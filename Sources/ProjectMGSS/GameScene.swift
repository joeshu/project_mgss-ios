import Foundation
import SpriteKit

final class GameScene: SKScene {
    var gameState: GameState {
        didSet { renderScene() }
    }

    var onStateChange: ((GameState) -> Void)?

    private let surviveSeconds = 180
    private var playerNode = SKShapeNode(circleOfRadius: 17)
    private var ghostNode = SKShapeNode(circleOfRadius: 22)
    private var doorNode = SKShapeNode(rectOf: CGSize(width: 110, height: 22), cornerRadius: 6)
    private var bedNode = SKShapeNode(rectOf: CGSize(width: 70, height: 42), cornerRadius: 9)
    private var auraNode = SKShapeNode(circleOfRadius: 31)
    private var ghostPressureRing = SKShapeNode(circleOfRadius: 34)
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

        let playRect = boardRect()
        let outer = SKShapeNode(rect: playRect, cornerRadius: 20)
        outer.fillColor = SKColor(red: 0.07, green: 0.06, blue: 0.13, alpha: 0.96)
        outer.strokeColor = SKColor(red: 0.47, green: 0.31, blue: 0.76, alpha: 0.85)
        outer.lineWidth = 3
        addChild(outer)

        let corridor = SKShapeNode(rect: CGRect(x: playRect.midX - 46, y: playRect.minY + 34, width: 92, height: playRect.height - 72), cornerRadius: 14)
        corridor.fillColor = SKColor(red: 0.11, green: 0.09, blue: 0.18, alpha: 1.0)
        corridor.strokeColor = SKColor(red: 0.30, green: 0.24, blue: 0.44, alpha: 1.0)
        corridor.lineWidth = 2
        addChild(corridor)

        addRoomGrid(in: playRect)
        addCorridorTiles(in: playRect)
        addBuildSlotHints(in: playRect)

        doorNode.strokeColor = .white
        doorNode.lineWidth = 2
        addChild(doorNode)

        bedNode.strokeColor = .white
        bedNode.lineWidth = 2
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

        ghostPressureRing.fillColor = .clear
        ghostPressureRing.strokeColor = SKColor(red: 1.0, green: 0.14, blue: 0.18, alpha: 0.62)
        ghostPressureRing.lineWidth = 3
        ghostPressureRing.glowWidth = 8
        addChild(ghostPressureRing)
    }

    private func boardRect() -> CGRect {
        let compact = size.height < 720 || size.width < 380
        let landscape = size.width > size.height
        let topReserve: CGFloat = landscape ? 82 : (compact ? 214 : 236)
        let bottomReserve: CGFloat = landscape ? 76 : (compact ? 172 : 194)
        let minY = max(58, bottomReserve)
        let visibleMaxY = max(minY + 160, size.height - topReserve)
        let clampedMaxY = min(size.height - 24, visibleMaxY)
        return CGRect(
            x: compact ? 12 : 18,
            y: minY,
            width: max(40, size.width - (compact ? 24 : 36)),
            height: max(160, clampedMaxY - minY)
        )
    }

    private func addRoomGrid(in rect: CGRect) {
        for room in DormRoom.allCases {
            let roomRect = dormRoomRect(for: room)
            let isSelected = room.id == gameState.selectedRoom.id
            let cell = SKShapeNode(rect: roomRect, cornerRadius: 14)
            cell.fillColor = isSelected ? SKColor(red: 0.23, green: 0.17, blue: 0.13, alpha: 1.0) : SKColor(red: 0.10, green: 0.09, blue: 0.16, alpha: 0.86)
            cell.strokeColor = isSelected ? SKColor(red: 0.98, green: 0.78, blue: 0.34, alpha: 0.95) : SKColor(red: 0.22, green: 0.18, blue: 0.34, alpha: 0.8)
            cell.lineWidth = isSelected ? 3 : 1.2
            addChild(cell)
            dynamicBaseNodes.append(cell)

            let title = makeLabel(room.name, size: 11, color: isSelected ? SKColor(red: 1.0, green: 0.84, blue: 0.42, alpha: 1.0) : SKColor.white.withAlphaComponent(0.56))
            title.position = CGPoint(x: roomRect.midX, y: roomRect.maxY - 18)
            addChild(title)
            dynamicBaseNodes.append(title)
        }
    }

    private func addCorridorTiles(in rect: CGRect) {
        let centerX = rect.midX
        let tileCount = 8
        for index in 0..<tileCount {
            let tile = SKShapeNode(rectOf: CGSize(width: 70, height: 18), cornerRadius: 5)
            tile.fillColor = SKColor(red: 0.16, green: 0.13, blue: 0.23, alpha: index % 2 == 0 ? 0.85 : 0.55)
            tile.strokeColor = SKColor(red: 0.36, green: 0.29, blue: 0.48, alpha: 0.45)
            tile.lineWidth = 1
            tile.position = CGPoint(x: centerX, y: rect.minY + 68 + CGFloat(index) * max(30, rect.height / 9))
            addChild(tile)
            dynamicBaseNodes.append(tile)
        }
    }

    private func addBuildSlotHints(in rect: CGRect) {
        let selectedSlots = gameState.selectedRoom.turretSlots
        for slot in selectedSlots.prefix(3) {
            let marker = SKShapeNode(circleOfRadius: 12)
            marker.fillColor = SKColor(red: 0.10, green: 0.22, blue: 0.26, alpha: 0.72)
            marker.strokeColor = SKColor(red: 0.38, green: 0.92, blue: 1.0, alpha: 0.70)
            marker.lineWidth = 1.5
            marker.position = mapPosition(slot)
            addChild(marker)
            dynamicBaseNodes.append(marker)

            let plus = makeLabel("+", size: 16, color: SKColor(red: 0.58, green: 0.96, blue: 1.0, alpha: 0.92))
            plus.position = CGPoint(x: marker.position.x, y: marker.position.y - 1)
            addChild(plus)
            dynamicBaseNodes.append(plus)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTickTime == 0 { lastTickTime = currentTime }
        let delta = currentTime - lastTickTime
        if delta < 1.0 { return }
        lastTickTime = currentTime

        advanceGameOneSecond()
        onStateChange?(gameState)
        renderScene()
    }

    private func advanceGameOneSecond() {
        guard gameState.gameStatus == .playing, gameState.phase == .nightDefense else { return }

        let now = Date()
        gameState.gameTime += 1
        gameState.player.position = gameState.selectedRoom.playerPosition
        gameState.player.activeEffects = gameState.player.activeEffects.filter { $0.expiresAt > now }
        if gameState.ghost.isFrozen && gameState.ghost.frozenUntil <= now { gameState.ghost.isFrozen = false }

        let hasGoldBoost = hasEffect(.goldBoost)
        let hasBarrier = hasEffect(.barrier) || hasEffect(.invincible)
        let hasSlowTrap = hasEffect(.slowTrap)

        if gameState.player.isSleeping {
            let baseGoldIncome = 12 + gameState.player.bedLevel * 10 + gameState.selectedRoom.rewardBonus
            let goldIncome = hasGoldBoost ? baseGoldIncome * 2 : baseGoldIncome
            gameState.player.gold += goldIncome
            gameState.player.electricity += max(1, gameState.player.bedLevel / 2)
        }

        if gameState.gameTime % 30 == 0 {
            gameState.wave += 1
            gameState.ghost.attackPower += Float(7 + gameState.selectedRoom.risk)
            gameState.ghost.speed += 0.08
            gameState.ghost.maxHealth += Float(70 + gameState.selectedRoom.risk * 10)
            gameState.ghost.health = min(gameState.ghost.maxHealth, gameState.ghost.health + 80)
        }

        moveGhostTowardRoomDoor(slowed: hasSlowTrap)
        updateGhostState()

        if (gameState.ghost.state == .attacking || gameState.ghost.state == .enraged) && !gameState.ghost.isFrozen && !hasBarrier {
            let armorReduction = min(Float(gameState.player.doorLevel - 1) * 0.07, 0.35)
            let rageMultiplier: Float = gameState.ghost.state == .enraged ? 1.22 : 1.0
            let damage = gameState.ghost.attackPower * rageMultiplier * (1.0 - armorReduction)
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

    private func moveGhostTowardRoomDoor(slowed: Bool) {
        guard !gameState.ghost.isFrozen else { return }
        let target = gameState.selectedRoom.doorPosition
        let step = max(0.03, gameState.ghost.speed / (slowed ? 122.0 : 82.0))
        let dx = target.x - gameState.ghost.position.x
        let dy = target.y - gameState.ghost.position.y
        gameState.ghost.position.x += max(-step, min(step, dx))
        gameState.ghost.position.y += max(-step, min(step, dy))
    }

    private func updateGhostState() {
        if gameState.ghost.position.distance(to: gameState.selectedRoom.doorPosition) <= 0.18 {
            gameState.ghost.state = gameState.gameTime > 120 ? .enraged : .attacking
        } else if gameState.gameTime < 16 {
            gameState.ghost.state = .scouting
        } else {
            gameState.ghost.state = .approaching
        }
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
        let slot = gameState.selectedRoom.turretSlots.randomElement() ?? gameState.selectedRoom.playerPosition
        let item = Item(id: UUID().uuidString, type: type, position: slot, duration: 10, expiresAt: now.addingTimeInterval(16))
        gameState.items.append(item)
    }

    private func hasEffect(_ type: Item.ItemType) -> Bool {
        gameState.player.activeEffects.contains { $0.type == type && $0.expiresAt > Date() }
    }

    private func renderScene() {
        playerNode.position = mapPosition(gameState.player.position)
        auraNode.position = playerNode.position
        auraNode.isHidden = !gameState.player.isSleeping || gameState.phase == .choosingRoom
        ghostNode.position = mapPosition(gameState.ghost.position)
        ghostNode.fillColor = gameState.ghost.isFrozen ? .cyan : SKColor(red: 0.88, green: 0.07, blue: 0.12, alpha: 1.0)
        ghostNode.setScale(gameState.ghost.state == .enraged ? 1.25 : (isBreakingDoor ? 1.12 : 1.0))
        ghostPressureRing.position = ghostNode.position
        ghostPressureRing.isHidden = gameState.ghost.isFrozen || gameState.phase == .choosingRoom
        ghostPressureRing.setScale(isBreakingDoor ? 1.35 : 1.0)
        ghostPressureRing.alpha = isBreakingDoor ? 0.88 : 0.45
        doorNode.position = mapPosition(gameState.selectedRoom.doorPosition)
        doorNode.fillColor = doorColor()
        doorNode.setScale(isBreakingDoor ? 1.05 : 1.0)
        bedNode.position = mapPosition(gameState.selectedRoom.playerPosition)
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

    private var isBreakingDoor: Bool {
        gameState.ghost.state == .attacking || gameState.ghost.state == .enraged
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
            if gameState.phase == .choosingRoom {
                statusText = "选房阶段：角色入住房间后不可自由移动"
            } else {
                statusText = isBreakingDoor ? "第 \(gameState.wave) 波 · 破门警报！" : "第 \(gameState.wave) 波 · \(phaseName()) · \(max(0, surviveSeconds - gameState.gameTime))s"
            }
        case .won:
            statusText = "胜利：天亮了"
        case .lost:
            statusText = "失败：寝室失守"
        }

        if gameState.phase == .choosingRoom || gameState.gameStatus != .playing {
            addCallout(text: statusText, at: CGPoint(x: size.width / 2, y: boardRect().maxY - 24), tint: SKColor(red: 0.98, green: 0.78, blue: 0.34, alpha: 1.0))
        }

        let ghostIcon = makeLabel(gameState.ghost.isFrozen ? "🧊" : ghostSymbol(), size: 24, color: .white)
        ghostIcon.position = CGPoint(x: ghostNode.position.x, y: ghostNode.position.y + 30)
        addChild(ghostIcon)
        labelNodes.append(ghostIcon)

        let sleepIcon = makeLabel(gameState.player.isSleeping ? "💤" : "🧑‍🎓", size: 20, color: .white)
        sleepIcon.position = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 25)
        addChild(sleepIcon)
        labelNodes.append(sleepIcon)

        let tipOffset: CGFloat = gameState.selectedRoom.id == DormRoom.leftUpper.id || gameState.selectedRoom.id == DormRoom.leftLower.id ? 56 : -56
        addCallout(
            text: doorTipText(),
            at: CGPoint(x: doorNode.position.x + tipOffset, y: doorNode.position.y + 30),
            tint: doorTipColor()
        )
    }

    private func addCallout(text: String, at position: CGPoint, tint: SKColor) {
        let width = min(size.width - 38, max(74, CGFloat(text.count) * 8.4 + 18))
        let bubble = SKShapeNode(rectOf: CGSize(width: width, height: 24), cornerRadius: 8)
        bubble.position = position
        bubble.fillColor = SKColor.black.withAlphaComponent(0.68)
        bubble.strokeColor = tint.withAlphaComponent(0.82)
        bubble.lineWidth = 1.2
        bubble.zPosition = 20
        addChild(bubble)

        let label = makeLabel(text, size: 11, color: tint)
        label.position = CGPoint(x: position.x, y: position.y - 1)
        label.zPosition = 21
        addChild(label)
        labelNodes.append(label)
    }

    private func ghostSymbol() -> String {
        switch gameState.ghost.state {
        case .scouting: return "👁"
        case .approaching: return "👹"
        case .attacking: return "💢"
        case .enraged: return "🔥"
        }
    }

    private func phaseName() -> String {
        if gameState.gameTime < 45 { return "发育期" }
        if gameState.gameTime < 110 { return "守门期" }
        return "反击期"
    }

    private func doorTipText() -> String {
        if gameState.phase == .choosingRoom { return "等待入住" }
        if isBreakingDoor { return "门口交战" }
        if gameState.turrets.isEmpty { return "建造炮台 +" }
        return "火力覆盖中"
    }

    private func doorTipColor() -> SKColor {
        if isBreakingDoor { return SKColor(red: 1.0, green: 0.30, blue: 0.22, alpha: 1.0) }
        if gameState.turrets.isEmpty { return SKColor(red: 0.56, green: 0.95, blue: 1.0, alpha: 1.0) }
        return SKColor(red: 0.56, green: 1.0, blue: 0.62, alpha: 1.0)
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

    private func dormRoomRect(for room: DormRoom) -> CGRect {
        let board = boardRect()
        let roomW = min((board.width - 112) / 2, 128)
        let roomH = min(max(82, board.height * 0.22), 122)
        let leftX = board.midX - 46 - roomW
        let rightX = board.midX + 46
        let lowerY = board.minY + 44
        let upperY = max(lowerY + roomH + 30, board.midY + 10)
        switch room.id {
        case DormRoom.rightLower.id:
            return CGRect(x: rightX, y: lowerY, width: roomW, height: roomH)
        case DormRoom.leftUpper.id:
            return CGRect(x: leftX, y: upperY, width: roomW, height: roomH)
        case DormRoom.rightUpper.id:
            return CGRect(x: rightX, y: upperY, width: roomW, height: roomH)
        default:
            return CGRect(x: leftX, y: lowerY, width: roomW, height: roomH)
        }
    }

    private func mapPosition(_ position: Position) -> CGPoint {
        let playRect = boardRect().insetBy(dx: 28, dy: 26)
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
        case .speedUp: return .systemBlue
        case .goldBoost: return .systemYellow
        case .doorRepair: return .systemGreen
        case .freezeGhost: return .cyan
        case .invincible: return .systemPurple
        case .barrier: return .systemOrange
        case .slowTrap: return .magenta
        }
    }

    private func symbol(for type: Item.ItemType) -> String {
        switch type {
        case .speedUp: return "↟"
        case .goldBoost: return "$"
        case .doorRepair: return "+"
        case .freezeGhost: return "*"
        case .invincible: return "◇"
        case .barrier: return "▣"
        case .slowTrap: return "~"
        }
    }
}
