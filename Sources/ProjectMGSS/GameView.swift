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
                        if gameViewModel.phase == .choosingRoom {
                            roomChoiceDeck(compact: metrics.isCompactPhone)
                        } else {
                            bottomCommandDeck(compact: metrics.isCompactPhone)
                        }
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
                    Text(gameViewModel.phase == .choosingRoom ? "选房准备" : "距天亮 \(max(0, 180 - gameViewModel.gameTime))s")
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
                    resourceChip(icon: "⏱", title: "天亮", value: "\(max(0, 180 - gameViewModel.gameTime))s", tint: .yellow)
                    resourceChip(icon: "🚪", title: "门", value: "Lv.\(gameViewModel.player.doorLevel)", tint: .orange)
                    resourceChip(icon: "🛡️", title: "炮台", value: "\(gameViewModel.turrets.count)", tint: .blue)
                }
            } else {
                HStack(spacing: 8) {
                    resourceChip(icon: "🪙", title: "金币", value: "\(gameViewModel.playerGold)", tint: .yellow)
                    resourceChip(icon: "⚡", title: "电力", value: "\(gameViewModel.playerElectricity)", tint: .cyan)
                    resourceChip(icon: "⏱", title: "天亮", value: "\(max(0, 180 - gameViewModel.gameTime))s", tint: .yellow)
                    resourceChip(icon: "🚪", title: "门", value: "Lv.\(gameViewModel.player.doorLevel)", tint: .orange)
                    resourceChip(icon: "🛡️", title: "炮台", value: "\(gameViewModel.turrets.count)", tint: .blue)
                }
            }

            VStack(alignment: .leading, spacing: compact ? 4 : 5) {
                meter(title: "房门耐久", value: gameViewModel.doorHealth, total: max(gameViewModel.doorMaxHealth, 1), tint: doorMeterTint)
                meter(title: "敌人血量", value: gameViewModel.ghost.health, total: max(gameViewModel.ghost.maxHealth, 1), tint: .red)
            }
        }
        .padding(compact ? 10 : 12)
        .background(.black.opacity(0.62))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(phaseTint.opacity(0.78), lineWidth: 1.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: phaseTint.opacity(0.30), radius: 14)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("游戏状态，金币 \(gameViewModel.playerGold)，电力 \(gameViewModel.playerElectricity)，门耐久 \(Int(gameViewModel.doorHealth))")
    }

    private func urgentCoachStrip(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: coachIcon).font(.caption.bold())
            Text("当前推荐")
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .foregroundColor(.black)
                .background(coachTint)
                .clipShape(Capsule())
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
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(coachTint.opacity(0.70), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func roomChoiceDeck(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("选一个房间入住")
                        .font(compact ? .caption.bold() : .headline.bold())
                    Text("入住后角色固定在床边，不自由走动；靠升级门、床、炮台守到天亮。")
                        .font(.caption2)
                        .opacity(0.76)
                        .lineLimit(2)
                }
                Spacer()
            }
            .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(gameViewModel.availableRooms) { room in
                    Button(action: { gameViewModel.chooseRoom(room) }) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(room.name).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.75)
                                Spacer()
                                Text("风险 \(room.risk)").font(.caption2.bold()).foregroundColor(room.id == gameViewModel.selectedRoom.id ? .black : .yellow)
                            }
                            Text("收益 +\(room.rewardBonus)/秒 · 门 \(Int(room.doorBonus))")
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .frame(maxWidth: .infinity, minHeight: compact ? 50 : 58)
                        .padding(8)
                        .foregroundColor(room.id == gameViewModel.selectedRoom.id ? .black : .white)
                        .background(room.id == gameViewModel.selectedRoom.id ? Color.yellow : Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: { gameViewModel.beginNightDefense() }) {
                commandButtonContent(title: "入住并开始夜晚", subtitle: "角色固定 · 开始睡觉发育", systemImage: "moon.stars.fill", compact: compact)
            }
            .buttonStyle(CommandButtonStyle(tint: .green, compact: compact))
        }
        .padding(compact ? 10 : 12)
        .background(.black.opacity(0.68))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.yellow.opacity(0.50), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bottomCommandDeck(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            HStack(spacing: compact ? 8 : 10) {
                Button(action: { gameViewModel.toggleSleep() }) {
                    commandButtonContent(
                        title: gameViewModel.player.isSleeping ? "醒来布防" : "立即睡觉",
                        subtitle: gameViewModel.player.isSleeping ? sleepButtonSubtitle : "角色不移动，只切换状态",
                        systemImage: gameViewModel.player.isSleeping ? "figure.stand" : "bed.double.fill",
                        compact: compact
                    )
                }
                .buttonStyle(CommandButtonStyle(tint: (recommendedCommand == .wake || recommendedCommand == .sleep) ? coachTint : (gameViewModel.player.isSleeping ? .yellow : .green), compact: compact, emphasized: recommendedCommand == .wake || recommendedCommand == .sleep))

                Button(action: { isShopPresented = true }) {
                    commandButtonContent(title: recommendedCommand == .shop ? "推荐：宿舍商店" : "宿舍商店", subtitle: recommendedShopAction, systemImage: "cart.fill", compact: compact)
                }
                .buttonStyle(CommandButtonStyle(tint: recommendedCommand == .shop ? coachTint : .blue, compact: compact, emphasized: recommendedCommand == .shop))
            }

            HStack(spacing: compact ? 8 : 10) {
                Button(action: { isRulesPresented = true }) {
                    commandButtonContent(title: "道具策略", subtitle: compact ? "道具/规则" : "冻结 / 屏障 / 修门", systemImage: "sparkles", compact: compact)
                }
                .buttonStyle(CommandButtonStyle(tint: recommendedCommand == .items ? coachTint : .purple, compact: compact, emphasized: recommendedCommand == .items))

                Button(action: { gameViewModel.repairDoor() }) {
                    commandButtonContent(title: recommendedCommand == .repair ? "推荐：修门" : "一键修门", subtitle: repairButtonSubtitle, systemImage: "hammer.fill", compact: compact)
                }
                .buttonStyle(CommandButtonStyle(tint: recommendedCommand == .repair ? coachTint : .orange, compact: compact, emphasized: recommendedCommand == .repair))
                .disabled(gameViewModel.playerGold < 90 || gameViewModel.doorHealth >= gameViewModel.doorMaxHealth)
                .opacity(gameViewModel.playerGold < 90 || gameViewModel.doorHealth >= gameViewModel.doorMaxHealth ? 0.55 : 1)
            }
        }
        .padding(compact ? 10 : 12)
        .background(.black.opacity(0.64))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var phaseTitle: String {
        if gameViewModel.phase == .choosingRoom { return "选房" }
        if gameViewModel.gameTime < 45 { return "发育期" }
        if gameViewModel.gameTime < 110 { return "守门期" }
        return "反击期"
    }

    private var phaseValue: String {
        if gameViewModel.phase == .choosingRoom { return "先定房间" }
        if gameViewModel.gameTime < 45 { return "睡觉攒钱" }
        if gameViewModel.gameTime < 110 { return "升级门" }
        return "炮台输出"
    }

    private var phaseSubtitle: String {
        if gameViewModel.phase == .choosingRoom { return "选房后人物固定，进入宿舍防守循环" }
        if gameViewModel.player.isSleeping { return "睡觉发育中 · 金币和电力持续增长" }
        if isBreakingDoor { return "敌人破门中 · 先修门再补炮台" }
        return "布防窗口 · 按节奏升级床、门、炮台"
    }

    private var phaseTint: Color {
        if gameViewModel.phase == .choosingRoom { return .yellow }
        if gameViewModel.gameTime < 45 { return .green }
        if gameViewModel.gameTime < 110 { return .orange }
        return .red
    }

    private var isBreakingDoor: Bool {
        gameViewModel.ghost.state == .attacking || gameViewModel.ghost.state == .enraged
    }

    private var threatLabel: String {
        if gameViewModel.phase == .choosingRoom { return "威胁：未入夜" }
        if gameViewModel.ghost.isFrozen { return "威胁：冻结" }
        switch gameViewModel.ghost.state {
        case .scouting: return "威胁：巡查走廊"
        case .approaching: return "威胁：逼近房门"
        case .attacking: return "威胁：正在破门"
        case .enraged: return "威胁：狂暴破门"
        }
    }

    private var threatColor: Color {
        if gameViewModel.phase == .choosingRoom { return .yellow }
        if gameViewModel.ghost.isFrozen { return .cyan }
        return isBreakingDoor ? .red : .orange
    }

    private var doorMeterTint: Color {
        let ratio = gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1)
        if ratio < 0.25 { return .red }
        if ratio < 0.55 { return .orange }
        return .green
    }

    private var coachTint: Color {
        if gameViewModel.phase == .choosingRoom { return .yellow }
        if isBreakingDoor || gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1) < 0.30 { return .red }
        if gameViewModel.playerGold >= 120 * (gameViewModel.player.bedLevel + 1) && gameViewModel.player.bedLevel < 5 { return .green }
        return phaseTint
    }

    private var coachIcon: String {
        if gameViewModel.phase == .choosingRoom { return "house.fill" }
        if isBreakingDoor { return "exclamationmark.triangle.fill" }
        if gameViewModel.player.isSleeping { return "moon.zzz.fill" }
        return "lightbulb.fill"
    }

    private var coachText: String {
        if gameViewModel.phase == .choosingRoom {
            return "先选房：低风险房更稳，高收益房更刺激。人物不会自由移动，主要操作是睡觉、升级、修门和布炮台。"
        }
        let doorRatio = gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1)
        if isBreakingDoor && doorRatio < 0.45 { return "门耐久偏低：先修门或升门，商店/修门不会重新开局。" }
        if isBreakingDoor { return "敌人正在破门：优先醒来布防，补炮台或升门。" }
        if gameViewModel.turrets.isEmpty && gameViewModel.gameTime > 30 { return "门前缺少炮台：现在先补一座炮台，比继续升床更安全。" }
        if gameViewModel.player.bedLevel < 3 && gameViewModel.playerGold >= 120 * (gameViewModel.player.bedLevel + 1) { return "安全发育：金币够了，优先升级床提高持续收益。" }
        if !gameViewModel.player.isSleeping { return "当前安全：可以立即睡觉继续发育。" }
        return "目标：守住房门到天亮，或用炮台提前击退敌人。"
    }

    private enum RecommendedCommand {
        case wake, shop, items, repair, sleep, none
    }

    private var recommendedCommand: RecommendedCommand {
        guard gameViewModel.phase != .choosingRoom else { return .none }
        let doorRatio = gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1)
        if isBreakingDoor && doorRatio < 0.45 && gameViewModel.playerGold >= 90 { return .repair }
        if isBreakingDoor && gameViewModel.player.isSleeping { return .wake }
        if gameViewModel.turrets.isEmpty && gameViewModel.gameTime > 30 { return .shop }
        if gameViewModel.player.bedLevel < 3 && gameViewModel.playerGold >= 120 * (gameViewModel.player.bedLevel + 1) { return .shop }
        if !gameViewModel.player.isSleeping && !isBreakingDoor { return .sleep }
        return .none
    }

    private var sleepButtonSubtitle: String {
        if isBreakingDoor { return "危险，立即操作" }
        if gameViewModel.turrets.isEmpty && gameViewModel.gameTime > 30 { return "先补炮台更稳" }
        return "安全时继续睡"
    }

    private var repairButtonSubtitle: String {
        if gameViewModel.doorHealth >= gameViewModel.doorMaxHealth { return "门耐久已满" }
        if gameViewModel.playerGold < 90 { return "金币不足，需要90" }
        return "消耗90金币"
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
            ProgressView(value: Double(value), total: Double(total)).tint(tint)
        }
    }

    private func commandButtonContent(title: String, subtitle: String, systemImage: String, compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Image(systemName: systemImage).font(compact ? .subheadline : .headline).frame(width: compact ? 18 : 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(compact ? .caption.bold() : .subheadline.bold()).lineLimit(1).minimumScaleFactor(0.78)
                Text(subtitle).font(.caption2).lineLimit(1).minimumScaleFactor(0.72).opacity(0.82)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 44 : 52)
        .contentShape(Rectangle())
    }

    private var resultOverlay: some View {
        VStack(spacing: 16) {
            Text(gameViewModel.gameStatus == .won ? "天亮了，守住了！" : "房门被破，宿舍失守")
                .font(.title2.bold())
            Text(gameViewModel.gameStatus == .won ? "本局选择了 \(gameViewModel.selectedRoom.name)，坚持 \(gameViewModel.gameTime) 秒，第 \(gameViewModel.wave) 波。" : "复盘：低风险房更稳；先升床发育，再保门和补炮台。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("重新选房开局") { gameViewModel.startGame() }
                .buttonStyle(.borderedProminent)
        }
        .foregroundColor(.white)
        .padding(24)
        .background(.black.opacity(0.82))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.yellow.opacity(0.7), lineWidth: 1.5))
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
    var emphasized: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(compact ? 8 : 10)
            .background(
                LinearGradient(
                    colors: [tint.opacity(configuration.isPressed ? 0.56 : (emphasized ? 0.90 : 0.62)), tint.opacity(emphasized ? 0.42 : 0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(emphasized ? tint.opacity(0.95) : .white.opacity(0.16), lineWidth: emphasized ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: emphasized ? tint.opacity(0.35) : .clear, radius: emphasized ? 10 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    GameView()
}
