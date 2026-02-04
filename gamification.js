// QosQanat - Gamification Module

// Calculate level based on points
function calculateLevel(points) {
    let level = 1;
    let requiredPoints = 100;
    let totalPoints = 0;

    while (totalPoints + requiredPoints <= points) {
        totalPoints += requiredPoints;
        level++;
        requiredPoints = 100 + (level - 1) * 150 + (level - 1) * (level - 2) * 25;
    }

    return {
        level,
        currentProgress: points - totalPoints,
        nextLevelPoints: requiredPoints
    };
}

// Calculate coins reward for level up
function calculateCoinReward(level) {
    return 10 + level * 20;
}

// Format level display
function formatLevel(level) {
    return `Деңгей ${level}`;
}

// Format points display
function formatPoints(points) {
    return `${points} ұпай`;
}

// Format coins display
function formatCoins(coins) {
    return `${coins} coin`;
}

// Show level up animation
function showLevelUpAnimation(newLevel, coinReward) {
    const modal = document.createElement('div');
    modal.className = 'modal show';
    modal.innerHTML = `
        <div class="modal-content animate-bounce-in">
            <div class="modal-body text-center">
                <div style="font-size: 80px; margin-bottom: 20px;">🎉</div>
                <h2 class="text-primary">Құттықтаймыз!</h2>
                <p class="text-xl">Сіз ${newLevel}-деңгейге көтерілдіңіз!</p>
                <div class="level-badge level-badge-lg" style="font-size: 24px; padding: 15px 30px; margin: 20px auto;">
                    <span class="level-badge-icon">⭐</span>
                    Деңгей ${newLevel}
                </div>
                <p class="text-lg text-success">+${coinReward} coin марапаты!</p>
                <button class="btn btn-primary btn-lg mt-lg" onclick="this.closest('.modal').remove()">
                    Жалғастыру
                </button>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

// Update stats display on page
function updateStatsDisplay(stats) {
    const levelInfo = calculateLevel(stats.intellectPoints);

    // Update level
    const levelElements = document.querySelectorAll('[data-stat="level"]');
    levelElements.forEach(el => {
        el.textContent = stats.level;
    });

    // Update points
    const pointsElements = document.querySelectorAll('[data-stat="points"]');
    pointsElements.forEach(el => {
        el.textContent = stats.intellectPoints;
    });

    // Update coins
    const coinsElements = document.querySelectorAll('[data-stat="coins"]');
    coinsElements.forEach(el => {
        el.textContent = stats.coins;
    });

    // Update progress bars
    const progressBars = document.querySelectorAll('[data-progress="level"]');
    progressBars.forEach(bar => {
        const percentage = (levelInfo.currentProgress / levelInfo.nextLevelPoints) * 100;
        bar.style.width = `${percentage}%`;
        bar.setAttribute('aria-valuenow', percentage);
    });
}

// Create stats widget
function createStatsWidget(stats) {
    const levelInfo = calculateLevel(stats.intellectPoints);

    return `
        <div class="stats-widget">
            <div class="stat-item">
                <div class="stat-icon">⭐</div>
                <div class="stat-value" data-stat="level">${stats.level}</div>
                <div class="stat-label">Деңгей</div>
            </div>
            <div class="stat-item">
                <div class="stat-icon">🧠</div>
               <div class="stat-value" data-stat="points">${stats.intellectPoints}</div>
                <div class="stat-label">Ақыл ұпайы</div>
            </div>
            <div class="stat-item">
                <div class="stat-icon">🪙</div>
                <div class="stat-value" data-stat="coins">${stats.coins}</div>
                <div class="stat-label">Coin</div>
            </div>
        </div>
        <div class="mt-md">
            <div class="d-flex justify-between mb-sm">
                <span class="text-sm">Келесі деңгейге дейін</span>
                <span class="text-sm fw-bold">${levelInfo.currentProgress} / ${levelInfo.nextLevelPoints}</span>
            </div>
            <div class="progress progress-lg">
                <div class="progress-bar" data-progress="level" style="width: ${(levelInfo.currentProgress / levelInfo.nextLevelPoints) * 100}%"></div>
            </div>
        </div>
    `;
}

// Initialize gamification on page load (localStorage mode)
function initGamification() {
    try {
        // Load stats from localStorage
        const stats = JSON.parse(localStorage.getItem('userStats') || '{"level":1,"intellectPoints":0,"coins":20}');
        updateStatsDisplay(stats);
    } catch (error) {
        console.error('Gamification init error:', error);
    }
}

// Export functions for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        calculateLevel,
        calculateCoinReward,
        formatLevel,
        formatPoints,
        formatCoins,
        showLevelUpAnimation,
        updateStatsDisplay,
        createStatsWidget,
        initGamification
    };
}
