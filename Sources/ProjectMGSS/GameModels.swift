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
    var doorHealth: Float
    var doorMaxHealth: Float
    var isDoorBroken: Bool
    var speed: Float
    var activeEffects: [ActiveEffect]
    
    init() {
        self.position = Position(x: 3.0, y: 3.0)
        self.isSleeping = false
        self.gold = 0
        self.doorHealth = 1000.0
        self.doorMaxHealth = 1000.0
        self.isDoorBroken = false
        self.speed = 3.0
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
        self.position = Position(x: 0.0, y: 0.0)
        self.state = .attacking
        self.health = 1000.0
        self.maxHealth = 1000.0
        self.speed = 4.0
        self.attackPower = 100.0
        self.isFrozen = false
        self.frozenUntil = Date()
    }
}

// MARK: - 防御塔
struct Turret: Codable {
    var position: Position
    var range: Float
    var damage: Float
    var lastShot: Date
    var cooldown: TimeInterval
    
    init(position: Position, range: Float = 5.0, damage: Float = 50.0) {
        self.position = position
        self.range = range
        self.damage = damage
        self.lastShot = Date.distantPast
        self.cooldown = 1.0
    }
}

// MARK: - 道具
struct Item: Codable {
    var id: String
    var type: ItemType
    var position: Position
    var duration: Int
    var expiresAt: Date
    
    enum ItemType: String, Codable {
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
struct ActiveEffect: Codable {
    var type: Item.ItemType
    var expiresAt: Date
}

// MARK: - 位置
struct Position: Codable {
    var x: Float
    var y: Float
}
