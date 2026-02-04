const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Register
router.post('/register', async (req, res) => {
    try {
        const { fullName, phone, email, city, school, grade, password } = req.body;

        // Check if user already exists
        const existingUser = await User.findOne({ $or: [{ email }, { phone }] });
        if (existingUser) {
            return res.status(400).json({ message: 'Бұл телефон немесе email тіркелген' });
        }

        // Create new user
        const user = await User.create({
            fullName,
            phone,
            email,
            city,
            school,
            grade,
            password,
            stats: {
                intellectPoints: 0,
                coins: 20,
                level: 1,
                currentLevelProgress: 0
            }
        });

        // Generate JWT token
        const token = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET || 'qosqanat_secret_key',
            { expiresIn: process.env.JWT_EXPIRE || '7d' }
        );

        res.status(201).json({
            success: true,
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email,
                avatar: user.avatar,
                stats: user.stats
            }
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Тіркелу кезінде қате кетті', error: error.message });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { phone, password } = req.body;

        // Find user
        const user = await User.findOne({
            $or: [{ phone }, { email: phone }]
        }).select('+password');

        if (!user) {
            return res.status(401).json({ message: 'Телефон немесе құпия сөз қате' });
        }

        // Check password
        const isPasswordCorrect = await user.comparePassword(password);
        if (!isPasswordCorrect) {
            return res.status(401).json({ message: 'Телефон немесе құпия сөз қате' });
        }

        // Generate JWT token
        const token = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET || 'qosqanat_secret_key',
            { expiresIn: process.env.JWT_EXPIRE || '7d' }
        );

        res.json({
            success: true,
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email,
                avatar: user.avatar,
                stats: user.stats,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Кіру кезінде қате кетті', error: error.message });
    }
});

// Admin Login
router.post('/admin-login', async (req, res) => {
    try {
        const { phone, password } = req.body;

        // Find admin user
        const user = await User.findOne({ phone, role: 'admin' }).select('+password');

        if (!user) {
            return res.status(401).json({ message: 'Admin табылмады' });
        }

        // Check password
        const isPasswordCorrect = await user.comparePassword(password);
        if (!isPasswordCorrect) {
            return res.status(401).json({ message: 'Құпия сөз қате' });
        }

        // Generate JWT token
        const token = jwt.sign(
            { id: user._id, role: 'admin' },
            process.env.JWT_SECRET || 'qosqanat_secret_key',
            { expiresIn: process.env.JWT_EXPIRE || '7d' }
        );

        res.json({
            success: true,
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Admin login error:', error);
        res.status(500).json({ message: 'Кіру кезінде қате кетті', error: error.message });
    }
});

module.exports = router;
