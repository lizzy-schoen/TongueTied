import SpriteKit

class GameScene: SKScene {

    // MARK: - Managers

    private let hapticManager = HapticManager()
    private let touchTracker  = TouchTracker()
    private let scoreManager  = ScoreManager()

    // MARK: - Nodes

    private var zoneNodes: [ZoneNode] = []
    private var currentTouchedZone: ZoneNode?

    // HUD
    private var scoreLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var patternLabel: SKLabelNode!
    private var feedbackLabel: SKLabelNode!

    // MARK: - State

    private var isPlaying = false

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)

        buildZones()
        buildHUD()
        wireScoreCallbacks()

        showLevelIntro(Level.all[0])
    }

    // MARK: - Zone geometry

    private func buildZones() {
        let cx = size.width / 2
        let cy = size.height * 0.45
        let s  = min(size.width, size.height) / 400     // reference scale

        addZone(.outerLabiaLeft,  oval: CGPoint(x: cx - 55*s, y: cy),          rx: 30*s, ry: 110*s, z: 0)
        addZone(.outerLabiaRight, oval: CGPoint(x: cx + 55*s, y: cy),          rx: 30*s, ry: 110*s, z: 0)
        addZone(.innerLabiaLeft,  oval: CGPoint(x: cx - 25*s, y: cy + 5*s),    rx: 18*s, ry: 85*s,  z: 1)
        addZone(.innerLabiaRight, oval: CGPoint(x: cx + 25*s, y: cy + 5*s),    rx: 18*s, ry: 85*s,  z: 1)
        addZone(.vaginalOpening,  oval: CGPoint(x: cx,        y: cy - 20*s),   rx: 14*s, ry: 25*s,  z: 2)
        addZone(.clitoralHood,    oval: CGPoint(x: cx,        y: cy + 75*s),   rx: 16*s, ry: 20*s,  z: 3)
        addZone(.clitoris,        oval: CGPoint(x: cx,        y: cy + 90*s),   rx: 10*s, ry: 10*s,  z: 4)
    }

    private func addZone(_ type: ZoneType, oval center: CGPoint,
                          rx: CGFloat, ry: CGFloat, z: CGFloat) {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: center.x - rx, y: center.y - ry,
                                   width: rx * 2, height: ry * 2))
        let node = ZoneNode(zoneType: type, path: path)
        node.zPosition = z
        zoneNodes.append(node)
        addChild(node)
    }

    // MARK: - HUD

    private func buildHUD() {
        let top = size.height - 60

        levelLabel   = makeLabel(size: 18, pos: CGPoint(x: size.width / 2, y: top))
        scoreLabel   = makeLabel(size: 22, pos: CGPoint(x: size.width / 2, y: top - 30))
        timerLabel   = makeLabel(size: 18, pos: CGPoint(x: size.width - 60, y: top - 30))
        comboLabel   = makeLabel(size: 16, pos: CGPoint(x: size.width / 2, y: top - 55))
        patternLabel = makeLabel(size: 14, pos: CGPoint(x: size.width / 2, y: 80))
        feedbackLabel = makeLabel(size: 28, pos: CGPoint(x: size.width / 2, y: size.height * 0.75))

        scoreLabel.fontColor = UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
        comboLabel.fontColor = UIColor(red: 1, green: 0.6, blue: 0.3, alpha: 1)
        patternLabel.fontColor = UIColor(white: 0.7, alpha: 1)

        [levelLabel, scoreLabel, timerLabel, comboLabel,
         patternLabel, feedbackLabel].forEach { addChild($0) }
    }

    private func makeLabel(size: CGFloat, pos: CGPoint) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "AvenirNext-Bold")
        l.fontSize = size
        l.position = pos
        l.fontColor = .white
        l.horizontalAlignmentMode = .center
        return l
    }

    // MARK: - Score callbacks

    private func wireScoreCallbacks() {
        scoreManager.onScoreUpdate = { [weak self] s in
            self?.scoreLabel.text = "Score: \(s)"
        }
        scoreManager.onComboUpdate = { [weak self] c in
            guard let self else { return }
            if c > 5 {
                comboLabel.text = "Combo x\(c)!"
                hapticManager.playTap(intensity: min(1, Float(c) / 20), sharpness: 0.3)
            } else {
                comboLabel.text = ""
            }
        }
        scoreManager.onLevelComplete = { [weak self] passed, finalScore in
            self?.handleLevelComplete(passed: passed, score: finalScore)
        }
    }

    // MARK: - Level flow

    private func showLevelIntro(_ level: Level) {
        isPlaying = false
        feedbackLabel.text = ""
        comboLabel.text = ""
        scoreLabel.text = "Score: 0"
        timerLabel.text = ""
        patternLabel.text = ""

        // Store the level so startLevel uses it
        scoreManager.startLevel(level, at: 0)   // time doesn't matter yet

        levelLabel.text = "Level \(level.number): \(level.name)"

        // Description
        let desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        desc.text = level.description
        desc.fontSize = 16
        desc.fontColor = UIColor(white: 0.85, alpha: 1)
        desc.numberOfLines = 0
        desc.preferredMaxLayoutWidth = size.width - 60
        desc.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        desc.name = "intro"
        addChild(desc)

        // Pattern hint
        let hint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hint.text = "Target: \(level.targetPattern.rawValue)"
        hint.fontSize = 14
        hint.fontColor = UIColor(white: 0.6, alpha: 1)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        hint.name = "intro"
        addChild(hint)

        // Tap prompt
        let tap = makeLabel(size: 20, pos: CGPoint(x: size.width / 2, y: size.height * 0.64))
        tap.text = "Tap to start"
        tap.fontColor = UIColor(white: 0.6, alpha: 1)
        tap.name = "intro"
        tap.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: 0.8),
            .fadeAlpha(to: 1.0, duration: 0.8)
        ])))
        addChild(tap)

        // Highlight target zones, dim others
        for zone in zoneNodes {
            if level.targetZones.contains(zone.zoneType) {
                zone.alpha = 1
                zone.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.5, duration: 0.5),
                    .fadeAlpha(to: 1.0, duration: 0.5)
                ])), withKey: "glow")
            } else {
                zone.alpha = 0.4
            }
        }
    }

    private func startCurrentLevel(at time: TimeInterval) {
        enumerateChildNodes(withName: "intro") { n, _ in n.removeFromParent() }
        for zone in zoneNodes {
            zone.removeAction(forKey: "glow")
            zone.alpha = 1
        }
        scoreManager.startLevel(scoreManager.currentLevel, at: time)
        isPlaying = true
    }

    private func handleLevelComplete(passed: Bool, score: Int) {
        isPlaying = false
        hapticManager.stopContinuous()
        touchTracker.reset()

        if passed {
            hapticManager.playSuccess()
            showFeedback("Level Complete!", color: .green)
            run(.wait(forDuration: 2)) { [weak self] in
                guard let self, let next = self.scoreManager.nextLevel() else {
                    self?.showFeedback("All levels done!", color: .yellow)
                    return
                }
                self.showLevelIntro(next)
            }
        } else {
            showFeedback("Try Again!  \(score)/\(scoreManager.currentLevel.targetScore)", color: .orange)
            run(.wait(forDuration: 2)) { [weak self] in
                guard let self else { return }
                self.showLevelIntro(self.scoreManager.currentLevel)
            }
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if !isPlaying {
            startCurrentLevel(at: touch.timestamp)
            return
        }
        processTouch(at: touch.location(in: self), timestamp: touch.timestamp)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let touch = touches.first else { return }
        processTouch(at: touch.location(in: self), timestamp: touch.timestamp)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }

    private func processTouch(at point: CGPoint, timestamp: TimeInterval) {
        touchTracker.addSample(position: point, timestamp: timestamp)

        // Hit‑test zones — higher sensitivity (z) first so small zones win
        let sorted = zoneNodes.sorted { $0.zoneType.sensitivity > $1.zoneType.sensitivity }
        let hit = sorted.first { $0.path?.contains(point) == true }

        if hit !== currentTouchedZone {
            currentTouchedZone?.setTouched(false)
            hit?.setTouched(true)

            if let zone = hit {
                hapticManager.playTap(intensity: zone.zoneType.hapticIntensity, sharpness: 0.5)
                hapticManager.startContinuous(
                    intensity: zone.zoneType.hapticIntensity * 0.5, sharpness: 0.3)
            } else {
                hapticManager.stopContinuous()
            }
            currentTouchedZone = hit
        }

        // Modulate haptic with speed
        if let zone = currentTouchedZone {
            let spd = touchTracker.speedScore(
                idealRange: scoreManager.currentLevel.idealSpeedRange)
            hapticManager.updateContinuous(
                intensity: zone.zoneType.hapticIntensity * Float(0.3 + spd * 0.7),
                sharpness: Float(spd) * 0.5)
        }

        // HUD updates
        patternLabel.text = "\(touchTracker.currentPattern.rawValue)  |  Speed \(Int(touchTracker.averageSpeed))"

        switch touchTracker.speedRating(idealRange: scoreManager.currentLevel.idealSpeedRange) {
        case 0:  showFeedback("Faster...",      color: UIColor(white: 0.5, alpha: 1))
        case 2:  showFeedback("Slower...",       color: UIColor(red: 1, green: 0.5, blue: 0.3, alpha: 1))
        default:
            if touchTracker.patternConsistency > 0.7 {
                showFeedback("Great rhythm!", color: .green)
            } else {
                showFeedback("Good!",         color: UIColor(white: 0.8, alpha: 1))
            }
        }
    }

    private func endTouch() {
        currentTouchedZone?.setTouched(false)
        currentTouchedZone = nil
        hapticManager.stopContinuous()
        touchTracker.reset()
        patternLabel.text = ""
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        guard isPlaying else { return }

        scoreManager.update(touchingZone: currentTouchedZone?.zoneType,
                            touchTracker: touchTracker,
                            currentTime: currentTime)

        let remaining = scoreManager.timeRemaining(currentTime: currentTime)
        timerLabel.text = String(format: "%.0f", remaining)
        timerLabel.fontColor = remaining < 10
            ? (remaining.truncatingRemainder(dividingBy: 1) < 0.5 ? .red : .white)
            : .white
    }

    // MARK: - Helpers

    private func showFeedback(_ text: String, color: UIColor) {
        feedbackLabel.text = text
        feedbackLabel.fontColor = color
        feedbackLabel.removeAllActions()
        feedbackLabel.alpha = 1
        feedbackLabel.run(.sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.3)]))
    }
}
