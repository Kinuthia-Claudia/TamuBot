const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Test route - this is what your Flutter app will call
app.post('/api/voice-command', (req, res) => {
  console.log('Received voice command:', req.body);
  
  // For now, just return a dummy response
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

// Health check route
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cooking Assistant API is running!' });
});

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Cooking Assistant API Server' });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});