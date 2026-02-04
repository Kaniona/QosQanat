const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');
const fs = require('fs');
const path = require('path');

// Get all topics
router.get('/topics', protect, (req, res) => {
    try {
        const topics = [
            { id: 'topic1', title: 'Натурал сандар', icon: '🔢' },
            { id: 'topic2', title: 'Бөлшектер', icon: '➗' },
            { id: 'topic3', title: 'Сызықтық теңдеулер', icon: '📐' }
        ];
        res.json({ success: true, topics });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Get topic details
router.get('/topics/:topicId', protect, (req, res) => {
    try {
        const { topicId } = req.params;
        const topicNumber = topicId.replace('topic', '');
        const files = fs.readdirSync(path.join(__dirname, '../../data/mathematics'));
        const file = files.find(f => f.startsWith(`topic${topicNumber}`));

        if (!file) {
            return res.status(404).json({ message: 'Тақырып табылмады' });
        }

        const data = JSON.parse(fs.readFileSync(path.join(__dirname, '../../data/mathematics', file), 'utf8'));
        res.json({ success: true, topic: data });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Submit answer
router.post('/submit', protect, async (req, res) => {
    try {
        const { topicId, problemId, answer } = req.body;

        // Load topic data
        const topicNumber = topicId.replace('topic', '');
        const files = fs.readdirSync(path.join(__dirname, '../../data/mathematics'));
        const file = files.find(f => f.startsWith(`topic${topicNumber}`));
        const topicData = JSON.parse(fs.readFileSync(path.join(__dirname, '../../data/mathematics', file), 'utf8'));

        // Find problem
        const problem = topicData.problems.find(p => p.id === problemId);
        if (!problem) {
            return res.status(404).json({ message: 'Есеп табылмады' });
        }

        // Check if already completed
        const alreadyCompleted = req.user.completedProblems.some(
            cp => cp.topicId === topicId && cp.problemId === problemId
        );

        // Check answer
        const isCorrect = answer.trim().toLowerCase() === problem.answer.toLowerCase();

        let pointsEarned = 0;
        let levededUp = false;
        let oldLevel = req.user.stats.level;

        if (isCorrect && !alreadyCompleted) {
            // Award points
            pointsEarned = problem.points;
            req.user.stats.intellectPoints += pointsEarned;

            // Add to completed problems
            req.user.completedProblems.push({
                topicId,
                problemId,
                pointsEarned
            });

            // Check for level up
            const newLevel = req.user.calculateLevel();
            if (newLevel > oldLevel) {
                leveledUp = true;
                // Award coins for level up
                const coinReward = 10 + newLevel * 20;
                req.user.stats.coins += coinReward;
            }

            await req.user.save();
        }

        res.json({
            success: true,
            correct: isCorrect,
            alreadyCompleted,
            pointsEarned,
            leveledUp,
            newLevel: req.user.stats.level,
            stats: req.user.stats,
            solution: isCorrect || alreadyCompleted ? problem.solution : null
        });
    } catch (error) {
        console.error('Submit error:', error);
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

module.exports = router;
