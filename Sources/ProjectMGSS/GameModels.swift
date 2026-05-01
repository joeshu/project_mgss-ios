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
    var phase: GamePhase
    var selectedRoom: DormRoom
    var wave: Int
}

enum GameStatus: String, Codable {
    case playing = "playing"
    case won = "won"
    case lost = "lost"
}

enum GamePhase: String, Codable {
    case choosingRoom = "CHOOSING_ROOM"
    case nightDefense = "NIGHT_DEFENSE"
}

enum DefensePressurePhase: String, Codable, CaseIterable {
    case early = "EARLY"
    case mid = "MID"
    case highPressure = "HIGH_PRESSURE"
    case frenzy = "FRENZY"

    var title: String {
        switch self {
        case .early: return "前期试探"
        case .mid: return "中期压迫"
        case .highPressure: return "高压破门"
        case .frenzy: return "狂暴终局"
        }
    }

    static func phase(for gameTime: Int) -> DefensePressurePhase {
        if gameTime < 45 { return .early }
        if gameTime < 95 { return .mid }
        if gameTime < 145 { return .highPressure }
        return .frenzy
    }
}

// MARK: - 房间选择
struct DormRoom: Codable, Identifiable, Equatable, CaseIterable {
    var id: String
    var name: String
    var risk: Int
    var rewardBonus: Int
    var doorBonus: Float
    var playerPosition: Position
    var doorPosition: Position
    var turretSlots: [Position]

    static let leftLower = DormRoom(
        id: "left-lower",
        name: "左下安静房",
        risk: 1,
        rewardBonus: 0,
        doorBonus: 180,
        playerPosition: Position(x: 1.55, y: 1.15),
        doorPosition: Position(x: 2.65, y: 2.42),
        turretSlots: [Position(x: 2.0, y: 2.82), Position(x: 1.25, y: 2.48), Position(x: 2.65, y: 3.08)]
    )

    static let rightLower = DormRoom(
        id: "right-lower",
        name: "右下发育房",
        risk: 2,
        rewardBonus: 4,
        doorBonus: 80,
        playerPosition: Position(x: 4.45, y: 1.15),
        doorPosition: Position(x: 3.35, y: 2.42),
        turretSlots: [Position(x: 4.0, y: 2.82), Position(x: 4.75, y: 2.48), Position(x: 3.35, y: 3.08)]
    )

    static let leftUpper = DormRoom(
        id: "left-upper",
        name: "左上近门房",
        risk: 3,
        rewardBonus: 7,
        doorBonus: 0,
        playerPosition: Position(x: 1.55, y: 3.92),
        doorPosition: Position(x: 2.65, y: 3.36),
        turretSlots: [Position(x: 2.0, y: 3.08), Position(x: 1.25, y: 3.42), Position(x: 2.65, y: 2.88)]
    )

    static let rightUpper = DormRoom(
        id: "right-upper",
        name: "右上高收益房",
        risk: 4,
        rewardBonus: 10,
        doorBonus: -80,
        playerPosition: Position(x: 4.45, y: 3.92),
        doorPosition: Position(x: 3.35, y: 3.36),
        turretSlots: [Position(x: 4.0, y: 3.08), Position(x: 4.75, y: 3.42), Position(x: 3.35, y: 2.88)]
    )

    static let allCases: [DormRoom] = [.leftLower, .rightLower, .leftUpper, .rightUpper]
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

    init(room: DormRoom = .rightLower) {
        self.position = room.playerPosition
        self.isSleeping = false
        self.gold = 70
        self.electricity = 0
        self.doorMaxHealth = max(700.0, 900.0 + room.doorBonus)
        self.doorHealth = self.doorMaxHealth
        self.isDoorBroken = false
        self.speed = 0.0
        self.bedLevel = 1
        self.doorLevel = 1
        self.activeEffects = []
    }
}

// MARK: - 敌人
enum MonsterType: String, Codable, CaseIterable {
    case normal = "NORMAL"
    case fast = "FAST"
    case armored = "ARMORED"

    var displayName: String {
        switch self {
        case .normal: return "巡夜影"
        case .fast: return "疾行影"
        case .armored: return "重甲影"
        }
    }

    var hpMultiplier: Float {
        switch self {
        case .normal: return 1.0
        case .fast: return 0.72
        case .armored: return 1.55
        }
    }

    var speedMultiplier: Float {
        switch self {
        case .normal: return 1.0
        case .fast: return 1.45
        case .armored: return 0.78
        }
    }

    var attackMultiplier: Float {
        switch self {
        case .normal: return 1.0
        case .fast: return 0.82
        case .armored: return 1.22
        }
    }
}

struct Ghost: Codable {
    var monsterType: MonsterType
    var position: Position
    var state: GhostState
    var health: Float
    var maxHealth: Float
    var speed: Float
    var attackPower: Float
    var isFrozen: Bool
    var frozenUntil: Date

    enum GhostState: String, Codable {
        case scouting = "SCOUTING"
        case approaching = "APPROACHING"
        case attacking = "ATTACKING"
        case enraged = "ENRAGED"
    }

    init(type: MonsterType = .normal, pressurePhase: DefensePressurePhase = .early, wave: Int = 1, roomRisk: Int = 1) {
        self.monsterType = type
        self.position = Position(x: 3.0, y: 5.7)
        self.state = .scouting
        let phaseHp: Float
        let phaseSpeed: Float
        let phaseAttack: Float
        switch pressurePhase {
        case .early:
            phaseHp = 0
            phaseSpeed = 0
            phaseAttack = 0
        case .mid:
            phaseHp = 260
            phaseSpeed = 0.16
            phaseAttack = 10
        case .highPressure:
            phaseHp = 620
            phaseSpeed = 0.30
            phaseAttack = 23
        case .frenzy:
            phaseHp = 1050
            phaseSpeed = 0.48
            phaseAttack = 38
        }
        let baseHealth = 1180.0 + Float(wave * 85) + Float(roomRisk * 55) + phaseHp
        self.maxHealth = baseHealth * type.hpMultiplier
        self.health = self.maxHealth
        self.speed = (2.95 + Float(wave) * 0.05 + phaseSpeed) * type.speedMultiplier
        self.attackPower = (34.0 + Float(wave * 4) + Float(roomRisk * 3) + phaseAttack) * type.attackMultiplier
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
struct Position: Codable, Equatable {
    var x: Float
    var y: Float

    func distance(to other: Position) -> Float {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
