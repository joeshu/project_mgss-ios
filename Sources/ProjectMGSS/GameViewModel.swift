import Foundation
import Combine
import SpriteKit

@MainActor
class GameViewModel: ObservableObject {
    @Published var player: Player
    @Published var ghost: Ghost
    @Published var turrets: [Turret]
    @Published var items: [Item]
    @Published var gameTime: Int
    @Published var gameStatus: GameStatus
    @Published var playerGold: Int
    @Published var doorHealth: Float
    @Published var doorMaxHealth: Float

    let gameScene: GameScene

    init() {
        self.player = Player()
        self.ghost = Ghost()
        self.turrets = []
        self.items = []
        self.gameTime = 0
        self.gameStatus = .playing
        self.playerGold = 0
        self.doorHealth = 1000.0
        self.doorMaxHealth = 1000.0

        let initialState = GameState(
            player: self.player,
            ghost: self.ghost,
            turrets: self.turrets,
            items: self.items,
            gameTime: self.gameTime,
            gameStatus: self.gameStatus
        )
        self.gameScene = GameScene(gameState: initialState)
    }

    func startGame() {
        player = Player()
        ghost = Ghost()
        turrets = []
        items = []
        gameTime = 0
        gameStatus = .playing
        playerGold = 0
        doorHealth = 1000.0
        doorMaxHealth = 1000.0
        updateGameState()
    }

    func toggleSleep() {
        player.isSleeping.toggle()
        updateGameState()
    }

    func exitGame() {
        startGame()
    }

    func addTurret(at position: Position) {
        let turret = Turret(position: position)
        turrets.append(turret)
        updateGameState()
    }

    func repairDoor() {
        let repairAmount: Float = 500.0
        doorHealth = min(doorMaxHealth, doorHealth + repairAmount)
        player.doorHealth = doorHealth
        updateGameState()
    }

    func updateGameState() {
        player.gold = playerGold
        player.doorHealth = doorHealth
        player.doorMaxHealth = doorMaxHealth
        ghost.health = max(ghost.health, 0)

        gameScene.gameState = GameState(
            player: player,
            ghost: ghost,
            turrets: turrets,
            items: items,
            gameTime: gameTime,
            gameStatus: gameStatus
        )
    }
}
