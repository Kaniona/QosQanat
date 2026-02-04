const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    fullName: {
        type: String,
        required: [true, 'Аты-жөні міндетті'],
        trim: true
    },
    phone: {
        type: String,
        required: [true, 'Телефон міндетті'],
        unique: true,
        match: [/^[0-9]{11}$/, 'Телефон нөмірі дұрыс емес']
    },
    email: {
        type: String,
        required: [true, 'Email міндетті'],
        unique: true,
        lowercase: true,
        match: [/^\S+@\S+\.\S+$/, 'Email дұрыс емес']
    },
    password: {
        type: String,
        required: [true, 'Құпия сөз міндетті'],
        minlength: 6,
        select: false
    },
    city: {
        type: String,
        required: [true, 'Қала міндетті']
    },
    school: {
        type: String,
        required: [true, 'Мектеп міндетті']
    },
    grade: {
        type: Number,
        required: [true, 'Сынып міндетті'],
        min: 7,
        max: 11
    },
    avatar: {
        type: String,
        enum: ['bektur', 'nazym', null],
        default: null
    },
    avatarItems: {
        glasses: { type: Boolean, default: false },
        hat: { type: Boolean, default: false },
        goldBackground: { type: Boolean, default: false },
        superCostume: { type: Boolean, default: false }
    },
    stats: {
        intellectPoints: { type: Number, default: 0 },
        coins: { type: Number, default: 20 },
        level: { type: Number, default: 1 },
        currentLevelProgress: { type: Number, default: 0 }
    },
    completedProblems: [{
        topicId: String,
        problemId: String,
        completedAt: { type: Date, default: Date.now },
        pointsEarned: Number
    }],
    role: {
        type: String,
        enum: ['student', 'admin'],
        default: 'student'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Hash password before saving
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();

    this.password = await bcrypt.hash(this.password, 12);
    next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

// Calculate level based on points
userSchema.methods.calculateLevel = function () {
    const points = this.stats.intellectPoints;
    let level = 1;
    let requiredPoints = 100;
    let totalPoints = 0;

    while (totalPoints + requiredPoints <= points) {
        totalPoints += requiredPoints;
        level++;
        requiredPoints = 100 + (level - 1) * 150 + (level - 1) * (level - 2) * 25;
    }

    this.stats.level = level;
    this.stats.currentLevelProgress = points - totalPoints;

    return level;
};

// Get points needed for next level
userSchema.methods.getNextLevelPoints = function () {
    const level = this.stats.level;
    return 100 + level * 150 + level * (level - 1) * 25;
};

module.exports = mongoose.model('User', userSchema);
