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
    private var playerNode = SKShapeNode(circleOfRadius: 18)
    private var ghostNode = SKShapeNode(circleOfRadius: 20)
    private var doorNode = SKShapeNode(rectOf: CGSize(width: 118, height: 22), cornerRadius: 6)
    private var bedNode = SKShapeNode(rectOf: CGSize(width: 70, height: 44), cornerRadius: 8)
    private var turretNodes: [SKShapeNode] = []
    private var itemNodes: [SKShapeNode] = []
    private var labelNodes: [SKLabelNode] = []
    private var lastTickTime: TimeInterval = 0

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 390, height: 780))
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupBaseScene()
        renderScene()
    }

    private func setupBaseScene() {
        removeAllChildren()

        let background = SKShapeNode(rect: CGRect(x: 16, y: 86, width: size.width - 32, height: size.height - 174), cornerRadius: 18)
        background.fillColor = SKColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1.0)
        background.strokeColor = .lightGray
        background.lineWidth = 3
        addChild(background)

        let room = SKShapeNode(rect: CGRect(x: 56, y: 142, width: size.width - 112, height: 210), cornerRadius: 14)
        room.fillColor = SKColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 1.0)
        room.strokeColor = .white
        room.lineWidth = 2
        addChild(room)

        doorNode.fillColor = .brown
        doorNode.strokeColor = .white
        doorNode.position = CGPoint(x: size.width / 2, y: 352)
        addChild(doorNode)

        bedNode.fillColor = .systemTeal
        bedNode.strokeColor = .white
        bedNode.position = CGPoint(x: size.width / 2, y: 212)
        addChild(bedNode)

        playerNode.fillColor = .systemBlue
        playerNode.strokeColor = .white
        addChild(playerNode)

        ghostNode.fillColor = .systemRed
        ghostNode.strokeColor = .white
        addChild(ghostNode)
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
        let roomMinX: CGFloat = 56
        let roomMaxX: CGFloat = size.width - 56
        let roomMinY: CGFloat = 142
        let roomMaxY: CGFloat = size.height - 126

        func mapPosition(_ position: Position) -> CGPoint {
            let x = roomMinX + CGFloat(position.x / 6.0) * (roomMaxX - roomMinX)
            let y = roomMinY + CGFloat(position.y / 6.0) * (roomMaxY - roomMinY)
            return CGPoint(x: x, y: y)
        }

        playerNode.position = mapPosition(gameState.player.position)
        ghostNode.position = mapPosition(gameState.ghost.position)
        ghostNode.fillColor = gameState.ghost.isFrozen ? .cyan : .systemRed
        doorNode.fillColor = gameState.player.doorHealth <= 0 ? .darkGray : .brown

        turretNodes.forEach { $0.removeFromParent() }
        turretNodes.removeAll()
        for turret in gameState.turrets {
            let node = SKShapeNode(rectOf: CGSize(width: 24 + turret.level * 2, height: 24 + turret.level * 2), cornerRadius: 4)
            node.fillColor = .systemGreen
            node.strokeColor = .white
            node.position = mapPosition(turret.position)
            addChild(node)
            turretNodes.append(node)
        }

        itemNodes.forEach { $0.removeFromParent() }
        itemNodes.removeAll()
        for item in gameState.items {
            let node = SKShapeNode(circleOfRadius: 10)
            node.fillColor = color(for: item.type)
            node.strokeColor = .white
            node.position = mapPosition(item.position)
            node.name = item.id
            addChild(node)
            itemNodes.append(node)
        }

        renderStatusLabels()
    }

    private func renderStatusLabels() {
        labelNodes.forEach { $0.removeFromParent() }
        labelNodes.removeAll()

        let statusText: String
        switch gameState.gameStatus {
        case .playing:
            statusText = "坚持到天亮：\(max(0, surviveSeconds - gameState.gameTime))s"
        case .won:
            statusText = "胜利：守住宿舍"
        case .lost:
            statusText = "失败：房门被攻破"
        }

        let label = SKLabelNode(text: statusText)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 17
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height - 92)
        addChild(label)
        labelNodes.append(label)
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
}
