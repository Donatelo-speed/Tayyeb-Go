const { functions, db, OPENAI_API_KEY, rateLimit } = require('./config');

const processAiMenuImage = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }
  const rl = await rateLimit(request.auth.uid, 'processAiMenuImage', { maxRequests: 5, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { base64Image, prompt } = request.data;
  if (!base64Image) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'base64Image is required'
    );
  }

  const maxBase64Length = 13333334;
  if (base64Image.length > maxBase64Length) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Image too large. Maximum size is 10MB.'
    );
  }

  if (!OPENAI_API_KEY) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OpenAI API key not configured on server'
    );
  }

  const safePrompt = 'Extract all menu items from this image. Return JSON array with: name, price (as number), category, description (optional). Arabic text supported.';

  try {
    const https = require('https');

    const response = await new Promise((resolve, reject) => {
      const body = JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: safePrompt },
              { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
            ],
          },
        ],
        response_format: { type: 'json_object' },
      });

      const req = https.request(
        'https://api.openai.com/v1/chat/completions',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${OPENAI_API_KEY}`,
          },
        },
        (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => {
            try {
              resolve({ status: res.statusCode, body: JSON.parse(data) });
            } catch {
              reject(new Error('Invalid JSON from OpenAI'));
            }
          });
        }
      );

      req.on('error', reject);
      req.write(body);
      req.end();
    });

    if (response.status !== 200) {
      console.error('OpenAI error:', response.body);
      throw new functions.https.HttpsError(
        'internal',
        `AI processing failed (${response.status})`
      );
    }

    return { result: response.body };
  } catch (err) {
    console.error('AI proxy error:', err.message);
    throw new functions.https.HttpsError(
      'internal',
      'AI processing failed. Please try again.'
    );
  }
});

module.exports = { processAiMenuImage };
