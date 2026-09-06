const fs = require('fs');
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const extensionMimeMap = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
  '.heif': 'image/heic',
};

const supportedImageMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
]);

const getImageMimeType = async (imageBuffer, filename) => {
  let detectedType;

  try {
    const { fileTypeFromBuffer } = await import('file-type');
    detectedType = await fileTypeFromBuffer(imageBuffer);
  } catch (error) {
    console.warn('[AI upload] Binary MIME detection failed:', error.message);
  }

  let mimeType = detectedType?.mime;

  if (mimeType === 'image/heif') {
    mimeType = 'image/heic';
  }

  if (!mimeType) {
    mimeType = extensionMimeMap[path.extname(filename).toLowerCase()];
  }

  if (!supportedImageMimeTypes.has(mimeType)) {
    const error = new Error('Unsupported image format');
    error.statusCode = 400;
    throw error;
  }

  return mimeType;
};

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
    const data = JSON.parse(text);
    const severity = ['Low', 'Medium', 'High', 'Critical'].includes(data.severity)
      ? data.severity
      : 'Medium';
    const animalType =
      typeof data.animalType === 'string' && data.animalType.trim()
        ? data.animalType.trim()
        : 'Unknown';
    const condition =
      typeof data.condition === 'string' && data.condition.trim()
        ? data.condition.trim()
        : typeof data.injuryType === 'string' && data.injuryType.trim()
          ? data.injuryType.trim()
          : 'No visible condition identified.';
    const firstAid =
      typeof data.firstAid === 'string' && data.firstAid.trim()
        ? data.firstAid.trim()
        : typeof data.suggestion === 'string' && data.suggestion.trim()
          ? data.suggestion.trim()
          : 'Avoid handling the animal unnecessarily and seek veterinary assessment.';
    const priorityScore = Number.isFinite(
      Number(data.priorityScore ?? data.confidence)
    )
      ? Math.max(0, Math.min(100, Math.round(Number(data.priorityScore ?? data.confidence))))
      : 50;
    const description =
      typeof data.description === 'string' && data.description.trim()
        ? data.description.trim()
        : 'No additional visible details were returned.';
    const detectedObjects = Array.isArray(data.detectedObjects)
      ? data.detectedObjects
      : [];

    return {
      ...data,
      animalType,
      condition,
      firstAid,
      priorityScore,
      severity,
      description,
      injuryType: condition,
      suggestion: firstAid,
      confidence: priorityScore,
      detectedObjects,
    };
  } catch (err) {
    throw new Error(`Invalid JSON response: ${err.message}`);
  }
};

/**
 * Calls Google Gemini API with the image.
 */
const callGemini = async (imageBase64, mimeType) => {
  const systemPrompt = `You are an expert veterinary AI assistant. Analyze only the visible evidence in the uploaded image and provide a species-neutral assessment of the animal's visible condition.

First identify the species from the image. Never assume the animal is a dog. Do not prioritize dogs. Detect the actual species present in the image. If the uploaded image is a bird, never label it as a dog. If it is a cat, never label it as a dog.

animalType must be exactly one of: Dog, Cat, Bird, Cow, Goat, Monkey, Rabbit, Other, Unknown. Use Unknown if the species cannot be determined confidently. If the image shows a cat, bird, cow, goat, monkey, rabbit, or another animal, return that detected species rather than defaulting to Dog.

Analyze only conditions that are visibly present. Do not invent injuries, symptoms, or details that are not visible. Estimate severity only from visible evidence and use exactly one of: Low, Medium, High, Critical. Generate first-aid advice appropriate for the detected species. If the species is Unknown, give cautious, species-neutral advice and recommend professional veterinary assessment.

Return ONLY valid JSON with NO markdown formatting, NO code blocks, NO explanations, and NO additional text. The JSON must be valid and parseable.

JSON Structure:
{
  "animalType": "Cat",
  "injuryType": "Superficial skin abrasion on hind leg.",
  "severity": "Medium",
  "confidence": 88,
  "description": "Visible patchy fur loss and a superficial abrasion on the hind limb with mild inflammation.",
  "suggestion": "Approach the cat calmly, avoid touching the wound directly, provide clean water if possible, and transport to a veterinary clinic or NGO.",
  "detectedObjects": ["cat", "hind leg abrasion"]
}

Ensure:
- confidence is an integer between 0 and 100 representing confidence in the visible assessment
- severity is exactly one of: Low, Medium, High, Critical
- animalType is exactly one allowed species value
- injuryType describes the visible condition only
- description describes visible evidence only
- suggestion is species-appropriate first-aid advice
- All fields are present and non-empty
- Response is pure JSON only`;

  try {
    const client = new GoogleGenerativeAI(GEMINI_API_KEY);

    const model = client.getGenerativeModel({
      model: 'gemini-3.6-flash',
    });

    console.log('[Gemini] Sending image with MIME type:', mimeType);

    const response = await model.generateContent([
      {
        inlineData: {
          mimeType,
          data: imageBase64,
        },
      },
      systemPrompt,
    ]);

    console.debug('[Gemini] response metadata:', {
      promptFeedback: response.response.promptFeedback,
      candidates: response.response.candidates?.map((candidate) => ({
        finishReason: candidate.finishReason,
        safetyRatings: candidate.safetyRatings,
      })),
    });

    const generatedText = response.response.text();

    console.debug('[Gemini] raw response text:', generatedText);

    if (!generatedText) {
      throw new Error('No generated text in Gemini response');
    }

    const parsed = parseAiResponse(generatedText);

    if (!isValidAiResponse(parsed)) {
      throw new Error(
        'Gemini response missing required fields or invalid structure'
      );
    }

    console.log('[AI] Final JSON sent to Flutter:', parsed);

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
 * Uses Google Gemini to analyze the uploaded image.
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
    const mimeType = await getImageMimeType(
      imageBuffer,
      req.file.originalname
    );

    console.debug('[AI upload] image received:', {
      fieldname: req.file.fieldname,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      mimeTypeSentToGemini: mimeType,
      multerSize: req.file.size,
      bytesReadFromDisk: imageBuffer.length,
      base64Length: imageBase64.length,
    });

    let analysisResult;

    try {
      analysisResult = await callGemini(
        imageBase64,
        mimeType
      );
    } catch {
      const err = new Error(
        'AI analysis is temporarily unavailable.'
      );

      err.statusCode = 503;
      throw err;
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