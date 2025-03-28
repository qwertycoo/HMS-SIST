require('dotenv').config();
const { Client, GatewayIntentBits } = require('discord.js');
const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');

const app = express();
app.use(express.json());
app.use(cors());

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent
    ],
});

// Connect to Discord
client.once('ready', () => {
    console.log(`🤖 Logged in as ${client.user.tag}`);
});

// WebSocket setup for real-time messages
const wss = new WebSocket.Server({ port: 8080 });
wss.on('connection', (ws) => {
    console.log('🔗 WebSocket Client Connected');

    client.on('messageCreate', (message) => {
        if (message.channel.id === process.env.CHANNEL_ID) {
            ws.send(JSON.stringify({ username: message.author.username, content: message.content }));
        }
    });
});

// REST API to send messages from Flutter
app.post('/send-message', async (req, res) => {
    const { message } = req.body;
    const channel = await client.channels.fetch(process.env.CHANNEL_ID);

    if (channel) {
        await channel.send(message);
        res.json({ success: true });
    } else {
        res.json({ success: false });
    }
});

// Start the server
client.login(process.env.DISCORD_TOKEN);
app.listen(3000, () => console.log("🚀 Server running on port 3000"));
