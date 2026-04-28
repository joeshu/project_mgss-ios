import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var isShopPresented = false
    @State private var isRulesPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.04, blue: 0.12), Color(red: 0.10, green: 0.06, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                SpriteView(scene: gameViewModel.gameScene, options: [.allowsTransparency])
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    topHud
                    Spacer(minLength: 0)
                    bottomCommandDeck
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .center) {
                if gameViewModel.gameStatus != .playing {
                    resultOverlay
                }
            }
            .sheet(isPresented: $isShopPresented) {
                ShopView(viewModel: gameViewModel)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isRulesPresented) {
                ItemsView(viewModel: gameViewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var topHud: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("夜半宿舍防线")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Text(gameViewModel.player.isSleeping ? "学生睡觉发育中 · 收益加速" : "醒着布防 · 可升级设施")
                        .font(.caption2)
                        .foregroundColor(gameViewModel.player.isSleeping ? .green : .orange)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("距天亮 \(max(0, 180 - gameViewModel.gameTime))s")
                        .font(.subheadline.bold())
                        .foregroundColor(.yellow)
                    Text(threatLabel)
                        .font(.caption2.bold())
                        .foregroundColor(threatColor)
                }
            }

            HStack(spacing: 8) {
                resourceChip(icon: "🪙", title: "金币", value: "\(gameViewModel.playerGold)", tint: .yellow)
                resourceChip(icon: "⚡", title: "电力", value: "\(gameViewModel.playerElectricity)", tint: .cyan)
                resourceChip(icon: "🛏️", title: "床", value: "Lv.\(gameViewModel.player.bedLevel)", tint: .green)
                resourceChip(icon: "🚪", title: "门", value: "Lv.\(gameViewModel.player.doorLevel)", tint: .orange)
            }

            VStack(alignment: .leading, spacing: 5) {
                meter(title: "房门耐久", value: gameViewModel.doorHealth, total: max(gameViewModel.doorMaxHealth, 1), tint: .orange)
                meter(title: "猛鬼血量", value: gameViewModel.ghost.health, total: max(gameViewModel.ghost.maxHealth, 1), tint: .red)
            }
        }
        .padding(12)
        .background(.black.opacity(0.54))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.purple.opacity(0.65), lineWidth: 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .purple.opacity(0.35), radius: 14)
    }

    private var bottomCommandDeck: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: { gameViewModel.toggleSleep() }) {
                    commandButtonContent(
                        title: gameViewModel.player.isSleeping ? "醒来操作" : "上床睡觉",
                        subtitle: gameViewModel.player.isSleeping ? "暂停收益，立刻布防" : "+金币 / +电力",
                        systemImage: gameViewModel.player.isSleeping ? "figure.walk" : "bed.double.fill"
                    )
                }
                .buttonStyle(CommandButtonStyle(tint: gameViewModel.player.isSleeping ? .yellow : .green))

                Button(action: { isShopPresented = true }) {
                    commandButtonContent(title: "打开商店", subtitle: "买完继续守门", systemImage: "cart.fill")
                }
                .buttonStyle(CommandButtonStyle(tint: .blue))
            }

            HStack(spacing: 10) {
                Button(action: { isRulesPresented = true }) {
                    commandButtonContent(title: "道具规则", subtitle: "冻结 / 屏障 / 修门", systemImage: "sparkles")
                }
                .buttonStyle(CommandButtonStyle(tint: .purple))

                Button(action: { gameViewModel.repairDoor() }) {
                    commandButtonContent(title: "快速修门", subtitle: "90 金币", systemImage: "hammer.fill")
                }
                .buttonStyle(CommandButtonStyle(tint: .orange))
                .disabled(gameViewModel.playerGold < 90 || gameViewModel.doorHealth >= gameViewModel.doorMaxHealth)
                .opacity(gameViewModel.playerGold < 90 || gameViewModel.doorHealth >= gameViewModel.doorMaxHealth ? 0.55 : 1)
            }
        }
        .padding(12)
        .background(.black.opacity(0.56))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var threatLabel: String {
        if gameViewModel.ghost.isFrozen { return "威胁：冻结" }
        switch gameViewModel.ghost.state {
        case .attacking:
            return "威胁：破门中"
        case .chasing:
            return gameViewModel.gameTime > 120 ? "威胁：狂暴接近" : "威胁：巡游接近"
        }
    }

    private var threatColor: Color {
        if gameViewModel.ghost.isFrozen { return .cyan }
        return gameViewModel.ghost.state == .attacking ? .red : .orange
    }

    private func resourceChip(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.caption)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(tint)
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func meter(title: String, value: Float, total: Float, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))/\(Int(total))")
            }
            .font(.caption2)
            .foregroundColor(.white.opacity(0.88))
            ProgressView(value: Double(value), total: Double(total))
                .tint(tint)
        }
    }

    private func commandButtonContent(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption2)
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    private var resultOverlay: some View {
        VStack(spacing: 16) {
            Text(gameViewModel.gameStatus == .won ? "天亮了，守住了！" : "猛鬼破门，宿舍失守")
                .font(.title2.bold())
            Text(gameViewModel.gameStatus == .won ? "继续提高床、门和炮台等级，可以挑战更高难度。" : "宿舍防守策略：先睡觉攒金币，再升级门和床，最后补炮台反击。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("重新开局") {
                gameViewModel.startGame()
            }
            .buttonStyle(.borderedProminent)
        }
        .foregroundColor(.white)
        .padding(24)
        .background(.black.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.yellow.opacity(0.7), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding()
    }
}

private struct CommandButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(10)
            .background(
                LinearGradient(
                    colors: [tint.opacity(configuration.isPressed ? 0.50 : 0.72), tint.opacity(0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    GameView()
}
