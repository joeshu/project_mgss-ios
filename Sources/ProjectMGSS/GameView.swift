import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var isShopPresented = false
    @State private var isRulesPresented = false

    var body: some View {
        GeometryReader { geometry in
            let metrics = PhoneMetrics(size: geometry.size, safeArea: geometry.safeAreaInsets)

            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.03, green: 0.03, blue: 0.09), Color(red: 0.10, green: 0.05, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    SpriteView(scene: gameViewModel.gameScene, options: [.allowsTransparency])
                        .ignoresSafeArea()

                    VStack(spacing: metrics.verticalSpacing) {
                        topHud(compact: metrics.isCompactPhone)
                        urgentCoachStrip(compact: metrics.isCompactPhone)
                        Spacer(minLength: metrics.scenePeekHeight)
                        bottomCommandDeck(compact: metrics.isCompactPhone)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, max(8, metrics.safeArea.top + 4))
                    .padding(.bottom, max(8, metrics.safeArea.bottom + 8))
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
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $isRulesPresented) {
                    ItemsView(viewModel: gameViewModel)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .dynamicTypeSize(.xSmall ... .accessibility2)
    }

    private func topHud(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("夜半宿舍防线")
                        .font(compact ? .subheadline.bold() : .headline.bold())
                        .foregroundColor(.white)
                    Text(phaseSubtitle)
                        .font(.caption2)
                        .foregroundColor(phaseTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("距天亮 \(max(0, 180 - gameViewModel.gameTime))s")
                        .font(compact ? .caption.bold() : .subheadline.bold())
                        .foregroundColor(.yellow)
                    Text(threatLabel)
                        .font(.caption2.bold())
                        .foregroundColor(threatColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            if compact {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    phaseChip(title: phaseTitle, value: phaseValue, tint: phaseTint)
                    resourceChip(icon: "🪙", title: "金币", value: "\(gameViewModel.playerGold)", tint: .yellow)
                    resourceChip(icon: "⚡", title: "电力", value: "\(gameViewModel.playerElectricity)", tint: .cyan)
                    resourceChip(icon: "🛏️", title: "床", value: "Lv.\(gameViewModel.player.bedLevel)", tint: .green)
                    resourceChip(icon: "🚪", title: "门", value: "Lv.\(gameViewModel.player.doorLevel)", tint: .orange)
                    resourceChip(icon: "🛡️", title: "炮台", value: "\(gameViewModel.turrets.count)", tint: .blue)
                }
            } else {
                HStack(spacing: 8) {
                    phaseChip(title: phaseTitle, value: phaseValue, tint: phaseTint)
                    resourceChip(icon: "🪙", title: "金币", value: "\(gameViewModel.playerGold)", tint: .yellow)
                    resourceChip(icon: "⚡", title: "电力", value: "\(gameViewModel.playerElectricity)", tint: .cyan)
                    resourceChip(icon: "🛏️", title: "床", value: "Lv.\(gameViewModel.player.bedLevel)", tint: .green)
                    resourceChip(icon: "🚪", title: "门", value: "Lv.\(gameViewModel.player.doorLevel)", tint: .orange)
                }
            }

            VStack(alignment: .leading, spacing: compact ? 4 : 5) {
                meter(title: "房门耐久", value: gameViewModel.doorHealth, total: max(gameViewModel.doorMaxHealth, 1), tint: doorMeterTint)
                meter(title: "猛鬼血量", value: gameViewModel.ghost.health, total: max(gameViewModel.ghost.maxHealth, 1), tint: .red)
            }
        }
        .padding(compact ? 10 : 12)
        .background(.black.opacity(0.62))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(phaseTint.opacity(0.78), lineWidth: 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: phaseTint.opacity(0.30), radius: 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("游戏状态，金币 \(gameViewModel.playerGold)，电力 \(gameViewModel.playerElectricity)，门耐久 \(Int(gameViewModel.doorHealth))")
    }

    private func urgentCoachStrip(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: coachIcon)
                .font(.caption.bold())
            Text(coachText)
                .font(compact ? .caption2.bold() : .caption.bold())
                .lineLimit(compact ? 2 : 3)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding(.horizontal, compact ? 10 : 11)
        .padding(.vertical, compact ? 7 : 8)
        .background(coachTint.opacity(0.30))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(coachTint.opacity(0.70), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func bottomCommandDeck(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            HStack(spacing: compact ? 8 : 10) {
                Button(action: { gameViewModel.toggleSleep() }) {
                    commandButtonContent(
                        title: gameViewModel.player.isSleeping ? "醒来布防" : "立即睡觉",
                        subtitle: gameViewModel.player.isSleeping ? "破门危险时再醒" : "优先发育经济",
                        systemImage: gameViewModel.player.isSleeping ? "figure.walk" : "bed.double.fill",
                        compact: compact
                    )
                }
                .buttonStyle(CommandButtonStyle(tint: gameViewModel.player.isSleeping ? .yellow : .green, compact: compact))

                Button(action: { isShopPresented = true }) {
                    commandButtonContent(title: "宿舍商店", subtitle: recommendedShopAction, systemImage: "cart.fill", compact: compact)
                }
                .buttonStyle(CommandButtonStyle(tint: .blue, compact: compact))
            }

            HStack(spacing: compact ? 8 : 10) {
                Button(action: { isRulesPresented = true }) {
                    commandButtonContent(title: "道具策略", subtitle: compact ? "道具/规则" : "冻结 / 屏障 / 修门", systemImage: "sparkles", compact: compact)
                }
                .buttonStyle(CommandButtonStyle(tint: .purple, compact: compact))

                Button(action: { gameViewModel.repairDoor() }) {
                    commandButtonContent(title: "一键修门", subtitle: compact ? "90 金币" : "90 金币 · 不重开", systemImage: "hammer.fill", compact: compact)
                }
                .buttonStyle(CommandButtonStyle(tint: .orange, compact: compact))
                .disabled(gameViewModel.playerGold < 90 || gameViewModel.doorHealth >= gameViewModel.doorMaxHealth)
                .opacity(gameViewModel.playerGold < 90 || gameViewModel.doorHealth >= gameViewModel.doorMaxHealth ? 0.55 : 1)
            }
        }
        .padding(compact ? 10 : 12)
        .background(.black.opacity(0.64))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var phaseTitle: String {
        if gameViewModel.gameTime < 45 { return "发育期" }
        if gameViewModel.gameTime < 110 { return "守门期" }
        return "反击期"
    }

    private var phaseValue: String {
        if gameViewModel.gameTime < 45 { return "睡觉攒钱" }
        if gameViewModel.gameTime < 110 { return "升级门" }
        return "炮台输出"
    }

    private var phaseSubtitle: String {
        if gameViewModel.player.isSleeping { return "睡觉发育中 · 金币和电力持续增长" }
        if gameViewModel.ghost.state == .attacking { return "猛鬼破门中 · 先修门再补炮台" }
        return "布防窗口 · 按节奏升级床、门、炮台"
    }

    private var phaseTint: Color {
        if gameViewModel.gameTime < 45 { return .green }
        if gameViewModel.gameTime < 110 { return .orange }
        return .red
    }

    private var threatLabel: String {
        if gameViewModel.ghost.isFrozen { return "威胁：冻结" }
        switch gameViewModel.ghost.state {
        case .attacking: return "威胁：正在破门"
        case .chasing: return gameViewModel.gameTime > 120 ? "威胁：狂暴逼近" : "威胁：走廊逼近"
        }
    }

    private var threatColor: Color {
        if gameViewModel.ghost.isFrozen { return .cyan }
        return gameViewModel.ghost.state == .attacking ? .red : .orange
    }

    private var doorMeterTint: Color {
        let ratio = gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1)
        if ratio < 0.25 { return .red }
        if ratio < 0.55 { return .orange }
        return .green
    }

    private var coachTint: Color {
        if gameViewModel.ghost.state == .attacking || gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1) < 0.30 { return .red }
        if gameViewModel.playerGold >= 120 * (gameViewModel.player.bedLevel + 1) && gameViewModel.player.bedLevel < 5 { return .green }
        return phaseTint
    }

    private var coachIcon: String {
        if gameViewModel.ghost.state == .attacking { return "exclamationmark.triangle.fill" }
        if gameViewModel.player.isSleeping { return "moon.zzz.fill" }
        return "lightbulb.fill"
    }

    private var coachText: String {
        let doorRatio = gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1)
        if gameViewModel.ghost.state == .attacking && doorRatio < 0.45 {
            return "门快撑不住了：先点“一键修门”或进商店升级门，买完会回到当前战局。"
        }
        if gameViewModel.player.bedLevel < 3 && gameViewModel.playerGold >= 120 * (gameViewModel.player.bedLevel + 1) {
            return "推荐节奏：先升床，提高睡觉收益，再补门和炮台。"
        }
        if gameViewModel.turrets.isEmpty && gameViewModel.gameTime > 55 {
            return "猛鬼快到门口：至少放一座炮台，形成宿舍门口火力点。"
        }
        if !gameViewModel.player.isSleeping && gameViewModel.ghost.state == .chasing {
            return "安全窗口：可以睡觉发育，听到破门提示再醒来操作。"
        }
        return "目标：守住房门到天亮，或用炮台提前击退猛鬼。"
    }

    private var recommendedShopAction: String {
        if gameViewModel.player.bedLevel < 3 { return "优先升床" }
        if gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1) < 0.55 { return "修门/升门" }
        if gameViewModel.turrets.count < 2 { return "补炮台" }
        return "强化防线"
    }

    private func phaseChip(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2.bold()).foregroundColor(.white)
            Text(value).font(.caption2).foregroundColor(tint).lineLimit(1).minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(tint.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func resourceChip(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.caption)
            Text(value).font(.caption.bold()).foregroundColor(tint).lineLimit(1).minimumScaleFactor(0.70)
            Text(title).font(.caption2).foregroundColor(.white.opacity(0.72))
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

    private func commandButtonContent(title: String, subtitle: String, systemImage: String, compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Image(systemName: systemImage)
                .font(compact ? .subheadline : .headline)
                .frame(width: compact ? 18 : 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(compact ? .caption.bold() : .subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(subtitle)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .opacity(0.82)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 44 : 52)
        .contentShape(Rectangle())
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

private struct PhoneMetrics {
    let size: CGSize
    let safeArea: EdgeInsets

    var isCompactPhone: Bool { size.height < 720 || size.width < 380 }
    var horizontalPadding: CGFloat { isCompactPhone ? 8 : 10 }
    var verticalSpacing: CGFloat { isCompactPhone ? 6 : 8 }
    var scenePeekHeight: CGFloat { isCompactPhone ? 20 : 34 }
}

private struct CommandButtonStyle: ButtonStyle {
    let tint: Color
    let compact: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(compact ? 8 : 10)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    GameView()
}
