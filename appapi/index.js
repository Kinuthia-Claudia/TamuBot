const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Improved CORS for Flutter development
app.use(cors({
  origin: ['http://localhost', 'http://10.0.2.2:3000', 'http://127.0.0.1:3000', 'http://192.168.100.4:3000'],
  credentials: true
}));

app.use(express.json());

// Your existing routes...
app.post('/api/voice-command', (req, res) => {
  console.log('Received voice command:', req.body);
  
  res.json({
    success: true,
    message: 'API is working!',
    received_command: req.body.transcript,
    intent: 'search_recipe',
    data: {
      recipe_title: 'Test Pancakes',
      ingredients: ['flour', 'eggs', 'milk'],
      instructions: ['Mix ingredients', 'Cook on pan']
    }
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cooking Assistant API is running!' });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});