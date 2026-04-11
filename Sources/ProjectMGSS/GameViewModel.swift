import Foundation
import Combine

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
    
    var gameScene: GameScene?
    
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
    }
    
    func startGame() {
        // 初始化游戏状态
        player = Player()
        ghost = Ghost()
        turrets = []
        items = []
        gameTime = 0
        gameStatus = .playing
        playerGold = 0
        doorHealth = 1000.0
        
        // 创建游戏场景
        let gameState = GameState(
            player: player,
            ghost: ghost,
            turrets: turrets,
            items: items,
            gameTime: gameTime,
            gameStatus: gameStatus
        )
        
        gameScene = GameScene(gameState: gameState)
    }
    
    func toggleSleep() {
        player.isSleeping.toggle()
    }
    
    func exitGame() {
        gameScene = nil
    }
    
    func addTurret(at position: Position) {
        let turret = Turret(position: position)
        turrets.append(turret)
        updateGameState()
    }
    
    func repairDoor() {
        let repairAmount = 500.0
        doorHealth = min(doorMaxHealth, doorHealth + repairAmount)
        updateGameState()
    }
    
    func updateGameState() {
        if let scene = gameScene {
            scene.gameState = GameState(
                player: player,
                ghost: ghost,
                turrets: turrets,
                items: items,
                gameTime: gameTime,
                gameStatus: gameStatus
            )
        }
    }
}

// MARK: - SceneDelegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIHostingController(rootView: GameView())
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
