import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            // 游戏场景
            SpriteView(scene: gameViewModel.gameScene)
                .ignoresSafeArea()
            
            // UI 层
            VStack {
                // 顶部状态栏
                HStack {
                    VStack(alignment: .leading) {
                        Text("猛鬼宿舍")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        HStack {
                            Text("金币: \(gameViewModel.playerGold)")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            Text("房门: \(Int(gameViewModel.doorHealth))/\(Int(gameViewModel.doorMaxHealth))")
                                .font(.caption)
                                .foregroundColor(.red)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("游戏时间: \(gameViewModel.gameTime)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        if gameViewModel.ghost.isFrozen {
                            Text("猛鬼被冻结!")
                                .font(.caption)
                                .foregroundColor(.cyan)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                
                Spacer()
                
                // 底部控制栏
                VStack {
                    HStack(spacing: 20) {
                        // 睡觉按钮
                        Button(action: {
                            gameViewModel.toggleSleep()
                        }) {
                            VStack {
                                Image(systemName: gameViewModel.player.isSleeping ? "moon.fill" : "moon")
                                Text(gameViewModel.player.isSleeping ? "醒来" : "睡觉")
                                    .font(.caption)
                            }
                            .padding()
                            .background(gameViewModel.player.isSleeping ? Color.yellow : Color.gray)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                        
                        // 商店按钮
                        NavigationLink(destination: ShopView(viewModel: gameViewModel)) {
                            VStack {
                                Image(systemName: "cart.fill")
                                Text("商店")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // 道具按钮
                        NavigationLink(destination: ItemsView(viewModel: gameViewModel)) {
                            VStack {
                                Image(systemName: "gift.fill")
                                Text("道具")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // 退出按钮
                        Button(action: {
                            gameViewModel.exitGame()
                        }) {
                            VStack {
                                Image(systemName: "arrow.left.square.fill")
                                Text("退出")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            gameViewModel.startGame()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
