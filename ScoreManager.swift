import Foundation
import CoreGraphics

class ScoreManager {
    private(set) var score: Int = 0
    private(set) var combo: Int = 0
    private(set) var maxCombo: Int = 0
    private(set) var currentLevel: Level

    private var levelStartTime: TimeInterval = 0
    private var isLevelActive = false

    // Callbacks — the scene hooks into these to update the HUD
    var onScoreUpdate: ((Int) -> Void)?
    var onComboUpdate: ((Int) -> Void)?
    var onLevelComplete: ((_ passed: Bool, _ finalScore: Int) -> Void)?

    // MARK: - Persistent high scores

    private static let highScorePrefix = "highScore_level_"

    static func highScore(for level: Int) -> Int {
        UserDefaults.standard.integer(forKey: "\(highScorePrefix)\(level)")
    }

    static func setHighScore(_ score: Int, for level: Int) {
        let key = "\(highScorePrefix)\(level)"
        if score > UserDefaults.standard.integer(forKey: key) {
            UserDefaults.standard.set(score, forKey: key)
        }
    }

    static func highestCompletedLevel() -> Int {
        for level in Level.all.reversed() {
            if highScore(for: level.number) >= level.targetScore { return level.number }
        }
        return 0
    }

    init() {
        currentLevel = Level.all[0]
    }

    // MARK: - Level lifecycle

    func startLevel(_ level: Level, at time: TimeInterval) {
        currentLevel = level
        score = 0
        combo = 0
        maxCombo = 0
        levelStartTime = time
        isLevelActive = true
    }

    func timeRemaining(currentTime: TimeInterval) -> TimeInterval {
        guard isLevelActive else { return 0 }
        return max(0, currentLevel.duration - (currentTime - levelStartTime))
    }

    func nextLevel() -> Level? {
        Level.all.first { $0.number == currentLevel.number + 1 }
    }

    // MARK: - Per‑frame update

    func update(touchingZone: ZoneType?,
                touchTracker: TouchTracker,
                currentTime: TimeInterval) {
        guard isLevelActive else { return }

        // Time up?
        if currentTime - levelStartTime >= currentLevel.duration {
            endLevel()
            return
        }

        guard let zone = touchingZone else {
            if combo > 0 {
                combo = 0
                onComboUpdate?(combo)
            }
            return
        }

        // --- Compute frame score ---

        var pts: CGFloat = 1.0      // base point per frame

        // Zone bonus
        let isTarget = currentLevel.targetZones.contains(zone)
        pts *= zone.sensitivity * (isTarget ? 2.0 : 0.5)

        // Speed bonus  (0.5× – 1.5×)
        let spd = touchTracker.speedScore(idealRange: currentLevel.idealSpeedRange)
        pts *= (0.5 + spd)

        // Pattern bonus (1× – 2×)
        let patternMatch = currentLevel.targetPattern == .unknown
                        || touchTracker.currentPattern == currentLevel.targetPattern
        if patternMatch {
            pts *= (1.0 + touchTracker.patternConsistency)
        }

        // Combo
        if isTarget && spd > 0.5 {
            combo += 1
            maxCombo = max(maxCombo, combo)
        } else {
            combo = max(0, combo - 1)
        }
        let comboMul = 1.0 + CGFloat(min(combo, 100)) / 50.0   // up to 3×
        pts *= comboMul

        score += max(1, Int(pts))

        onScoreUpdate?(score)
        onComboUpdate?(combo)
    }

    // MARK: - Private

    private func endLevel() {
        isLevelActive = false
        ScoreManager.setHighScore(score, for: currentLevel.number)
        onLevelComplete?(score >= currentLevel.targetScore, score)
    }
}
