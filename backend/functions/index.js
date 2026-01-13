"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");
const {authenticate, optionalAuthenticate} = require("./middleware");

admin.initializeApp();

const app = require("express")();
app.use(require("express").json({limit: "10mb"}));
app.use(cors({origin: true}));

/**
 * POST /vision/analyze
 * body: { imageUrl?: string, imageBase64?: string }
 * Optional authentication - recommended for production
 */
app.post("/vision/analyze", optionalAuthenticate, async (req, res) => {
  try {
    // Try new environment variables first (Firebase Functions v2+)
    // Fall back to functions.config() for v1 compatibility
    const visionKey = process.env.VISION_API_KEY || 
                      functions.config().vision?.key;
    if (!visionKey) {
      return res.status(500).json({error: "VISION_API_KEY not configured"});
    }

    const {imageUrl, imageBase64} = req.body ?? {};
    if (!imageUrl && !imageBase64) {
      return res.status(400).json({error: "Provide imageUrl or imageBase64"});
    }

    const requestPayload = {
      requests: [
        {
          image: imageUrl ? {source: {imageUri: imageUrl}} : {content: imageBase64},
          features: [
            {type: "OBJECT_LOCALIZATION", maxResults: 50},
            {type: "LABEL_DETECTION", maxResults: 20},
          ],
        },
      ],
    };

    const response = await fetch(
        `https://vision.googleapis.com/v1/images:annotate?key=${visionKey}`,
        {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify(requestPayload),
        },
    );

    if (!response.ok) {
      const text = await response.text();
      return res.status(response.status).json({error: text});
    }

    const data = await response.json();
    return res.json({data});
  } catch (error) {
    functions.logger.error("Vision analyze failed", error);
    return res.status(500).json({error: error.message});
  }
});

/**
 * POST /replicate/generate
 * body: { imageUrl: string }
 * Optional authentication - recommended for production
 */
app.post("/replicate/generate", optionalAuthenticate, async (req, res) => {
  try {
    // Try new environment variables first (Firebase Functions v2+)
    // Fall back to functions.config() for v1 compatibility
    const replicateToken = process.env.REPLICATE_API_TOKEN || 
                            functions.config().replicate?.token;
    if (!replicateToken) {
      return res.status(500).json({error: "REPLICATE_API_TOKEN not configured"});
    }

    const {imageUrl} = req.body ?? {};
    if (!imageUrl) {
      return res.status(400).json({error: "imageUrl is required"});
    }

    const predictionResp = await fetch(
        "https://api.replicate.com/v1/predictions",
        {
          method: "POST",
          headers: {
            "Authorization": `Token ${replicateToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            version: "39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
            input: {
              image: imageUrl,
              prompt: "same space perfectly organized and tidy, clean surfaces, everything stored, high quality, photorealistic",
              prompt_strength: 0.7,
              num_inference_steps: 28,
            },
          }),
        },
    );

    if (!predictionResp.ok) {
      const text = await predictionResp.text();
      return res.status(predictionResp.status).json({error: text});
    }

    const prediction = await predictionResp.json();
    const predictionId = prediction.id;

    let outputUrl = null;
    const maxAttempts = 60;
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      await new Promise((resolve) => setTimeout(resolve, 1000));

      const statusResp = await fetch(
          `https://api.replicate.com/v1/predictions/${predictionId}`,
          {
            headers: {
              "Authorization": `Token ${replicateToken}`,
            },
          },
      );

      if (!statusResp.ok) {
        const text = await statusResp.text();
        return res.status(statusResp.status).json({error: text});
      }

      const statusJson = await statusResp.json();
      if (statusJson.status === "succeeded") {
        outputUrl = Array.isArray(statusJson.output) ?
          statusJson.output[0] :
          statusJson.output;
        break;
      } else if (["failed", "canceled"].includes(statusJson.status)) {
        return res.status(500).json({error: statusJson.error ?? statusJson.status});
      }
    }

    if (!outputUrl) {
      return res.status(504).json({error: "Replicate generation timed out"});
    }

    return res.json({data: {predictionId, outputUrl}});
  } catch (error) {
    functions.logger.error("Replicate generate failed", error);
    return res.status(500).json({error: error.message});
  }
});

/**
 * GET /stripe/oauth/return
 * Handles OAuth callback from Stripe Connect for customer-provided accounts
 * Query params: code, state
 * No authentication required (public callback endpoint)
 */
app.get("/stripe/oauth/return", async (req, res) => {
  try {
    const {code, state} = req.query;
    
    if (!code) {
      return res.status(400).json({error: "Authorization code missing"});
    }

    // Get Stripe secret key
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY || 
                           functions.config().stripe?.secret_key;
    if (!stripeSecretKey) {
      return res.status(500).json({error: "STRIPE_SECRET_KEY not configured"});
    }

    // Exchange authorization code for account ID
    const tokenResponse = await fetch("https://connect.stripe.com/oauth/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code: code,
      }).toString(),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      functions.logger.error("Stripe OAuth token exchange failed", errorText);
      return res.status(400).json({error: "Failed to exchange authorization code"});
    }

    const tokenData = await tokenResponse.json();
    const accountId = tokenData.stripe_user_id;
    const userId = state; // State parameter contains user ID for security

    if (!accountId || !userId) {
      return res.status(400).json({error: "Invalid OAuth response"});
    }

    // Get account details from Stripe
    const accountResponse = await fetch(
        `https://api.stripe.com/v1/accounts/${accountId}`,
        {
          headers: {
            "Authorization": `Bearer ${stripeSecretKey}`,
          },
        },
    );

    if (!accountResponse.ok) {
      return res.status(500).json({error: "Failed to fetch account details"});
    }

    const accountData = await accountResponse.json();

    // Save connected account to Firestore
    const db = admin.firestore();
    await db.collection("stripe_connected_accounts").doc(userId).set({
      accountId: accountId,
      userId: userId,
      email: accountData.email || "",
      type: accountData.type || "standard",
      status: accountData.charges_enabled && accountData.payouts_enabled ?
        "enabled" : "pending",
      businessName: accountData.business_profile?.name || null,
      country: accountData.country || null,
      chargesEnabled: accountData.charges_enabled || false,
      payoutsEnabled: accountData.payouts_enabled || false,
      detailsSubmitted: accountData.details_submitted || false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    // Redirect to app (deep link or web URL)
    // In production, this should be a deep link: clutterzen://stripe/connected
    // For web, redirect to a success page
    const redirectUrl = process.env.STRIPE_OAUTH_REDIRECT_URL || 
                       "https://clutterzen.app/stripe/connected";
    
    return res.redirect(redirectUrl);
  } catch (error) {
    functions.logger.error("Stripe OAuth callback failed", error);
    return res.status(500).json({error: error.message});
  }
});

/**
 * POST /stripe/connect/create-account-link
 * Creates an account link for onboarding a new connected account
 * body: { accountId: string, returnUrl: string, refreshUrl: string }
 * Requires authentication
 */
app.post("/stripe/connect/create-account-link", authenticate, async (req, res) => {
  try {
    const {accountId, returnUrl, refreshUrl} = req.body;
    
    if (!accountId || !returnUrl || !refreshUrl) {
      return res.status(400).json({
        error: "accountId, returnUrl, and refreshUrl are required",
      });
    }

    const stripeSecretKey = process.env.STRIPE_SECRET_KEY || 
                         functions.config().stripe?.secret_key;
    if (!stripeSecretKey) {
      return res.status(500).json({error: "STRIPE_SECRET_KEY not configured"});
    }

    const linkResponse = await fetch("https://api.stripe.com/v1/account_links", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        account: accountId,
        return_url: returnUrl,
        refresh_url: refreshUrl,
        type: "account_onboarding",
      }).toString(),
    });

    if (!linkResponse.ok) {
      const errorText = await linkResponse.text();
      return res.status(linkResponse.status).json({error: errorText});
    }

    const linkData = await linkResponse.json();
    return res.json({data: {url: linkData.url}});
  } catch (error) {
    functions.logger.error("Create account link failed", error);
    return res.status(500).json({error: error.message});
  }
});

/**
 * POST /stripe/connect/create-payment-intent
 * Creates a payment intent for a professional service booking
 * body: { accountId: string, amount: number, currency: string, applicationFeeAmount?: number }
 * Requires authentication
 */
app.post("/stripe/connect/create-payment-intent", authenticate, async (req, res) => {
  try {
    const {accountId, amount, currency = "usd", applicationFeeAmount} = req.body;
    const userId = req.user.uid;
    
    if (!accountId || !amount) {
      return res.status(400).json({
        error: "accountId and amount are required",
      });
    }

    const stripeSecretKey = process.env.STRIPE_SECRET_KEY || 
                         functions.config().stripe?.secret_key;
    if (!stripeSecretKey) {
      return res.status(500).json({error: "STRIPE_SECRET_KEY not configured"});
    }

    const amountInCents = Math.round(amount * 100);
    const feeInCents = applicationFeeAmount ? 
                       Math.round(applicationFeeAmount * 100) : null;

    const body = new URLSearchParams({
      amount: amountInCents.toString(),
      currency: currency,
      "payment_method_types[]": "card",
      "automatic_payment_methods[enabled]": "true",
      ...(feeInCents && {"application_fee_amount": feeInCents.toString()}),
    });

    const intentResponse = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${stripeSecretKey}`,
        "Stripe-Account": accountId,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: body.toString(),
    });

    if (!intentResponse.ok) {
      const errorText = await intentResponse.text();
      return res.status(intentResponse.status).json({error: errorText});
    }

    const intentData = await intentResponse.json();

    // Save booking to Firestore
    const db = admin.firestore();
    await db.collection("service_bookings").add({
      userId: userId,
      professionalAccountId: accountId,
      amount: amount,
      currency: currency,
      applicationFee: applicationFeeAmount || 0,
      paymentIntentId: intentData.id,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({
      data: {
        clientSecret: intentData.client_secret,
        paymentIntentId: intentData.id,
      },
    });
  } catch (error) {
    functions.logger.error("Create payment intent failed", error);
    return res.status(500).json({error: error.message});
  }
});

exports.api = functions.https.onRequest(app);
