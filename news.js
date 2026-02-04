const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const News = require('../models/News');

// Get all news
router.get('/', async (req, res) => {
    try {
        const news = await News.find({ published: true })
            .populate('createdBy', 'fullName')
            .sort({ createdAt: -1 })
            .limit(20);

        res.json({
            success: true,
            news
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Get single news
router.get('/:id', async (req, res) => {
    try {
        const news = await News.findById(req.params.id)
            .populate('createdBy', 'fullName');

        if (!news) {
            return res.status(404).json({ message: 'Жаңалық табылмады' });
        }

        res.json({
            success: true,
            news
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

module.exports = router;
