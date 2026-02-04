const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');

// Shop items configuration
const SHOP_ITEMS = [
    { id: 'glasses', name: 'Көзілдірік', price: 50, icon: '🕶️' },
    { id: 'hat', name: 'Бас киім', price: 70, icon: '🎩' },
    { id: 'goldBackground', name: 'Алтын фон', price: 100, icon: '⭐' },
    { id: 'superCostume', name: 'Супер костюм', price: 150, icon: '🦸' }
];

// Get shop items
router.get('/items', protect, (req, res) => {
    try {
        const userItems = req.user.avatarItems;
        const items = SHOP_ITEMS.map(item => ({
            ...item,
            purchased: userItems[item.id] || false
        }));

        res.json({
            success: true,
            items,
            userCoins: req.user.stats.coins
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

// Purchase item
router.post('/purchase', protect, async (req, res) => {
    try {
        const { itemId } = req.body;

        const item = SHOP_ITEMS.find(i => i.id === itemId);
        if (!item) {
            return res.status(404).json({ message: 'Зат табылмады' });
        }

        // Check if already purchased
        if (req.user.avatarItems[itemId]) {
            return res.status(400).json({ message: 'Сіз бұл затты сатып алғансыз' });
        }

        // Check if enough coins
        if (req.user.stats.coins < item.price) {
            return res.status(400).json({ message: 'Coin жеткіліксіз' });
        }

        // Deduct coins and add item
        req.user.stats.coins -= item.price;
        req.user.avatarItems[itemId] = true;

        await req.user.save();

        res.json({
            success: true,
            message: `${item.name} сәтті сатып алынды!`,
            item: itemId,
            remainingCoins: req.user.stats.coins,
            avatarItems: req.user.avatarItems
        });
    } catch (error) {
        res.status(500).json({ message: 'Қате кетті', error: error.message });
    }
});

module.exports = router;
