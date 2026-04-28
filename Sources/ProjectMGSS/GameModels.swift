import Foundation
import SpriteKit

// MARK: - 游戏状态
struct GameState: Codable {
    var player: Player
    var ghost: Ghost
    var turrets: [Turret]
    var items: [Item]
    var gameTime: Int
    var gameStatus: GameStatus
}

enum GameStatus: String, Codable {
    case playing = "playing"
    case won = "won"
    case lost = "lost"
}

// MARK: - 玩家
struct Player: Codable {
    var position: Position
    var isSleeping: Bool
    var gold: Int
    var electricity: Int
    var doorHealth: Float
    var doorMaxHealth: Float
    var isDoorBroken: Bool
    var speed: Float
    var bedLevel: Int
    var doorLevel: Int
    var activeEffects: [ActiveEffect]

    init() {
        self.position = Position(x: 3.0, y: 1.0)
        self.isSleeping = false
        self.gold = 60
        self.electricity = 0
        self.doorHealth = 900.0
        self.doorMaxHealth = 900.0
        self.isDoorBroken = false
        self.speed = 3.0
        self.bedLevel = 1
        self.doorLevel = 1
        self.activeEffects = []
    }
}

// MARK: - 猛鬼
struct Ghost: Codable {
    var position: Position
    var state: GhostState
    var health: Float
    var maxHealth: Float
    var speed: Float
    var attackPower: Float
    var isFrozen: Bool
    var frozenUntil: Date

    enum GhostState: String, Codable {
        case attacking = "ATTACKING"
        case chasing = "CHASING"
    }

    init() {
        self.position = Position(x: 3.0, y: 5.4)
        self.state = .chasing
        self.health = 1400.0
        self.maxHealth = 1400.0
        self.speed = 3.4
        self.attackPower = 42.0
        self.isFrozen = false
        self.frozenUntil = Date()
    }
}

// MARK: - 防御塔
struct Turret: Codable, Identifiable {
    var id: String
    var position: Position
    var level: Int
    var range: Float
    var damage: Float
    var lastShot: Date
    var cooldown: TimeInterval

    init(position: Position, level: Int = 1, range: Float = 4.0, damage: Float = 45.0) {
        self.id = UUID().uuidString
        self.position = position
        self.level = level
        self.range = range
        self.damage = damage
        self.lastShot = Date.distantPast
        self.cooldown = 1.0
    }
}

// MARK: - 道具
struct Item: Codable, Identifiable {
    var id: String
    var type: ItemType
    var position: Position
    var duration: Int
    var expiresAt: Date

    enum ItemType: String, Codable, CaseIterable {
        case speedUp = "SPEED_UP"
        case goldBoost = "GOLD_BOOST"
        case doorRepair = "DOOR_REPAIR"
        case freezeGhost = "FREEZE_GHOST"
        case invincible = "INVINCIBLE"
        case barrier = "BARRIER"
        case slowTrap = "SLOW_TRAP"
    }
}

// MARK: - 活跃效果
struct ActiveEffect: Codable, Identifiable {
    var id: String
    var type: Item.ItemType
    var expiresAt: Date

    init(type: Item.ItemType, expiresAt: Date) {
        self.id = UUID().uuidString
        self.type = type
        self.expiresAt = expiresAt
    }
}

// MARK: - 位置
struct Position: Codable {
    var x: Float
    var y: Float

    func distance(to other: Position) -> Float {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
