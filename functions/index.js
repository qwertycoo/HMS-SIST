const functions = require("firebase-functions");
const axios = require("axios");

const GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"; // Replace with your API Key

exports.geminiAI = functions.https.onRequest(async (req, res) => {
    try {
        const userInput = req.body.prompt;
        const response = await axios.post(
            `https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`,
            {
                contents: [{ parts: [{ text: userInput }] }]
            }
        );
        res.json(response.data);
    } catch (error) {
        res.status(500).send(error.toString());
    }
});
