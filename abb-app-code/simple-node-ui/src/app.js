const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_MESSAGE = process.env.APP_MESSAGE || 'Hello from Node.js App!';

// Serve static HTML from views folder
app.use(express.static(path.join(__dirname, 'views')));

// API endpoint
app.get('/api/message', (req, res) => {
  res.json({ message: APP_MESSAGE });
});

// Health endpoints
app.get('/health/live', (req, res) => res.sendStatus(200));
app.get('/health/ready', (req, res) => res.sendStatus(200));

// Start server
if (require.main === module) {
  app.listen(PORT, () => console.log(`✅ App running on port ${PORT}`));
}

module.exports = app; // For testing
