import Foundation
import SpriteKit

final class GameScene: SKScene {
    var gameState: GameState {
        didSet {
            renderScene()
        }
    }

    var onStateChange: ((GameState) -> Void)?

    private let surviveSeconds = 180
    private var playerNode = SKShapeNode(circleOfRadius: 17)
    private var ghostNode = SKShapeNode(circleOfRadius: 22)
    private var doorNode = SKShapeNode(rectOf: CGSize(width: 126, height: 24), cornerRadius: 6)
    private var bedNode = SKShapeNode(rectOf: CGSize(width: 78, height: 46), cornerRadius: 9)
    private var auraNode = SKShapeNode(circleOfRadius: 31)
    private var turretNodes: [SKNode] = []
    private var itemNodes: [SKNode] = []
    private var labelNodes: [SKLabelNode] = []
    private var dynamicBaseNodes: [SKNode] = []
    private var lastTickTime: TimeInterval = 0

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 390, height: 780))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.backgroundColor = .clear
        setupBaseScene()
        renderScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        setupBaseScene()
        renderScene()
    }

    private func setupBaseScene() {
        removeAllChildren()
        dynamicBaseNodes.removeAll()

        let playRect = CGRect(x: 18, y: 96, width: max(40, size.width - 36), height: max(120, size.height - 196))
        let outer = SKShapeNode(rect: playRect, cornerRadius: 20)
        outer.fillColor = SKColor(red: 0.07, green: 0.06, blue: 0.13, alpha: 0.96)
        outer.strokeColor = SKColor(red: 0.47, green: 0.31, blue: 0.76, alpha: 0.85)
        outer.lineWidth = 3
        addChild(outer)

        let corridor = SKShapeNode(rect: CGRect(x: playRect.midX - 48, y: playRect.midY - 50, width: 96, height: playRect.height - 120), cornerRadius: 14)
        corridor.fillColor = SKColor(red: 0.11, green: 0.09, blue: 0.18, alpha: 1.0)
        corridor.strokeColor = SKColor(red: 0.30, green: 0.24, blue: 0.44, alpha: 1.0)
        corridor.lineWidth = 2
        addChild(corridor)

        addRoomGrid(in: playRect)
        addWarningDecorations(in: playRect)

        let room = SKShapeNode(rect: dormRoomRect(), cornerRadius: 16)
        room.fillColor = SKColor(red: 0.23, green: 0.17, blue: 0.13, alpha: 1.0)
        room.strokeColor = SKColor(red: 0.98, green: 0.78, blue: 0.34, alpha: 0.95)
        room.lineWidth = 3
        addChild(room)

        let roomTitle = makeLabel("404 寝室", size: 13, color: SKColor(red: 1.0, green: 0.84, blue: 0.42, alpha: 1.0))
        roomTitle.position = CGPoint(x: dormRoomRect().midX, y: dormRoomRect().maxY - 24)
        addChild(roomTitle)
        dynamicBaseNodes.append(roomTitle)

        doorNode.strokeColor = .white
        doorNode.lineWidth = 2
        doorNode.position = doorPosition()
        addChild(doorNode)

        bedNode.strokeColor = .white
        bedNode.lineWidth = 2
        bedNode.position = CGPoint(x: dormRoomRect().midX - 52, y: dormRoomRect().minY + 66)
        addChild(bedNode)

        auraNode.fillColor = SKColor(red: 0.18, green: 0.75, blue: 1.0, alpha: 0.10)
        auraNode.strokeColor = SKColor(red: 0.42, green: 0.86, blue: 1.0, alpha: 0.45)
        auraNode.lineWidth = 2
        addChild(auraNode)

        playerNode.fillColor = .systemBlue
        playerNode.strokeColor = .white
        playerNode.lineWidth = 2
        addChild(playerNode)

        ghostNode.fillColor = .systemRed
        ghostNode.strokeColor = SKColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        ghostNode.lineWidth = 3
        addChild(ghostNode)
    }

    private func addRoomGrid(in rect: CGRect) {
        let columns: CGFloat = 2
        let rows: CGFloat = 3
        let roomW = (rect.width - 56) / columns
        let roomH = (rect.height - 92) / rows
        for row in 0..<Int(rows) {
            for col in 0..<Int(columns) {
                let x = rect.minX + 18 + CGFloat(col) * (roomW + 20)
                let y = rect.minY + 24 + CGFloat(row) * (roomH + 16)
                let cell = SKShapeNode(rect: CGRect(x: x, y: y, width: roomW, height: roomH), cornerRadius: 12)
                cell.fillColor = SKColor(red: 0.10, green: 0.09, blue: 0.16, alpha: 0.86)
                cell.strokeColor = SKColor(red: 0.22, green: 0.18, blue: 0.34, alpha: 0.8)
                cell.lineWidth = 1.2
                addChild(cell)
                dynamicBaseNodes.append(cell)
            }
        }
    }

    private func addWarningDecorations(in rect: CGRect) {
        for idx in 0..<5 {
            let line = SKShapeNode(rectOf: CGSize(width: 52, height: 4), cornerRadius: 2)
            line.fillColor = SKColor(red: 0.94, green: 0.70, blue: 0.18, alpha: 0.7)
            line.strokeColor = .clear
            line.zRotation = -.pi / 7
            line.position = CGPoint(x: rect.minX + 50 + CGFloat(idx) * 68, y: rect.maxY - 38)
            addChild(line)
            dynamicBaseNodes.append(line)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTickTime == 0 {
            lastTickTime = currentTime
        }

        let delta = currentTime - lastTickTime
        if delta < 1.0 { return }
        lastTickTime = currentTime

        advanceGameOneSecond()
        onStateChange?(gameState)
        renderScene()
    }

    private func advanceGameOneSecond() {
        guard gameState.gameStatus == .playing else { return }

        let now = Date()
        gameState.gameTime += 1
        gameState.player.activeEffects = gameState.player.activeEffects.filter { $0.expiresAt > now }
        if gameState.ghost.isFrozen && gameState.ghost.frozenUntil <= now {
            gameState.ghost.isFrozen = false
        }

        let hasGoldBoost = hasEffect(.goldBoost)
        let hasBarrier = hasEffect(.barrier) || hasEffect(.invincible)
        let hasSlowTrap = hasEffect(.slowTrap)

        if gameState.player.isSleeping {
            let baseGoldIncome = 12 + gameState.player.bedLevel * 10
            let goldIncome = hasGoldBoost ? baseGoldIncome * 2 : baseGoldIncome
            gameState.player.gold += goldIncome
            gameState.player.electricity += max(1, gameState.player.bedLevel / 2)
        }

        if gameState.gameTime % 30 == 0 {
            gameState.ghost.attackPower += 8
            gameState.ghost.speed += 0.1
            gameState.ghost.maxHealth += 80
            gameState.ghost.health = min(gameState.ghost.maxHealth, gameState.ghost.health + 80)
        }

        moveGhostTowardDoor(slowed: hasSlowTrap)

        if gameState.ghost.position.y <= 3.05 {
            gameState.ghost.state = .attacking
        } else {
            gameState.ghost.state = .chasing
        }

        if gameState.ghost.state == .attacking && !gameState.ghost.isFrozen && !hasBarrier {
            let armorReduction = min(Float(gameState.player.doorLevel - 1) * 0.07, 0.35)
            let damage = gameState.ghost.attackPower * (1.0 - armorReduction)
            gameState.player.doorHealth = max(0, gameState.player.doorHealth - damage)
        }

        fireTurrets(now: now)

        if gameState.player.doorHealth <= 0 {
            gameState.player.isDoorBroken = true
            gameState.gameStatus = .lost
        }

        if gameState.ghost.health <= 0 || gameState.gameTime >= surviveSeconds {
            gameState.gameStatus = .won
        }

        maybeSpawnItem(now: now)
        gameState.items = gameState.items.filter { $0.expiresAt > now }
    }

    private func moveGhostTowardDoor(slowed: Bool) {
        guard !gameState.ghost.isFrozen else { return }
        let target = Position(x: 3.0, y: 3.0)
        let step = max(0.03, gameState.ghost.speed / (slowed ? 120.0 : 80.0))
        let dx = target.x - gameState.ghost.position.x
        let dy = target.y - gameState.ghost.position.y
        gameState.ghost.position.x += max(-step, min(step, dx))
        gameState.ghost.position.y += max(-step, min(step, dy))
    }

    private func fireTurrets(now: Date) {
        for index in gameState.turrets.indices {
            let turret = gameState.turrets[index]
            guard turret.position.distance(to: gameState.ghost.position) <= turret.range else { continue }
            guard now.timeIntervalSince(turret.lastShot) >= turret.cooldown else { continue }

            let damage = turret.damage + Float(turret.level - 1) * 18.0
            gameState.ghost.health = max(0, gameState.ghost.health - damage)
            gameState.turrets[index].lastShot = now
            renderLaser(from: mapPosition(turret.position), to: mapPosition(gameState.ghost.position))
        }
    }

    private func maybeSpawnItem(now: Date) {
        guard gameState.items.count < 3 else { return }
        guard Int.random(in: 1...100) <= 18 else { return }

        let type = Item.ItemType.allCases.randomElement() ?? .goldBoost
        let item = Item(
            id: UUID().uuidString,
            type: type,
            position: Position(x: Float.random(in: 1.2...4.8), y: Float.random(in: 1.2...4.8)),
            duration: 10,
            expiresAt: now.addingTimeInterval(16)
        )
        gameState.items.append(item)
    }

    private func hasEffect(_ type: Item.ItemType) -> Bool {
        gameState.player.activeEffects.contains { $0.type == type && $0.expiresAt > Date() }
    }

    private func renderScene() {
        playerNode.position = mapPosition(gameState.player.position)
        auraNode.position = playerNode.position
        auraNode.isHidden = !gameState.player.isSleeping
        ghostNode.position = mapPosition(gameState.ghost.position)
        ghostNode.fillColor = gameState.ghost.isFrozen ? .cyan : SKColor(red: 0.88, green: 0.07, blue: 0.12, alpha: 1.0)
        ghostNode.setScale(gameState.gameTime > 120 ? 1.16 : 1.0)
        doorNode.position = doorPosition()
        doorNode.fillColor = doorColor()
        bedNode.fillColor = bedColor()

        turretNodes.forEach { $0.removeFromParent() }
        turretNodes.removeAll()
        for turret in gameState.turrets {
            let base = SKShapeNode(rectOf: CGSize(width: 25 + turret.level * 3, height: 25 + turret.level * 3), cornerRadius: 5)
            base.fillColor = turret.damage > 70 ? SKColor(red: 0.24, green: 0.88, blue: 1.0, alpha: 1.0) : .systemGreen
            base.strokeColor = .white
            base.lineWidth = 2
            base.position = mapPosition(turret.position)

            let barrel = SKShapeNode(rectOf: CGSize(width: 8, height: 20), cornerRadius: 3)
            barrel.fillColor = .darkGray
            barrel.strokeColor = .white
            barrel.lineWidth = 1
            barrel.position = CGPoint(x: 0, y: 15)
            base.addChild(barrel)

            let level = makeLabel("Lv\(turret.level)", size: 9, color: .white)
            level.position = CGPoint(x: 0, y: -21)
            base.addChild(level)
            addChild(base)
            turretNodes.append(base)
        }

        itemNodes.forEach { $0.removeFromParent() }
        itemNodes.removeAll()
        for item in gameState.items {
            let node = makePickupNode(for: item)
            node.position = mapPosition(item.position)
            node.name = item.id
            addChild(node)
            itemNodes.append(node)
        }

        renderStatusLabels()
    }

    private func renderLaser(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let laser = SKShapeNode(path: path)
        laser.strokeColor = SKColor(red: 0.34, green: 0.95, blue: 1.0, alpha: 0.82)
        laser.lineWidth = 3
        laser.glowWidth = 5
        addChild(laser)
        laser.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
    }

    private func renderStatusLabels() {
        labelNodes.forEach { $0.removeFromParent() }
        labelNodes.removeAll()

        let statusText: String
        switch gameState.gameStatus {
        case .playing:
            statusText = gameState.ghost.state == .attacking ? "猛鬼正在破门！" : "夜晚倒计时：\(max(0, surviveSeconds - gameState.gameTime))s"
        case .won:
            statusText = "胜利：天亮了"
        case .lost:
            statusText = "失败：寝室失守"
        }

        let banner = makeLabel(statusText, size: 17, color: .white)
        banner.fontName = "AvenirNext-Bold"
        banner.position = CGPoint(x: size.width / 2, y: size.height - 104)
        addChild(banner)
        labelNodes.append(banner)

        let ghostIcon = makeLabel(gameState.ghost.isFrozen ? "🧊" : "👹", size: 24, color: .white)
        ghostIcon.position = CGPoint(x: ghostNode.position.x, y: ghostNode.position.y + 30)
        addChild(ghostIcon)
        labelNodes.append(ghostIcon)

        let sleepIcon = makeLabel(gameState.player.isSleeping ? "💤" : "🧑‍🎓", size: 20, color: .white)
        sleepIcon.position = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 25)
        addChild(sleepIcon)
        labelNodes.append(sleepIcon)
    }

    private func makePickupNode(for item: Item) -> SKNode {
        let container = SKNode()
        let circle = SKShapeNode(circleOfRadius: 13)
        circle.fillColor = color(for: item.type)
        circle.strokeColor = .white
        circle.lineWidth = 2
        container.addChild(circle)
        let label = makeLabel(symbol(for: item.type), size: 13, color: .white)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -4)
        container.addChild(label)
        return container
    }

    private func dormRoomRect() -> CGRect {
        let width = min(size.width - 86, 300)
        return CGRect(x: (size.width - width) / 2, y: 142, width: width, height: 224)
    }

    private func doorPosition() -> CGPoint {
        CGPoint(x: dormRoomRect().midX, y: dormRoomRect().maxY + 3)
    }

    private func mapPosition(_ position: Position) -> CGPoint {
        let playRect = CGRect(x: 42, y: 122, width: max(40, size.width - 84), height: max(120, size.height - 254))
        let x = playRect.minX + CGFloat(position.x / 6.0) * playRect.width
        let y = playRect.minY + CGFloat(position.y / 6.0) * playRect.height
        return CGPoint(x: x, y: y)
    }

    private func doorColor() -> SKColor {
        if gameState.player.doorHealth <= 0 { return .darkGray }
        let healthRatio = gameState.player.doorHealth / max(gameState.player.doorMaxHealth, 1)
        if healthRatio < 0.25 { return SKColor(red: 0.85, green: 0.18, blue: 0.12, alpha: 1.0) }
        if healthRatio < 0.55 { return SKColor(red: 0.88, green: 0.48, blue: 0.10, alpha: 1.0) }
        return SKColor(red: 0.45, green: 0.25, blue: 0.12, alpha: 1.0)
    }

    private func bedColor() -> SKColor {
        let level = min(gameState.player.bedLevel, 5)
        let blue = 0.36 + CGFloat(level) * 0.08
        return SKColor(red: 0.10, green: 0.45, blue: min(0.95, blue), alpha: 1.0)
    }

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    private func color(for type: Item.ItemType) -> SKColor {
        switch type {
        case .speedUp:
            return .systemBlue
        case .goldBoost:
            return .systemYellow
        case .doorRepair:
            return .systemGreen
        case .freezeGhost:
            return .cyan
        case .invincible:
            return .systemPurple
        case .barrier:
            return .systemOrange
        case .slowTrap:
            return .magenta
        }
    }

    private func symbol(for type: Item.ItemType) -> String {
        switch type {
        case .speedUp:
            return "↟"
        case .goldBoost:
            return "$"
        case .doorRepair:
            return "+"
        case .freezeGhost:
            return "*"
        case .invincible:
            return "◇"
        case .barrier:
            return "▣"
        case .slowTrap:
            return "~"
        }
    }
}
