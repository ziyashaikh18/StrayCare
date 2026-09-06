const fs = require('fs');
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const ANIMAL_DETECT_API = process.env.ANIMAL_DETECT_API;

const extensionMimeMap = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
  '.heif': 'image/heic',
};

const allowedSpecies = new Set([
  'Dog',
  'Cat',
  'Bird',
  'Cow',
  'Goat',
  'Monkey',
  'Rabbit',
  'Other',
  'Unknown',
]);

const normalizeSpecies = (label) => {
  const value = String(label || '').toLowerCase();
  if (value === 'dog') return 'Dog';
  if (value === 'cat') return 'Cat';
  if (['bird', 'bird other'].includes(value)) return 'Bird';
  if (value === 'cow') return 'Cow';
  if (['goat', 'sheep'].includes(value)) return 'Goat';
  if (['monkey', 'primate'].includes(value)) return 'Monkey';
  if (['rabbit', 'hare'].includes(value)) return 'Rabbit';
  if (['horse', 'elephant', 'bear', 'zebra', 'giraffe'].includes(value)) {
    return 'Other';
  }
  return 'Unknown';
};

const detectMimeType = async (buffer, filename) => {
  try {
    const { fileTypeFromBuffer } = await import('file-type');
    const detected = await fileTypeFromBuffer(buffer);
    if (detected?.mime === 'image/heif') return 'image/heic';
    if (detected?.mime) return detected.mime;
  } catch (error) {
    console.warn('[Chat] Binary MIME detection failed:', error.message);
  }

  return extensionMimeMap[path.extname(filename).toLowerCase()];
};

const callAnimalDetect = async (imageBase64, mimeType) => {
  if (!ANIMAL_DETECT_API) return null;

  try {
    console.log('Animal Detect request started.');

    const imageBuffer = Buffer.from(imageBase64, 'base64');
    const formData = new FormData();
    formData.append(
      'image',
      new Blob([imageBuffer], { type: mimeType }),
      'scan.jpg'
    );
    formData.append('threshold', '0.2');
    formData.append('classify', 'true');

    const response = await fetch('https://api.animaldetect.com/v1/detect', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${ANIMAL_DETECT_API}`,
      },
      body: formData,
    });

    console.log(`Animal Detect HTTP status: ${response.status}`);

    const responseText = await response.text();
    let data;
    try {
      data = JSON.parse(responseText);
    } catch {
      console.error('Animal Detect returned invalid JSON.');
      return null;
    }

    if (response.status === 401) {
      console.error('Animal Detect authentication failed.');
      console.error('Animal Detect error body:', responseText);
      return null;
    }

    if (response.status === 402) {
      console.error('Animal Detect free quota exhausted.');
      return null;
    }

    if (!response.ok) {
      console.error('Animal Detect error body:', responseText);
      return null;
    }

    const annotations = Array.isArray(data.annotations)
      ? data.annotations
      : Array.isArray(data.data?.annotations)
        ? data.data.annotations
        : [];
    const bestDetection = annotations.sort(
      (left, right) =>
        Number(right.confidence ?? right.score ?? 0) -
        Number(left.confidence ?? left.score ?? 0)
    )[0];

    if (!bestDetection) return null;

    const rawConfidence = Number(
      bestDetection.confidence ?? bestDetection.score ?? 0
    );
    const rawLabel =
      bestDetection.animalType ??
      bestDetection.label ??
      bestDetection.class ??
      bestDetection.name;
    const animalType = normalizeSpecies(rawLabel);

    if (animalType === 'Unknown') return null;

    const confidence = Math.round(
      rawConfidence <= 1 ? rawConfidence * 100 : rawConfidence
    );

    console.log(
      `Animal Detect species: ${animalType}, confidence: ${confidence}`
    );

    return {
      animalType,
      confidence,
    };
  } catch (error) {
    console.error('[Animal Detect] Detection failed:', error.message);
    return null;
  }
};

const parseGeminiResponse = (text) => {
  const match = text.trim().match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  const parsed = JSON.parse(match ? match[1].trim() : text.trim());
  const animalType = allowedSpecies.has(parsed.animalType)
    ? parsed.animalType
    : 'Unknown';

  return {
    animalType,
    condition: String(parsed.condition || 'No visible condition identified.'),
    severity: ['Low', 'Medium', 'High', 'Critical'].includes(parsed.severity)
      ? parsed.severity
      : 'Medium',
    priorityScore: Number.isFinite(Number(parsed.priorityScore))
      ? Math.max(0, Math.min(100, Math.round(Number(parsed.priorityScore))))
      : 50,
    description: String(parsed.description || 'No additional visible details were returned.'),
    firstAid: String(parsed.firstAid || 'Avoid handling the animal unnecessarily and seek veterinary assessment.'),
    reply: String(parsed.reply || 'I can help with the animal health and care questions related to this scan.'),
  };
};

const callGeminiChat = async ({ imageBase64, mimeType, animalDetect, message }) => {
  const prompt = `You are the StrayCare veterinary AI Assistant. Analyze the uploaded animal image and answer the user's relevant animal-health or StrayCare question.

The user may ask only about animal health, animal care, rescue guidance, StrayCare features, or NGO partnership. For unrelated questions such as math, coding, politics, movies, cricket, or random chat, reply exactly: "I'm the StrayCare AI Assistant. I can help with animal health, injury analysis, rescue guidance, NGO partnership, and StrayCare app-related questions only. Please ask a relevant StrayCare or animal-care question."

Use only visible evidence. Do not invent injuries. Identify the actual species. The Animal Detect result is only a species cross-check and must not be used for injury reasoning:
${JSON.stringify(animalDetect || { animalType: 'Unknown', confidence: 0 })}

User question: ${message || 'Analyze this image and explain the visible condition, severity, and first aid.'}

Return only valid JSON:
{
  "animalType": "Cat",
  "condition": "Visible condition only.",
  "severity": "Low | Medium | High | Critical",
  "priorityScore": 50,
  "description": "Visible evidence only.",
  "firstAid": "Species-appropriate first aid.",
  "reply": "Your conversational answer to the user."
}`;

  const client = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = client.getGenerativeModel({ model: 'gemini-3.6-flash' });
  const response = await model.generateContent([
    { inlineData: { mimeType, data: imageBase64 } },
    prompt,
  ]);
  const text = response.response.text();
  if (!text) throw new Error('No generated text in Gemini response');
  return parseGeminiResponse(text);
};

const chat = async (req, res, next) => {
  try {
    if (!req.file) {
      const error = new Error('An image is required for AI Scan');
      error.statusCode = 400;
      throw error;
    }

    const imageBuffer = fs.readFileSync(req.file.path);
    const imageBase64 = imageBuffer.toString('base64');
    const mimeType = await detectMimeType(imageBuffer, req.file.originalname);
    if (!mimeType || !mimeType.startsWith('image/')) {
      const error = new Error('Unsupported image format');
      error.statusCode = 400;
      throw error;
    }

    const animalDetect = await callAnimalDetect(imageBase64, mimeType);
    const geminiResult = await callGeminiChat({
      imageBase64,
      mimeType,
      animalDetect,
      message: req.body.message,
    });

    let animalType = geminiResult.animalType;
    let speciesVerifiedBy = 'gemini';
    let confidence = geminiResult.priorityScore;

    if (animalDetect && geminiResult.animalType === animalDetect.animalType) {
      animalType = animalDetect.animalType;
      speciesVerifiedBy = 'animal_detect';
      confidence = animalDetect.confidence;
    } else if (animalDetect && animalDetect.animalType !== geminiResult.animalType) {
      console.warn(
        `Species mismatch:\nAnimal Detect = ${animalDetect.animalType}\nGemini = ${geminiResult.animalType}\nUsing Gemini species.`
      );
    }

    fs.unlink(req.file.path, () => {});
    return res.json({
      success: true,
      animalType,
      speciesVerifiedBy,
      confidence,
      condition: geminiResult.condition,
      severity: geminiResult.severity,
      priorityScore: geminiResult.priorityScore,
      description: geminiResult.description,
      firstAid: geminiResult.firstAid,
      reply: geminiResult.reply,
    });
  } catch (error) {
    if (req.file) fs.unlink(req.file.path, () => {});
    next(error);
  }
};

module.exports = { callAnimalDetect, chat };
