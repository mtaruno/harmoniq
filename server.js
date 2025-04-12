const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API endpoints
app.post('/api/favorites', (req, res) => {
    // Handle saving favorites to a file or database
    res.json({ success: true });
});

app.get('/api/favorites', (req, res) => {
    // Handle retrieving favorites from a file or database
    res.json([]);
});

// Start server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
}); 