"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");

admin.initializeApp();

const app = require("express")();
app.use(require("express").json({limit: "10mb"}));
app.use(cors({origin: true}));

/**
 * POST /vision/analyze
 * body: { imageUrl?: string, imageBase64?: string }
 */
app.post("/vision/analyze", async (req, res) => {
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
 */
app.post("/replicate/generate", async (req, res) => {
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

exports.api = functions.https.onRequest(app);
