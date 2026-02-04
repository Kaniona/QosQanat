const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const learningRoutes = require('./routes/learning');
const shopRoutes = require('./routes/shop');
const ratingRoutes = require('./routes/rating');
const newsRoutes = require('./routes/news');
const adminRoutes = require('./routes/admin');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static files
app.use(express.static(path.join(__dirname, '../public')));

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/qosqanat', {
    useNewUrlParser: true,
    useUnifiedTopology: true
})
    .then(() => console.log('✅ MongoDB қосылды'))
    .catch(err => console.error('❌ MongoDB қосылу қатесі:', err));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/learning', learningRoutes);
app.use('/api/shop', shopRoutes);
app.use('/api/rating', ratingRoutes);
app.use('/api/news', newsRoutes);
app.use('/api/admin', adminRoutes);

// Serve mathematics data
app.get('/api/learning/topics/:topicId', (req, res) => {
    const topicId = req.params.topicId;
    const topicFile = path.join(__dirname, `../data/mathematics/topic${topicId.replace('topic', '')}-*.json`);

    try {
        const fs = require('fs');
        const files = fs.readdirSync(path.join(__dirname, '../data/mathematics'));
        const file = files.find(f => f.startsWith(`topic${topicId.replace('topic', '')}`));

        if (file) {
            const data = require(`../data/mathematics/${file}`);
            res.json(data);
        } else {
            res.status(404).json({ message: 'Topic not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Error loading topic', error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        message: 'Серверде қате кетті',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ message: 'Route табылмады' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 QosQanat сервер іске қосылды: http://localhost:${PORT}`);
    console.log(`📱 Браузерде ашыңыз: http://localhost:${PORT}/pages/index.html`);
});

module.exports = app;
