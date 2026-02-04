const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/qosqanat', {
    useNewUrlParser: true,
    useUnifiedTopology: true
})
    .then(() => console.log('✅ MongoDB қосылды'))
    .catch(err => {
        console.error('❌ MongoDB қосылу қатесі:', err);
        process.exit(1);
    });

// Create default admin
async function createDefaultAdmin() {
    try {
        // Check if admin already exists
        const existingAdmin = await User.findOne({ phone: '87713399824' });

        if (existingAdmin) {
            console.log('ℹ️  Default admin бұрыннан бар');
            return;
        }

        // Create admin user
        const admin = await User.create({
            fullName: 'QosQanat Admin',
            phone: '87713399824',
            email: 'admin@qosqanat.kz',
            password: '02110166n',
            city: 'Астана',
            school: 'Admin',
            grade: 0,
            role: 'admin'
        });

        console.log('✅ Default admin жасалды:');
        console.log(`   Телефон: 87713399824`);
        console.log(`   Пароль: 02110166n`);
    } catch (error) {
        console.error('❌ Admin жасау қатесі:', error);
    }
}

// Create demo students
async function createDemoStudents() {
    try {
        const demoStudents = [
            {
                fullName: 'Айдар Серікбаев',
                phone: '87011111111',
                email: 'aidar@test.kz',
                password: 'test123',
                city: 'Астана',
                school: '№1 Назарбаев Зияткерлік мектебі',
                grade: 10,
                stats: { intellectPoints: 850, coins: 120, level: 1 }
            },
            {
                fullName: 'Жанар Қалиева',
                phone: '87012222222',
                email: 'zhanar@test.kz',
                password: 'test123',
                city: 'Алматы',
                school: '№28 гимназиясы',
                grade: 9,
                stats: { intellectPoints: 720, coins: 95, level: 1 }
            },
            {
                fullName: 'Нұрсұлтан Әбдіғалиев',
                phone: '87013333333',
                email: 'nursultan@test.kz',
                password: 'test123',
                city: 'Астана',
                school: '№45 мектебі',
                grade: 11,
                stats: { intellectPoints: 950, coins: 150, level: 1 }
            },
            {
                fullName: 'Айгерім Темірбекова',
                phone: '87014444444',
                email: 'aigerim@test.kz',
                password: 'test123',
                city: 'Шымкент',
                school: '№12 гимназиясы',
                grade: 8,
                stats: { intellectPoints: 650, coins: 80, level: 1 }
            },
            {
                fullName: 'Ерлан Досмұхамбетов',
                phone: '87015555555',
                email: 'yerlan@test.kz',
                password: 'test123',
                city: 'Қарағанды',
                school: '№7 мектебі',
                grade: 10,
                stats: { intellectPoints: 780, coins: 100, level: 1 }
            }
        ];

        for (const student of demoStudents) {
            const existing = await User.findOne({ phone: student.phone });
            if (!existing) {
                const user = await User.create(student);
                user.calculateLevel();
                await user.save();
                console.log(`✅ Demo студент жасалды: ${student.fullName}`);
            }
        }
    } catch (error) {
        console.error('❌ Demo студенттер жасау қатесі:', error);
    }
}

// Run seed
async function seed() {
    console.log('🌱 Seed бастау...\n');

    await createDefaultAdmin();
    await createDemoStudents();

    console.log('\n✅ Seed аяқталды!');
    console.log('\nЕнді серверді іске қосыңыз: npm run dev\n');

    process.exit(0);
}

seed();
