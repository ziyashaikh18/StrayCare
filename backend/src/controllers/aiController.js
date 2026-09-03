const fs = require('fs');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const HF_API_BASE =
  "https://router.huggingface.co/hf-inference/models/meta-llama/Llama-4-Scout-17B-16E-Instruct";

const HF_TIMEOUT = 30000;
const HF_TOKEN = process.env.HF_TOKEN;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

/**
 * Validates that the AI response contains all required fields
 * and has valid structure.
 */
const isValidAiResponse = (data) => {
  if (!data || typeof data !== 'object') return false;

  const requiredFields = [
    'animalType',
    'injuryType',
    'severity',
    'confidence',
    'description',
    'suggestion',
  ];

  for (const field of requiredFields) {
    if (data[field] === undefined || data[field] === null) {
      return false;
    }
  }

  const validSeverities = ['Low', 'Medium', 'High', 'Critical'];

  if (!validSeverities.includes(data.severity)) {
    return false;
  }

  if (
    typeof data.confidence !== 'number' ||
    data.confidence < 0 ||
    data.confidence > 100
  ) {
    return false;
  }

  if (!Array.isArray(data.detectedObjects)) {
    return false;
  }

  return true;
};

/**
 * Parses AI response and ensures proper JSON structure.
 * Attempts to extract JSON from markdown code blocks if needed.
 */
const parseAiResponse = (responseText) => {
  if (typeof responseText !== 'string') {
    throw new Error('AI response is not a string');
  }

  let text = responseText.trim();

  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);

  if (jsonMatch) {
    text = jsonMatch[1].trim();
  }

  try {
    return JSON.parse(text);
  } catch (err) {
    throw new Error(`Invalid JSON response: ${err.message}`);
  }
};

/**
 * Calls OpenRouter API with the image.
 */
const callOpenRouter = async (imageBase64, mimeType = 'image/jpeg') => {
  console.log("OpenRouter key loaded:", !!process.env.OPENROUTER_API_KEY);

  const prompt = `You are an expert veterinary AI assistant. Analyze the uploaded image of a stray animal and provide a detailed assessment.

Return ONLY valid JSON with NO markdown formatting, NO code blocks, and NO additional text. The JSON must be valid and parseable.

JSON Structure:
{
  "animalType": "type of animal (e.g., Dog, Cat, Rabbit, etc.)",
  "injuryType": "description of the injury or condition observed",
  "severity": "Low | Medium | High | Critical",
  "confidence": 85,
  "description": "detailed description of the animal's condition",
  "suggestion": "recommended next steps for rescue or treatment",
  "detectedObjects": ["list", "of", "detected", "objects"]
}

Ensure:
- confidence is an integer between 0 and 100
- severity is exactly one of: Low, Medium, High, Critical
- animalType is a single animal type
- All fields are present and non-empty
- Response is pure JSON only`;

  try {
    const response = await axios.post(
      "https://openrouter.ai/api/v1/chat/completions",
      {
        model: "google/gemma-3-27b-it:free",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${imageBase64}`,
                },
              },
            ],
          },
        ],
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.data || !response.data.choices || !response.data.choices[0]) {
      throw new Error(`OpenRouter API returned invalid response`);
    }

    const generatedText = response.data.choices[0].message.content;

    if (!generatedText) {
      throw new Error('No generated text in OpenRouter response');
    }

    const parsed = parseAiResponse(generatedText);

    if (!isValidAiResponse(parsed)) {
      throw new Error(
        'OpenRouter response missing required fields or invalid structure'
      );
    }

    return parsed;
  } catch (error) {
    console.error('OpenRouter Error:');

    if (error.response) {
      console.error('Status:', error.response.status);
      console.error(
        'Body:',
        JSON.stringify(error.response.data, null, 2)
      );
    } else {
      console.error(error.message);
    }

    throw error;
  }
};

/**
 * Calls Hugging Face Inference API with the image.
 */
const callHuggingFace = async (imageBase64, mimeType) => {
  const systemPrompt = `You are an expert veterinary AI assistant. Analyze the uploaded image of a stray animal and provide a detailed assessment.

Return ONLY valid JSON with NO markdown formatting, NO code blocks, and NO additional text. The JSON must be valid and parseable.

JSON Structure:
{
  "animalType": "type of animal (e.g., Dog, Cat, Rabbit, etc.)",
  "injuryType": "description of the injury or condition observed",
  "severity": "Low | Medium | High | Critical",
  "confidence": 85,
  "description": "detailed description of the animal's condition",
  "suggestion": "recommended next steps for rescue or treatment",
  "detectedObjects": ["list", "of", "detected", "objects"]
}

Ensure:
- confidence is an integer between 0 and 100
- severity is exactly one of: Low, Medium, High, Critical
- animalType is a single animal type
- All fields are present and non-empty
- Response is pure JSON only`;

  try {
    const response = await axios.post(
      HF_API_BASE,
      {
        model: 'Qwen/Qwen2.5-VL-7B-Instruct',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`,
                },
              },
              {
                type: 'text',
                text: systemPrompt,
              },
            ],
          },
        ],
        max_tokens: 500,
      },
      {
        headers: {
          Authorization: `Bearer ${HF_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: HF_TIMEOUT,
      }
    );

    if (!response.data || response.status !== 200) {
      throw new Error(`HF API returned status ${response.status}`);
    }

    const generatedText = response.data.choices[0].message.content;

    if (!generatedText) {
      throw new Error('No generated text in HF response');
    }

    const parsed = parseAiResponse(generatedText);

    if (!isValidAiResponse(parsed)) {
      throw new Error(
        'HF response missing required fields or invalid structure'
      );
    }

    return parsed;
  } catch (error) {
    console.error('HuggingFace Error:');

    if (error.response) {
      console.error('Status:', error.response.status);
      console.error(
        'Body:',
        JSON.stringify(error.response.data, null, 2)
      );
    } else {
      console.error(error.message);
    }

    throw error;
  }
};

/**
 * Calls Google Gemini API as a fallback with the image.
 */
const callGemini = async (imageBase64, mimeType) => {
  const systemPrompt = `You are an expert veterinary AI assistant. Analyze the uploaded image of a stray animal and provide a detailed assessment.

Return ONLY valid JSON with NO markdown formatting, NO code blocks, and NO additional text. The JSON must be valid and parseable.

JSON Structure:
{
  "animalType": "type of animal (e.g., Dog, Cat, Rabbit, etc.)",
  "injuryType": "description of the injury or condition observed",
  "severity": "Low | Medium | High | Critical",
  "confidence": 85,
  "description": "detailed description of the animal's condition",
  "suggestion": "recommended next steps for rescue or treatment",
  "detectedObjects": ["list", "of", "detected", "objects"]
}

Ensure:
- confidence is an integer between 0 and 100
- severity is exactly one of: Low, Medium, High, Critical
- animalType is a single animal type
- All fields are present and non-empty
- Response is pure JSON only`;

  try {
    const client = new GoogleGenerativeAI(GEMINI_API_KEY);

    const model = client.getGenerativeModel({
      model: 'gemini-3.6-flash',
    });

    const response = await model.generateContent([
      {
        inlineData: {
          mimeType,
          data: imageBase64,
        },
      },
      systemPrompt,
    ]);

    const generatedText = response.response.text();

    if (!generatedText) {
      throw new Error('No generated text in Gemini response');
    }

    const parsed = parseAiResponse(generatedText);

    if (!isValidAiResponse(parsed)) {
      throw new Error(
        'Gemini response missing required fields or invalid structure'
      );
    }

    return parsed;
  } catch (error) {
    const errorMessage = `Gemini Error: ${error.message}`;
    console.error(errorMessage);
    throw error;
  }
};

/**
 * POST /api/ai/analyze
 * Accepts a multipart image upload and returns AI analysis.
 * Tries Hugging Face first and falls back to Gemini on any error.
 */
const analyzeImage = async (req, res, next) => {
  try {
    if (!req.file) {
      const err = new Error('An image is required for analysis');
      err.statusCode = 400;
      throw err;
    }

    const imageBuffer = fs.readFileSync(req.file.path);
    const imageBase64 = imageBuffer.toString('base64');
    const mimeType = req.file.mimetype || 'image/jpeg';

    let analysisResult;
    let provider = 'openrouter';

    try {
      console.log('AI Provider: Attempting OpenRouter...');

      analysisResult = await callOpenRouter(
        imageBase64,
        mimeType
      );

      console.log('AI Provider: OpenRouter (success)');
    } catch (openRouterError) {
      console.warn(
        'AI Provider: OpenRouter failed, falling back to HuggingFace / Gemini'
      );

      console.error(
        'OpenRouter Error Details:',
        openRouterError.message
      );

      try {
        console.log('AI Provider: Attempting HuggingFace (fallback)...');

        analysisResult = await callHuggingFace(
          imageBase64,
          mimeType
        );

        provider = 'huggingface';

        console.log('AI Provider: HuggingFace (fallback - success)');
      } catch (hfError) {
        console.warn(
          'AI Provider: HuggingFace failed, falling back to Gemini'
        );

        console.error(
          'HuggingFace Error Details:',
          hfError.message
        );

        try {
          console.log('AI Provider: Attempting Gemini (fallback)...');

          analysisResult = await callGemini(
            imageBase64,
            mimeType
          );

          provider = 'gemini';

          console.log(
            'AI Provider: Gemini (fallback - success)'
          );
        } catch (geminiError) {
          console.error(
            'AI Provider: All AI providers (OpenRouter, HuggingFace, Gemini) failed'
          );

          console.error(
            'Gemini Error Details:',
            geminiError.message
          );

          const err = new Error(
            'AI analysis is temporarily unavailable.'
          );

          err.statusCode = 503;
          throw err;
        }
      }
    }

    fs.unlink(req.file.path, (err) => {
      if (err) {
        console.error(
          'Failed to delete temp file:',
          err.message
        );
      }
    });

    return res.status(200).json({
      success: true,
      provider,
      data: analysisResult,
    });
  } catch (error) {
    if (req.file) {
      fs.unlink(req.file.path, (err) => {
        if (err) {
          console.error(
            'Failed to delete temp file:',
            err.message
          );
        }
      });
    }

    return next(error);
  }
};

module.exports = {
  analyzeImage,
};