const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');

// Get city leaderboard
router.get('/city', protect, async (req, res) => {
    try {
        const { city } = req.query;
        const targetCity = city || req.user.city;

        const users = await User.find({ city: targetCity, role: 'student' })
            .select('fullName school stats')
            .sort({ 'stats.intellectPoints': -1 })
            .limit(100);

        const leaderboard = users.map((user, index) => ({
            rank: index + 1,
            fullName: user.fullName,
            school: user.school,
            points: user.stats.intellectPoints,
            level: user.stats.level,
            isCurrentUser: user._id.toString() === req.user._id.toString()
        }));

        res.json({
            success: true,
            city: targetCity,
            leaderboard
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Get national leaderboard
router.get('/national', protect, async (req, res) => {
    try {
        const users = await User.find({ role: 'student' })
            .select('fullName city school stats')
            .sort({ 'stats.intellectPoints': -1 })
            .limit(100);

        const leaderboard = users.map((user, index) => ({
            rank: index + 1,
            fullName: user.fullName,
            city: user.city,
            school: user.school,
            points: user.stats.intellectPoints,
            level: user.stats.level,
            isCurrentUser: user._id.toString() === req.user._id.toString()
        }));

        res.json({
            success: true,
            leaderboard
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

module.exports = router;
