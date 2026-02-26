import SpriteKit

class GameScene: SKScene {

    // MARK: - Managers

    private let hapticManager = HapticManager()
    private let touchTracker  = TouchTracker()
    private let scoreManager  = ScoreManager()
    private let audioSynthManager = AudioSynthManager()

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
    private var themeButton: SKShapeNode!

    // MARK: - State

    var gameMode: GameMode = .level(number: 1)

    private var isDontStopMode: Bool {
        if case .dontStop = gameMode { return true }
        return false
    }

    private var isPlaying = false
    private var isGamePaused = false
    private var pauseTime: TimeInterval = 0
    private let maxProximityRange: CGFloat = 150
    private var resignObserver: Any?

    // Don't Stop mode state
    private var dontStopExcitement: Float = 0
    private var touchDuration: TimeInterval = 0
    private var touchStartTime: TimeInterval?
    private var backButton: SKLabelNode?
    private var menuButton: SKLabelNode?

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)

        buildZones()
        buildHUD()
        wireScoreCallbacks()
        audioSynthManager.setup()

        resignObserver = NotificationCenter.default.addObserver(
            forName: .appWillResignActive, object: nil, queue: .main
        ) { [weak self] _ in self?.pauseGame() }

        switch gameMode {
        case .level(let number):
            showLevelIntro(Level.all[number - 1])
        case .dontStop:
            enterDontStopMode()
        }
    }

    deinit {
        if let o = resignObserver { NotificationCenter.default.removeObserver(o) }
    }

    // MARK: - Zone geometry

    private func buildZones() {
        let cx = size.width / 2
        let cy = size.height * 0.45
        let s  = min(size.width, size.height) / 300     // reference scale

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

        // Theme selector button (top-left)
        themeButton = SKShapeNode(circleOfRadius: 14)
        themeButton.fillColor = ColorTheme.current.previewColor
        themeButton.strokeColor = UIColor(white: 0.5, alpha: 0.8)
        themeButton.lineWidth = 2
        themeButton.position = CGPoint(x: 40, y: top)
        themeButton.zPosition = 50
        addChild(themeButton)
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

        audioSynthManager.silence()

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

        // High score
        let best = ScoreManager.highScore(for: level.number)
        if best > 0 {
            let hs = SKLabelNode(fontNamed: "AvenirNext-Medium")
            hs.text = "Best: \(best)"
            hs.fontSize = 14
            hs.fontColor = UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 0.7)
            hs.position = CGPoint(x: size.width / 2, y: size.height * 0.66)
            hs.name = "intro"
            addChild(hs)
        }

        // Tap prompt
        let tap = makeLabel(size: 20, pos: CGPoint(x: size.width / 2, y: size.height * 0.60))
        tap.text = "Tap to start"
        tap.fontColor = UIColor(white: 0.6, alpha: 1)
        tap.name = "intro"
        tap.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: 0.8),
            .fadeAlpha(to: 1.0, duration: 0.8)
        ])))
        addChild(tap)

        // Menu button on intro screen
        let menuBtn = SKLabelNode(fontNamed: "AvenirNext-Medium")
        menuBtn.text = "Menu >"
        menuBtn.fontSize = 16
        menuBtn.fontColor = UIColor(white: 0.6, alpha: 1)
        menuBtn.position = CGPoint(x: size.width - 50, y: size.height - 60)
        menuBtn.name = "intro"
        menuBtn.zPosition = 50
        addChild(menuBtn)
        menuButton = menuBtn

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

    private func enterDontStopMode() {
        scoreLabel.isHidden = true
        comboLabel.isHidden = true
        timerLabel.isHidden = true
        levelLabel.text = "Don't Stop"

        for zone in zoneNodes { zone.alpha = 1 }

        let back = SKLabelNode(fontNamed: "AvenirNext-Medium")
        back.text = "< Back"
        back.fontSize = 16
        back.fontColor = UIColor(white: 0.7, alpha: 1)
        back.position = CGPoint(x: size.width - 50, y: size.height - 60)
        back.name = "btn_back"
        back.zPosition = 50
        addChild(back)
        backButton = back

        // Use Freestyle level config for speed ranges
        scoreManager.startLevel(Level.all[5], at: 0)
        isPlaying = true
    }

    private func navigateToMenu() {
        audioSynthManager.silence()
        hapticManager.stopContinuous()
        hapticManager.stopProximity()
        touchTracker.reset()

        let menu = MainMenuScene(size: size)
        menu.scaleMode = .aspectFill
        view?.presentScene(menu, transition: .fade(withDuration: 0.4))
    }

    private func startCurrentLevel(at time: TimeInterval) {
        menuButton = nil
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
        hapticManager.stopProximity()
        touchTracker.reset()
        audioSynthManager.silence()

        if passed {
            hapticManager.playSuccess()
            let prevBest = ScoreManager.highScore(for: scoreManager.currentLevel.number)
            let isNewBest = score > prevBest
            if isNewBest { submitTotalScoreToLeaderboard() }
            showFeedback(isNewBest ? "New Best!" : "Level Complete!", color: .green)
            run(.wait(forDuration: 2)) { [weak self] in
                guard let self else { return }
                if let next = self.scoreManager.nextLevel() {
                    self.showLevelIntro(next)
                } else {
                    self.showFeedback("All levels done!", color: .yellow)
                    self.run(.wait(forDuration: 1.5)) { [weak self] in
                        guard let self else { return }
                        let scene = LevelSelectScene(size: self.size)
                        scene.scaleMode = .aspectFill
                        self.view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                    }
                }
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
        let loc = touch.location(in: self)
        if hypot(loc.x - themeButton.position.x, loc.y - themeButton.position.y) < 25 {
            cycleTheme()
            return
        }
        if let back = backButton, back.contains(loc) {
            navigateToMenu()
            return
        }
        if let menu = menuButton, menu.contains(loc) {
            navigateToMenu()
            return
        }
        if isGamePaused {
            resumeGame()
            return
        }
        if !isPlaying {
            startCurrentLevel(at: touch.timestamp)
            return
        }
        if isDontStopMode && touchStartTime == nil {
            touchStartTime = touch.timestamp
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

            // Border bump when moving between zones (not first touch or leaving all zones)
            if currentTouchedZone != nil && hit != nil {
                hapticManager.playBorderBump()
            }

            if let zone = hit {
                // Stop proximity haptics when entering a zone
                hapticManager.stopProximity()

                // Zone-specific textured haptic
                hapticManager.playTap(intensity: zone.zoneType.hapticIntensity, sharpness: 0.5)
                hapticManager.startContinuousForZone(zone.zoneType.hapticProfile)

                // Audio: set new target frequency (portamento handles the glide)
                var synthState = currentSynthState()
                synthState.isActive = true
                synthState.targetFreq = zone.zoneType.baseToneFrequency
                audioSynthManager.updateState(synthState)
            } else {
                hapticManager.stopContinuous()

                // Audio: begin fade-out
                audioSynthManager.silence()
            }
            currentTouchedZone = hit
        }

        // Proximity haptics when finger is off all zones
        if hit == nil {
            let nearestDistance = zoneNodes
                .map { hypot($0.centroid.x - point.x, $0.centroid.y - point.y) }
                .min() ?? .greatestFiniteMagnitude
            hapticManager.playProximityFeedback(distance: nearestDistance, maxDistance: maxProximityRange)
        }

        // Modulate haptic and audio with speed
        if let zone = currentTouchedZone {
            let spd = touchTracker.speedScore(
                idealRange: scoreManager.currentLevel.idealSpeedRange)
            let profile = zone.zoneType.hapticProfile

            // Haptic: modulate within zone's sharpness range
            let sharpness = profile.sustainSharpnessRange.lowerBound +
                Float(spd) * (profile.sustainSharpnessRange.upperBound - profile.sustainSharpnessRange.lowerBound)
            hapticManager.updateContinuous(
                intensity: profile.baseIntensity * Float(0.3 + spd * 0.7),
                sharpness: sharpness)

            // Audio: update speed and pattern modulation
            var synthState = currentSynthState()
            synthState.isActive = true
            synthState.targetFreq = zone.zoneType.baseToneFrequency
            synthState.speedModulation = Float(spd)
            synthState.patternModulation = Float(touchTracker.patternConsistency)
            audioSynthManager.updateState(synthState)
        }

        // HUD updates
        if isDontStopMode {
            patternLabel.text = touchTracker.currentPattern.rawValue
        } else {
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
    }

    private func endTouch() {
        currentTouchedZone?.setTouched(false)
        currentTouchedZone = nil
        hapticManager.stopContinuous()
        hapticManager.stopProximity()
        touchTracker.reset()
        patternLabel.text = ""
        audioSynthManager.silence()
        touchStartTime = nil
        touchDuration = 0
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        guard isPlaying else { return }

        if isDontStopMode {
            if let start = touchStartTime, currentTouchedZone != nil {
                touchDuration = currentTime - start
            }
            updateDontStopExcitement()
            return
        }

        scoreManager.update(touchingZone: currentTouchedZone?.zoneType,
                            touchTracker: touchTracker,
                            currentTime: currentTime)

        let remaining = scoreManager.timeRemaining(currentTime: currentTime)
        timerLabel.text = String(format: "%.0f", remaining)
        timerLabel.fontColor = remaining < 10
            ? (remaining.truncatingRemainder(dividingBy: 1) < 0.5 ? .red : .white)
            : .white
    }

    private func updateDontStopExcitement() {
        guard currentTouchedZone != nil else {
            dontStopExcitement = max(0, dontStopExcitement - 0.002)
            return
        }
        let speedFactor = Float(touchTracker.speedScore(
            idealRange: Level.all[5].idealSpeedRange))
        let patternFactor = Float(touchTracker.patternConsistency)
        let durationFactor = min(1.0, Float(touchDuration / 10.0))

        let target = speedFactor * 0.35 + patternFactor * 0.35 + durationFactor * 0.30
        dontStopExcitement += (target - dontStopExcitement) * 0.02
        dontStopExcitement = min(1.0, max(0, dontStopExcitement))
    }

    // MARK: - Synth state

    private func currentSynthState() -> SynthState {
        let freq = currentTouchedZone?.zoneType.baseToneFrequency ?? 220.0
        let active = currentTouchedZone != nil

        if isDontStopMode {
            return SynthState(
                isActive: active,
                fundamentalFreq: freq, targetFreq: freq,
                amplitude: active ? (0.15 + dontStopExcitement * 0.50) : 0,
                excitement: dontStopExcitement,
                speedModulation: 0, patternModulation: 0
            )
        }

        let combo = scoreManager.combo
        let score = scoreManager.score
        let level = scoreManager.currentLevel

        let comboFactor = Float(min(combo, 50)) / 50.0
        let scoreFactor = Float(score) / Float(max(1, level.targetScore))
        let excitement  = min(1.0, comboFactor * 0.5 + scoreFactor * 0.3)

        return SynthState(
            isActive: active,
            fundamentalFreq: freq, targetFreq: freq,
            amplitude: active ? (0.15 + excitement * 0.50) : 0,
            excitement: excitement,
            speedModulation: 0, patternModulation: 0
        )
    }

    // MARK: - Pause / Resume

    private func pauseGame() {
        guard isPlaying, !isGamePaused else { return }
        isGamePaused = true
        endTouch()

        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 0, alpha: 0.6)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 100
        overlay.name = "pause"
        addChild(overlay)

        let label = makeLabel(size: 28, pos: CGPoint(x: size.width / 2, y: size.height / 2))
        label.text = "Paused — Tap to Resume"
        label.zPosition = 101
        label.name = "pause"
        addChild(label)

        self.view?.isPaused = true
    }

    private func resumeGame() {
        guard isGamePaused else { return }
        isGamePaused = false
        enumerateChildNodes(withName: "pause") { n, _ in n.removeFromParent() }
        self.view?.isPaused = false
    }

    // MARK: - Helpers

    private func submitTotalScoreToLeaderboard() {
        guard let name = ScreenNameManager.current, !name.isEmpty else { return }
        let total = ScoreManager.totalBestScore()
        CloudKitService.shared.submitScore(screenName: name, totalScore: total) { result in
            if case .failure(let err) = result {
                print("Leaderboard submit failed: \(err)")
            }
        }
    }

    private func cycleTheme() {
        ColorTheme.cycleNext()
        themeButton.fillColor = ColorTheme.current.previewColor
        for zone in zoneNodes { zone.applyTheme() }
        showFeedback(ColorTheme.current.name, color: .white)
    }

    private func showFeedback(_ text: String, color: UIColor) {
        feedbackLabel.text = text
        feedbackLabel.fontColor = color
        feedbackLabel.removeAllActions()
        feedbackLabel.alpha = 1
        feedbackLabel.run(.sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.3)]))
    }
}
