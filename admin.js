const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { protect, adminOnly } = require('../middleware/auth');
const News = require('../models/News');
const User = require('../models/User');

// Configure multer for image uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/assets/news/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'news-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        const filetypes = /jpeg|jpg|png|gif|webp/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(path.extname(file.originalname).toLowerCase());

        if (mimetype && extname) {
            return cb(null, true);
        }
        cb(new Error('Тек сурет файлдарын жүктеуге болады'));
    }
});

// Create news (admin only)
router.post('/news', protect, adminOnly, upload.single('image'), async (req, res) => {
    try {
        const { title, shortDescription, fullDescription } = req.body;

        if (!req.file) {
            return res.status(400).json({ message: 'Сурет міндетті' });
        }

        const newsPost = await News.create({
            title,
            shortDescription,
            fullDescription,
            image: `/assets/news/${req.file.filename}`,
            createdBy: req.user._id
        });

        res.status(201).json({
            success: true,
            message: 'Жаңалық жарияланды',
            news: newsPost
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Delete news (admin only)
router.delete('/news/:id', protect, adminOnly, async (req, res) => {
    try {
        const news = await News.findByIdAndDelete(req.params.id);

        if (!news) {
            return res.status(404).json({ message: 'Жаңалық табылмады' });
        }

        res.json({
            success: true,
            message: 'Жаңалық жойылды'
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Get dashboard stats (admin only)
router.get('/stats', protect, adminOnly, async (req, res) => {
    try {
        const totalUsers = await User.countDocuments({ role: 'student' });
        const totalNews = await News.countDocuments();
        const totalAdmins = await User.countDocuments({ role: 'admin' });

        // Get top students
        const topStudents = await User.find({ role: 'student' })
            .select('fullName city stats')
            .sort({ 'stats.intellectPoints': -1 })
            .limit(10);

        // Get recent activity
        const recentNews = await News.find()
            .populate('createdBy', 'fullName')
            .sort({ createdAt: -1 })
            .limit(5);

        res.json({
            success: true,
            stats: {
                totalUsers,
                totalNews,
                totalAdmins,
                topStudents,
                recentNews
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Add new admin (admin only)
router.post('/admins', protect, adminOnly, async (req, res) => {
    try {
        const { fullName, phone, password } = req.body;

        // Check if user already exists
        const existing = await User.findOne({ phone });
        if (existing) {
            return res.status(400).json({ message: 'Бұл телефон тіркелген' });
        }

        const admin = await User.create({
            fullName,
            phone,
            email: `admin${phone}@qosqanat.kz`,
            password,
            city: 'Admin',
            school: 'Admin',
            grade: 0,
            role: 'admin'
        });

        res.status(201).json({
            success: true,
            message: 'Admin қосылды',
            admin: {
                id: admin._id,
                fullName: admin.fullName,
                phone: admin.phone
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Remove admin (admin only)
router.delete('/admins/:id', protect, adminOnly, async (req, res) => {
    try {
        // Don't allow removing yourself
        if (req.params.id === req.user._id.toString()) {
            return res.status(400).json({ message: 'Өзіңізді жоя алмайсыз' });
        }

        const admin = await User.findByIdAndDelete(req.params.id);

        if (!admin || admin.role !== 'admin') {
            return res.status(404).json({ message: 'Admin табылмады' });
        }

        res.json({
            success: true,
            message: 'Admin жойылды'
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Get all admins (admin only)
router.get('/admins', protect, adminOnly, async (req, res) => {
    try {
        const admins = await User.find({ role: 'admin' })
            .select('fullName phone createdAt');

        res.json({
            success: true,
            admins
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

module.exports = router;
