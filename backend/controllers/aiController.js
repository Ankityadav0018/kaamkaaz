const { GoogleGenerativeAI } = require('@google/generative-ai');

// Maps easy_localization locale codes to full language names for prompt injection
const localeMap = {
  en: 'English',
  hi: 'Hindi',
  bn: 'Bengali',
  ta: 'Tamil',
  te: 'Telugu',
  kn: 'Kannada',
  ml: 'Malayalam',
  or: 'Odia',
  pa: 'Punjabi',
  mr: 'Marathi',
  gu: 'Gujarati',
  raj: 'Rajasthani / Bhojpuri dialect',
  bgc: 'Haryanvi / Bagri dialect',
};

exports.assist = async (req, res) => {
  try {
    const { message, locale, currentRoute, role, name, history } = req.body;
    
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ success: false, message: 'AI Assistant is not configured on the server.' });
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const targetLanguage = localeMap[locale] || 'Hindi';

    const systemPrompt = `You are "Kaamkaaz Sahayak", a highly helpful AI assistant built into the Kaamkaaz app.
    
**CRITICAL LANGUAGE INSTRUCTION**:
You MUST write your entire response in the ${targetLanguage} language. NEVER reply in English unless ${targetLanguage} is English. Even if the user asks a question in English, you MUST translate your answer and reply in ${targetLanguage}. If the language is a regional dialect like Rajasthani or Bhojpuri, use simple common words of that dialect. Do NOT use Markdown, keep it plain text.

**GREETING INSTRUCTION**:
When you first reply, you MUST always greet the user by name using a culturally appropriate greeting for ${targetLanguage} (e.g., "Namaste ${name || 'Ji'}", "Raam Raam ${name || 'Ji'}", "Khama Ghani Sa ${name || 'Ji'}", etc.). Be highly respectful.

**USER CONTEXT**:
- Name: ${name || 'Dost'}
- Role: ${role || 'guest'}
- Current App Screen: ${currentRoute || 'Unknown'}

**APP KNOWLEDGE BASE**:
Kaamkaaz is a hyperlocal daily wage job marketplace for blue-collar workers (Kaamgars) and recruiters in rural and semi-urban India. It connects workers with nearby jobs within 15–30km radius using GPS.
- Worker features: job feed with GPS-based listings, one-tap apply, application status tracking (Pending / Accepted / Hired / Completed), KYC verification (Aadhaar + live selfie + driving license), verified skill badges, media portfolio (photos/videos of past work), emergency SOS alerts, offline mode with cached listings, in-app chat with recruiter.
- Recruiter features: post a job with GPS location + skill requirements + wage + site photos, browse applicants with ratings and verified badges, accept applicants to reveal contact (call / WhatsApp / in-app chat), view past hired workers and re-invite them.
- General features: 13 Indian language support, biometric login, OTP verification, Firebase push notifications, deep linking.

**YOUR GOAL**:
The user is stuck or has a question. Look at the Current App Screen and their Role to understand what they are trying to do. Provide a short (1-3 sentences), highly actionable answer on what button to press, what to fill out next, or how a feature works based on the knowledge base. Be friendly and respectful (e.g., use "Bhaiya", "Didi", "Ji").`;

    const model = genAI.getGenerativeModel({ 
      model: 'gemini-2.5-flash',
      systemInstruction: systemPrompt
    });
    // Map history to Gemini format if provided
    const formattedHistory = [];
    
    if (Array.isArray(history)) {
      history.forEach(msg => {
        formattedHistory.push({
          role: msg.role === 'model' ? 'model' : 'user',
          parts: [{ text: msg.text }]
        });
      });
    }

    const chatSession = model.startChat({
      history: formattedHistory,
    });

    let responseText = '';
    let retries = 3;
    let delay = 1000;

    while (retries > 0) {
      try {
        const result = await chatSession.sendMessage(message);
        responseText = result.response.text().replace(/\*/g, ''); // strip markdown bold/italics
        break;
      } catch (error) {
        retries -= 1;
        // Check if error is a 503 Service Unavailable
        const isServiceUnavailable = error.message && error.message.includes('503');
        if (retries === 0 || (!isServiceUnavailable && error.status !== 503)) {
          if (isServiceUnavailable || error.status === 503) {
            return res.status(503).json({ success: false, message: 'The AI assistant is currently experiencing high demand. Please try again in a few moments.' });
          }
          throw error;
        }
        console.warn(`Gemini API 503 Error. Retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay *= 2;
      }
    }

    res.status(200).json({
      success: true,
      text: responseText
    });
  } catch (error) {
    console.error('AI Controller Error:', error);
    res.status(500).json({ success: false, message: 'Failed to process AI request', errorDetails: error.message, stack: error.stack });
  }
};
