const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

async function test() {
  try {
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-3.5-flash',
      systemInstruction: "You are a bot"
    });
    
    const result = await model.generateContent("Hello");
    console.log("Success with gemini-3.5-flash:", result.response.text());
  } catch(e) {
    console.error("ERROR:", e);
  }
}
test();
