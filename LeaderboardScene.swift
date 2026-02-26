import SpriteKit

class LeaderboardScene: SKScene {

    private var themeButton: SKShapeNode!
    private var contentNode: SKNode!
    private var entryNodes: [SKNode] = []
    private var statusLabel: SKLabelNode!
    private var scrollOffset: CGFloat = 0
    private var entries: [LeaderboardEntry] = []

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 1)
        buildHeader()
        buildBackButton()
        buildThemeButton()
        buildRefreshButton()

        contentNode = SKNode()
        addChild(contentNode)

        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        statusLabel.fontSize = 16
        statusLabel.fontColor = UIColor(white: 0.5, alpha: 1)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(statusLabel)

        fetchLeaderboard()
    }

    // MARK: - Layout

    private func buildHeader() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Leaderboard"
        title.fontSize = 24
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(title)
    }

    private func buildBackButton() {
        let back = SKLabelNode(fontNamed: "AvenirNext-Medium")
        back.text = "< Menu"
        back.fontSize = 16
        back.fontColor = UIColor(white: 0.7, alpha: 1)
        back.position = CGPoint(x: size.width - 50, y: size.height - 60)
        back.horizontalAlignmentMode = .center
        back.name = "btn_back"
        back.zPosition = 50
        addChild(back)
    }

    private func buildThemeButton() {
        let top = size.height - 60
        themeButton = SKShapeNode(circleOfRadius: 14)
        themeButton.fillColor = ColorTheme.current.previewColor
        themeButton.strokeColor = UIColor(white: 0.5, alpha: 0.8)
        themeButton.lineWidth = 2
        themeButton.position = CGPoint(x: 40, y: top)
        themeButton.zPosition = 50
        addChild(themeButton)
    }

    private func buildRefreshButton() {
        let btn = SKLabelNode(fontNamed: "AvenirNext-Medium")
        btn.text = "Refresh"
        btn.fontSize = 14
        btn.fontColor = UIColor(white: 0.5, alpha: 1)
        btn.position = CGPoint(x: size.width / 2, y: size.height - 110)
        btn.name = "btn_refresh"
        addChild(btn)
    }

    // MARK: - Data

    private func fetchLeaderboard() {
        statusLabel.text = "Loading..."
        statusLabel.isHidden = false

        CloudKitService.shared.fetchLeaderboard(limit: 50) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusLabel.isHidden = true
                switch result {
                case .success(let entries):
                    self.entries = entries
                    if entries.isEmpty {
                        self.statusLabel.text = "No scores yet — be the first!"
                        self.statusLabel.isHidden = false
                    } else {
                        self.buildEntryList()
                    }
                case .failure:
                    self.statusLabel.text = "Could not load leaderboard"
                    self.statusLabel.isHidden = false
                    self.checkICloudStatus()
                }
            }
        }
    }

    private func checkICloudStatus() {
        CloudKitService.shared.checkAccountStatus { [weak self] available in
            if !available {
                DispatchQueue.main.async {
                    self?.statusLabel.text = "Sign in to iCloud to view scores"
                }
            }
        }
    }

    private func buildEntryList() {
        entryNodes.forEach { $0.removeFromParent() }
        entryNodes.removeAll()

        let myName = ScreenNameManager.current
        let startY = size.height - 145
        let rowHeight: CGFloat = 44

        for (index, entry) in entries.enumerated() {
            let y = startY - CGFloat(index) * rowHeight
            let isMe = entry.screenName == myName
            let row = buildRow(rank: index + 1, entry: entry, isMe: isMe, y: y)
            contentNode.addChild(row)
            entryNodes.append(row)
        }
    }

    private func buildRow(rank: Int, entry: LeaderboardEntry,
                          isMe: Bool, y: CGFloat) -> SKNode {
        let row = SKNode()
        row.position = CGPoint(x: 0, y: y)

        if isMe {
            let highlight = SKShapeNode(
                rect: CGRect(x: 10, y: -16, width: size.width - 20, height: 36),
                cornerRadius: 6)
            highlight.fillColor = UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 0.08)
            highlight.strokeColor = .clear
            row.addChild(highlight)
        }

        let color = isMe
            ? UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            : UIColor(white: 0.85, alpha: 1)

        let rankLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        rankLabel.text = "#\(rank)"
        rankLabel.fontSize = 16
        rankLabel.fontColor = color
        rankLabel.horizontalAlignmentMode = .left
        rankLabel.position = CGPoint(x: 25, y: 0)
        row.addChild(rankLabel)

        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        nameLabel.text = entry.screenName
        nameLabel.fontSize = 16
        nameLabel.fontColor = color
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: 70, y: 0)
        row.addChild(nameLabel)

        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "\(entry.totalScore)"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = color
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width - 25, y: 0)
        row.addChild(scoreLabel)

        return row
    }

    // MARK: - Touch / Scroll

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        if hypot(loc.x - themeButton.position.x, loc.y - themeButton.position.y) < 25 {
            ColorTheme.cycleNext()
            themeButton.fillColor = ColorTheme.current.previewColor
            return
        }

        let tapped = atPoint(loc)
        let name = tapped.name ?? tapped.parent?.name

        if name == "btn_back" {
            let scene = MainMenuScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.4))
        } else if name == "btn_refresh" {
            fetchLeaderboard()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !entries.isEmpty else { return }
        let dy = touch.location(in: self).y - touch.previousLocation(in: self).y
        let maxScroll = max(0, CGFloat(entries.count) * 44 - (size.height - 200))
        scrollOffset = max(0, min(maxScroll, scrollOffset - dy))
        contentNode.position.y = scrollOffset
    }
}
