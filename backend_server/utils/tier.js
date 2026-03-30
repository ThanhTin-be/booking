const TIERS = {
    MEMBER: 'member',
    SILVER: 'silver',
    GOLD: 'gold',
    PLATINUM: 'platinum'
};

/**
 * Chuẩn hoá quy tắc chuyển đổi points → tier.
 *
 * - member:   0 <= points < 500
 * - silver:   500 <= points < 1500
 * - gold:     1500 <= points < 3000
 * - platinum: points >= 3000
 *
 * @param {number} points
 * @returns {'member' | 'silver' | 'gold' | 'platinum'}
 */
function getTierFromPoints(points) {
    const safePoints = Number.isFinite(points) && points > 0 ? Math.floor(points) : 0;

    if (safePoints >= 3000) return TIERS.PLATINUM;
    if (safePoints >= 1500) return TIERS.GOLD;
    if (safePoints >= 500) return TIERS.SILVER;
    return TIERS.MEMBER;
}

module.exports = {
    TIERS,
    getTierFromPoints
};

