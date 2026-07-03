require('dotenv').config({ path: '.env' });
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function run() {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    const genAI = new GoogleGenerativeAI(apiKey);
    const systemPrompt = `You are a test assistant.`;
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-flash-latest',
      systemInstruction: systemPrompt
    });
    
    const formattedHistory = [
      { role: 'user', parts: [{ text: "Hello" }] },
      { role: 'model', parts: [{ text: "Hi" }] }
    ];
    
    const chatSession = model.startChat({
      history: formattedHistory,
    });
    
    const result = await chatSession.sendMessage("Test");
    console.log("Success:", result.response.text());
  } catch (err) {
    console.error("Error:", err);
  }
}
run();
