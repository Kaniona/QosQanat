const mongoose = require('mongoose');

const newsSchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Тақырып міндетті'],
        trim: true
    },
    shortDescription: {
        type: String,
        required: [true, 'Қысқаша сипаттама міндетті'],
        maxlength: 200
    },
    fullDescription: {
        type: String,
        required: [true, 'Толық сипаттама міндетті']
    },
    image: {
        type: String,
        required: [true, 'Сурет міндетті']
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    published: {
        type: Boolean,
        default: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('News', newsSchema);
