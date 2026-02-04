const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');

// Get user profile
router.get('/profile', protect, async (req, res) => {
    try {
        const user = await User.findById(req.user._id);
        res.json({
            success: true,
            user: {
                fullName: user.fullName,
                email: user.email,
                phone: user.phone,
                city: user.city,
                school: user.school,
                grade: user.grade,
                avatar: user.avatar,
                avatarItems: user.avatarItems,
                stats: user.stats,
                completedProblems: user.completedProblems
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Set avatar
router.post('/avatar', protect, async (req, res) => {
    try {
        const { avatar } = req.body;

        if (!['bektur', 'nazym'].includes(avatar)) {
            return res.status(400).json({ message: 'Аватар дұрыс таңдалмаған' });
        }

        req.user.avatar = avatar;
        await req.user.save();

        res.json({
            success: true,
            message: 'Аватар сәтті таңдалды',
            avatar: req.user.avatar
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Update profile
router.put('/profile', protect, async (req, res) => {
    try {
        const { fullName, email, city, school, grade } = req.body;

        const user = await User.findById(req.user._id);

        if (fullName) user.fullName = fullName;
        if (email) user.email = email;
        if (city) user.city = city;
        if (school) user.school = school;
        if (grade) user.grade = grade;

        await user.save();

        res.json({
            success: true,
            message: 'Профиль жаңартылды',
            user
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

module.exports = router;
