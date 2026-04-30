import SwiftUI
import SpriteKit

private enum MGSSUITheme {
    static let nightBase = Color(red: 0.035, green: 0.035, blue: 0.060)
    static let nightPanelTop = Color(red: 0.055, green: 0.052, blue: 0.082)
    static let nightPanelBottom = Color(red: 0.080, green: 0.065, blue: 0.105)
    static let roomPanelTop = Color(red: 0.045, green: 0.045, blue: 0.070)
    static let roomPanelBottom = Color(red: 0.070, green: 0.060, blue: 0.085)
    static let cardFill = Color(red: 0.080, green: 0.075, blue: 0.100)
    static let chipFill = Color(red: 0.110, green: 0.105, blue: 0.130)
    static let selection = Color.yellow
    static let action = Color.green
    static let utility = Color.cyan
    static let warning = Color.orange
    static let danger = Color.red
}

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var isShopPresented = false
    @State private var isRulesPresented = false
    @State private var isTopPanelExpanded = false
    @State private var isBottomPanelExpanded = true

    var body: some View {
        GeometryReader { geometry in
            let metrics = PhoneMetrics(size: geometry.size, safeArea: geometry.safeAreaInsets)
            let shouldUseCollapsedChrome = metrics.needsCollapsedChrome

            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [MGSSUITheme.nightBase, Color(red: 0.10, green: 0.05, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    SpriteView(scene: gameViewModel.gameScene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    topInsetContent(metrics: metrics, collapsedChrome: shouldUseCollapsedChrome)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomInsetContent(metrics: metrics, collapsedChrome: shouldUseCollapsedChrome)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .overlay(alignment: .top) {
                    gameplayOverlay(metrics: metrics, collapsedChrome: shouldUseCollapsedChrome)
                }
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

    @ViewBuilder
    private func topInsetContent(metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        let compact = metrics.isCompactPhone
        if gameViewModel.phase == .choosingRoom {
            adaptiveTopPanel(expanded: isTopPanelExpanded, metrics: metrics, collapsedChrome: collapsedChrome) {
                choosingRoomTopInset(compact: compact, metrics: metrics, collapsedChrome: collapsedChrome)
            }
        } else {
            adaptiveTopPanel(expanded: isTopPanelExpanded, metrics: metrics, collapsedChrome: collapsedChrome) {
                nightDefenseTopInset(compact: compact, metrics: metrics, collapsedChrome: collapsedChrome)
            }
        }
    }

    @ViewBuilder
    private func bottomInsetContent(metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        let compact = metrics.isCompactPhone
        if gameViewModel.phase == .choosingRoom {
            adaptiveBottomPanel(expanded: isBottomPanelExpanded, metrics: metrics, collapsedChrome: collapsedChrome) {
                choosingRoomBottomInset(compact: compact, metrics: metrics, collapsedChrome: collapsedChrome)
            }
        } else {
            adaptiveBottomPanel(expanded: isBottomPanelExpanded, metrics: metrics, collapsedChrome: collapsedChrome) {
                nightDefenseBottomInset(compact: compact, metrics: metrics, collapsedChrome: collapsedChrome)
            }
        }
    }

    @ViewBuilder
    private func gameplayOverlay(metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        if shouldShowCriticalOverlay {
            HStack(spacing: 8) {
                Image(systemName: coachIcon)
                    .font(.caption.bold())
                Text(topSummaryText)
                    .font(metrics.isCompactPhone ? .caption2.bold() : .caption.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(coachTint.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(coachTint.opacity(0.95), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.top, criticalOverlayTopPadding(metrics: metrics, collapsedChrome: collapsedChrome))
            .padding(.horizontal, metrics.horizontalPadding)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func criticalOverlayTopPadding(metrics: PhoneMetrics, collapsedChrome: Bool) -> CGFloat {
        topChromeReservedHeight(metrics: metrics, collapsedChrome: collapsedChrome) + 8
    }

    private func topChromeReservedHeight(metrics: PhoneMetrics, collapsedChrome: Bool) -> CGFloat {
        let handleHeight: CGFloat = collapsedChrome ? 44 : 0
        let panelHeight: CGFloat = collapsedChrome
            ? (isTopPanelExpanded ? expandedTopPanelEstimatedHeight(metrics: metrics) : 0)
            : expandedTopPanelEstimatedHeight(metrics: metrics)
        let topSpacing: CGFloat = collapsedChrome ? max(4, metrics.safeArea.top + 2) : 0
        let contentGap: CGFloat = panelHeight > 0 ? 6 : 0
        return topSpacing + handleHeight + contentGap + panelHeight
    }

    private func expandedTopPanelEstimatedHeight(metrics: PhoneMetrics) -> CGFloat {
        switch gameViewModel.phase {
        case .choosingRoom:
            return metrics.isCompactPhone ? 72 : 88
        case .nightDefense:
            return metrics.isCompactPhone ? 96 : 118
        }
    }

    private func adaptiveTopPanel<Content: View>(expanded: Bool, metrics: PhoneMetrics, collapsedChrome: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            if collapsedChrome {
                collapseHandle(
                    title: gameViewModel.phase == .choosingRoom ? "顶部信息" : "战况总览",
                    systemImage: expanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill",
                    expanded: expanded,
                    tint: phaseTint,
                    subtle: gameViewModel.phase == .choosingRoom,
                    action: { withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) { isTopPanelExpanded.toggle() } }
                )
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, max(4, metrics.safeArea.top + 2))

                if expanded {
                    content()
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            } else {
                content()
            }
        }
    }

    private func adaptiveBottomPanel<Content: View>(expanded: Bool, metrics: PhoneMetrics, collapsedChrome: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            if collapsedChrome {
                if expanded {
                    content()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                collapseHandle(
                    title: gameViewModel.phase == .choosingRoom ? "选房操作" : "操作面板",
                    systemImage: expanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill",
                    expanded: expanded,
                    tint: coachTint,
                    subtle: gameViewModel.phase == .choosingRoom,
                    action: { withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) { isBottomPanelExpanded.toggle() } }
                )
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.bottom, max(6, metrics.safeArea.bottom + 6))
            } else {
                content()
            }
        }
    }

    private func collapseHandle(title: String, systemImage: String, expanded: Bool, tint: Color, subtle: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(Color.white.opacity(subtle ? 0.18 : 0.36))
                    .frame(width: 28, height: 4)
                Text(expanded ? "收起\(title)" : "展开\(title)")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(subtle ? 0.72 : 1))
                Spacer(minLength: 0)
                Image(systemName: systemImage)
                    .foregroundColor(tint.opacity(subtle ? 0.66 : 1))
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(subtle ? MGSSUITheme.nightBase : .black.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(subtle ? 0.28 : 0.55), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(expanded ? "收起\(title)" : "展开\(title)")
    }

    private func choosingRoomTopInset(compact: Bool, metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("选择宿舍")
                        .font(compact ? .caption.bold() : .subheadline.bold())
                        .foregroundColor(.white)
                    Text("入住后角色固定在床边，不自由走动；靠升级门、床、炮台守到天亮。")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.76))
                        .lineLimit(compact ? 2 : 1)
                        .minimumScaleFactor(0.82)
                }
                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                choosingRoomBadge(title: "候选房间", value: "\(gameViewModel.availableRooms.count)", tint: MGSSUITheme.selection)
                choosingRoomBadge(title: "当前房间", value: gameViewModel.selectedRoom.name, tint: MGSSUITheme.utility)
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, collapsedChrome ? 4 : max(6, metrics.safeArea.top + 4))
        .padding(.bottom, collapsedChrome ? 4 : 6)
    }

    private func nightDefenseTopInset(compact: Bool, metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        topHud(compact: compact, condensed: collapsedChrome)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.top, collapsedChrome ? 4 : max(6, metrics.safeArea.top + 4))
            .padding(.bottom, collapsedChrome ? 4 : 6)
    }

    private func choosingRoomBottomInset(compact: Bool, metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        roomChoiceDeck(compact: compact, condensed: collapsedChrome)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.top, collapsedChrome ? 6 : 8)
            .padding(.bottom, collapsedChrome ? 4 : max(8, metrics.safeArea.bottom + 8))
    }

    private func nightDefenseBottomInset(compact: Bool, metrics: PhoneMetrics, collapsedChrome: Bool) -> some View {
        bottomCommandDeck(compact: compact, condensed: collapsedChrome)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.top, collapsedChrome ? 6 : 8)
            .padding(.bottom, collapsedChrome ? 4 : max(8, metrics.safeArea.bottom + 8))
    }

    private var nightPanelBackground: LinearGradient {
        LinearGradient(
            colors: [MGSSUITheme.nightPanelTop.opacity(0.92), MGSSUITheme.nightPanelBottom.opacity(0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var roomSelectionPanelBackground: LinearGradient {
        LinearGradient(
            colors: [
                MGSSUITheme.roomPanelTop,
                MGSSUITheme.roomPanelBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func topHud(compact: Bool, condensed: Bool) -> some View {
        VStack(alignment: .leading, spacing: condensed ? 4 : (compact ? 6 : 8)) {
            topHeadlineRow(compact: compact)
            topResourceStrip(compact: compact)
            if !condensed {
                topMeterStrip(compact: compact)
            }
        }
        .padding(condensed ? 8 : (compact ? 10 : 12))
        .background(nightPanelBackground)
        .overlay(RoundedRectangle(cornerRadius: condensed ? 14 : 16, style: .continuous).stroke(phaseTint.opacity(0.62), lineWidth: 1.2))
        .clipShape(RoundedRectangle(cornerRadius: condensed ? 14 : 16, style: .continuous))
        .shadow(color: phaseTint.opacity(0.22), radius: condensed ? 8 : 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("游戏状态，金币 \(gameViewModel.playerGold)，电力 \(gameViewModel.playerElectricity)，门耐久 \(Int(gameViewModel.doorHealth))")
    }

    private func topHeadlineRow(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(gameViewModel.phase == .choosingRoom ? "选择宿舍" : "夜间防守")
                    .font(compact ? .subheadline.bold() : .headline.bold())
                    .foregroundColor(.white)
                Text(phaseTitle)
                    .font(.caption2)
                    .foregroundColor(phaseTint)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(gameViewModel.phase == .choosingRoom ? "选房准备" : "距天亮 \(max(0, 180 - gameViewModel.gameTime))s")
                    .font(compact ? .caption.bold() : .subheadline.bold())
                    .foregroundColor(MGSSUITheme.selection)
                Text(threatLabel)
                    .font(.caption2.bold())
                    .foregroundColor(threatColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private func topResourceStrip(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            resourceChip(icon: "🪙", title: "金币", value: "\(gameViewModel.playerGold)", tint: .yellow)
            resourceChip(icon: "⚡", title: "电力", value: "\(gameViewModel.playerElectricity)", tint: .cyan)
            resourceChip(icon: "🚪", title: "门", value: "Lv.\(gameViewModel.player.doorLevel)", tint: .orange)
            resourceChip(icon: "🛡️", title: "炮台", value: "\(gameViewModel.turrets.count)", tint: .blue)
        }
    }

    private func topMeterStrip(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 10) {
            meter(title: "房门", value: gameViewModel.doorHealth, total: max(gameViewModel.doorMaxHealth, 1), tint: doorMeterTint)
            meter(title: "敌人", value: gameViewModel.ghost.health, total: max(gameViewModel.ghost.maxHealth, 1), tint: .red)
        }
    }

    private func roomChoiceDeck(compact: Bool, condensed: Bool) -> some View {
        VStack(spacing: condensed ? 7 : (compact ? 9 : 11)) {
            HStack(spacing: 8) {
                Image(systemName: "bed.double.fill")
                    .font(.caption.bold())
                    .foregroundColor(MGSSUITheme.selection)
                Text("选房操作区")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.88))
                Spacer(minLength: 8)
                Text("地图仅看位置")
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.58))
            }

            selectedRoomSummaryCard(compact: compact)

            roomSelectionStrip(compact: compact)

            beginNightButton(compact: compact)
        }
        .padding(condensed ? 10 : (compact ? 12 : 14))
        .background(roomSelectionPanelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: condensed ? 18 : 20, style: .continuous)
                .stroke(MGSSUITheme.selection.opacity(0.70), lineWidth: 1.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: condensed ? 18 : 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.46), radius: 18, x: 0, y: -6)
    }

    private func selectedRoomSummaryCard(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("当前选择")
                        .font(.caption2.bold())
                        .foregroundColor(MGSSUITheme.selection.opacity(0.86))
                    Text(gameViewModel.selectedRoom.name)
                        .font(compact ? .caption.bold() : .subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                Spacer(minLength: 8)
                Text(roomTag(for: gameViewModel.selectedRoom))
                    .font(.caption2.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MGSSUITheme.selection)
                    .clipShape(Capsule())
            }

            HStack(spacing: compact ? 6 : 8) {
                roomSummaryPill(title: "风险", value: "\(gameViewModel.selectedRoom.risk)级", tint: roomRiskColor(for: gameViewModel.selectedRoom))
                roomSummaryPill(title: "产出", value: roomRewardText(for: gameViewModel.selectedRoom), tint: .white)
                roomSummaryPill(title: "门耐久", value: roomDoorHealthText(for: gameViewModel.selectedRoom), tint: .cyan)
            }

            Text("地图只看房间位置；下方切换，确认后进入夜晚防守。")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.70))
                .lineLimit(compact ? 2 : 1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 9 : 11)
        .background(MGSSUITheme.cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MGSSUITheme.selection.opacity(0.42), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func roomSelectionStrip(compact: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: compact ? 6 : 8) {
                ForEach(gameViewModel.availableRooms) { room in
                    roomChoicePill(room, compact: compact)
                }
            }
            .padding(.horizontal, 1)
        }
        .accessibilityLabel("切换候选宿舍")
    }

    private func roomChoicePill(_ room: DormRoom, compact: Bool) -> some View {
        let isSelected = room.id == gameViewModel.selectedRoom.id

        return Button(action: { gameViewModel.chooseRoom(room) }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption2.bold())
                VStack(alignment: .leading, spacing: 1) {
                    Text(room.name)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(isSelected ? "已选择 ✓" : "选择")
                        .font(.caption2.bold())
                        .foregroundColor(isSelected ? .black.opacity(0.78) : .white.opacity(0.62))
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, compact ? 9 : 10)
            .padding(.vertical, compact ? 7 : 8)
            .background(isSelected ? MGSSUITheme.selection : MGSSUITheme.chipFill)
            .overlay(
                Capsule()
                    .stroke(isSelected ? MGSSUITheme.selection.opacity(0.95) : Color.white.opacity(0.14), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isSelected ? "已选择" : "选择")\(room.name)")
    }

    private func roomSummaryPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.64))
            Text(value)
                .font(.caption.bold())
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MGSSUITheme.chipFill)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.32), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func beginNightButton(compact: Bool) -> some View {
        Button(action: { gameViewModel.beginNightDefense() }) {
            commandButtonContent(title: "确认入住并开始夜晚", subtitle: "确认后角色固定，无法自由移动", systemImage: "moon.stars.fill", compact: compact)
        }
        .buttonStyle(CommandButtonStyle(tint: MGSSUITheme.action, compact: compact))
    }

    private func quickStatusRow(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 10) {
            quickStatusPill(
                title: gameViewModel.player.isSleeping ? "当前状态" : "建议动作",
                value: gameViewModel.player.isSleeping ? "睡觉发育中" : quickActionText,
                tint: gameViewModel.player.isSleeping ? .green : coachTint,
                systemImage: gameViewModel.player.isSleeping ? "bed.double.fill" : quickActionIcon
            )
            quickStatusPill(
                title: "临时效果",
                value: activeEffectSummary,
                tint: activeEffectTint,
                systemImage: activeEffectIcon
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("快速状态，\(gameViewModel.player.isSleeping ? "睡觉发育中" : quickActionText)，\(activeEffectSummary)")
    }

    private func bottomCommandDeck(compact: Bool, condensed: Bool) -> some View {
        VStack(spacing: condensed ? 6 : (compact ? 7 : 9)) {
            if !condensed {
                gameAreaLegend(compact: compact)
                    .opacity(isAnySheetPresented ? 0.32 : 1)
            }

            primaryCommandBar(compact: compact)
                .opacity(isAnySheetPresented ? 0.22 : 1)
                .allowsHitTesting(!isAnySheetPresented)

            if !isAnySheetPresented && !condensed {
                secondaryCommandRow(compact: compact)
            }
        }
        .padding(condensed ? 8 : (compact ? 9 : 11))
        .background(nightPanelBackground)
        .overlay(RoundedRectangle(cornerRadius: condensed ? 16 : 18, style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: condensed ? 16 : 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func gameAreaLegend(compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 7) {
            legendChip("蓝=你/床", tint: .cyan)
            legendChip("红=猛鬼", tint: MGSSUITheme.danger)
            legendChip("棕=门", tint: MGSSUITheme.warning)
            legendChip("青=炮台位", tint: MGSSUITheme.utility)
            legendChip("黄=道具", tint: MGSSUITheme.selection)
        }
        .font(.caption2.bold())
        .lineLimit(1)
        .minimumScaleFactor(0.68)
        .accessibilityLabel("地图图例：蓝色是玩家和床，红色是猛鬼，棕色是门，青色是炮台位，黄色是道具")
    }

    private func legendChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .foregroundColor(.white.opacity(0.88))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(tint.opacity(0.16))
            .overlay(Capsule().stroke(tint.opacity(0.42), lineWidth: 1))
            .clipShape(Capsule())
    }

    private func primaryCommandBar(compact: Bool) -> some View {
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
    }

    private func secondaryCommandRow(compact: Bool) -> some View {
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

    private var isAnySheetPresented: Bool {
        isShopPresented || isRulesPresented
    }

    private var shouldShowCriticalOverlay: Bool {
        gameViewModel.phase == .nightDefense && (isBreakingDoor || gameViewModel.ghost.isFrozen || recommendedCommand == .repair)
    }

    private var topSummaryText: String {
        if gameViewModel.ghost.isFrozen {
            return "猛鬼已冻结，趁窗口补强防线"
        }
        if isBreakingDoor && gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1) < 0.45 {
            return "门耐久偏低，优先修门或升门"
        }
        if isBreakingDoor {
            return "猛鬼正在破门，优先醒来布防"
        }
        if recommendedCommand == .repair {
            return "当前建议先修门，避免防线失守"
        }
        return coachText
    }

    private var phaseTitle: String {
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
        if gameViewModel.player.activeEffects.contains(where: { $0.type == .freezeGhost && $0.expiresAt > Date() }) {
            return .shop
        }
        if gameViewModel.ghost.isFrozen {
            return doorRatio < 0.45 ? .repair : .shop
        }
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
        if gameViewModel.ghost.isFrozen { return "趁冻结补炮台/升床" }
        if gameViewModel.player.bedLevel < 3 { return "优先升床" }
        if gameViewModel.doorHealth / max(gameViewModel.doorMaxHealth, 1) < 0.55 { return "修门/升门" }
        if gameViewModel.turrets.count < 2 { return "补炮台" }
        return "强化防线"
    }

    private var quickActionText: String {
        switch recommendedCommand {
        case .wake: return "立刻醒来布防"
        case .shop:
            if gameViewModel.ghost.isFrozen { return "趁冻结补强防线" }
            return recommendedShopAction
        case .items: return "查看道具应对"
        case .repair: return "花90金币修门"
        case .sleep: return "继续睡觉发育"
        case .none: return "按当前节奏推进"
        }
    }

    private var quickActionIcon: String {
        switch recommendedCommand {
        case .wake: return "figure.stand"
        case .shop: return "cart.fill"
        case .items: return "sparkles"
        case .repair: return "hammer.fill"
        case .sleep: return "bed.double.fill"
        case .none: return "checkmark.circle.fill"
        }
    }

    private var activeEffectSummary: String {
        if gameViewModel.ghost.isFrozen { return "猛鬼已冻结" }
        let active = gameViewModel.player.activeEffects.filter { $0.expiresAt > Date() }
        guard let effect = active.sorted(by: { $0.expiresAt < $1.expiresAt }).first else { return "暂无增益" }
        let seconds = max(1, Int(effect.expiresAt.timeIntervalSinceNow.rounded(.down)))
        return "\(effectLabel(effect.type)) · \(seconds)s"
    }

    private var activeEffectTint: Color {
        if gameViewModel.ghost.isFrozen { return .cyan }
        let active = gameViewModel.player.activeEffects.filter { $0.expiresAt > Date() }
        guard let effect = active.sorted(by: { $0.expiresAt < $1.expiresAt }).first else { return .white }
        return effectTint(effect.type)
    }

    private var activeEffectIcon: String {
        if gameViewModel.ghost.isFrozen { return "snowflake" }
        let active = gameViewModel.player.activeEffects.filter { $0.expiresAt > Date() }
        guard let effect = active.sorted(by: { $0.expiresAt < $1.expiresAt }).first else { return "bolt.slash.fill" }
        return effectIcon(effect.type)
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

    private func choosingRoomBadge(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.68))
            Text(value)
                .font(.caption.bold())
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func roomCardMetricRow(title: String, value: String, valueColor: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.68))
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
    }

    private func roomTag(for room: DormRoom) -> String {
        switch room.risk {
        case 1: return "稳健开局"
        case 2: return "均衡发育"
        case 3: return "近门压迫"
        default: return "高收益高压"
        }
    }

    private func roomRiskColor(for room: DormRoom) -> Color {
        switch room.risk {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private func roomRewardText(for room: DormRoom) -> String {
        room.rewardBonus > 0 ? "+\(room.rewardBonus)/秒" : "基础产出"
    }

    private func roomDoorHealthText(for room: DormRoom) -> String {
        let initialDoorHealth = Int(max(700.0, 900.0 + room.doorBonus))
        return "\(initialDoorHealth)"
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

    private func quickStatusPill(title: String, value: String, tint: Color, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundColor(tint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.68))
                Text(value)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background(tint.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.55), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func effectLabel(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp: return "急行鞋"
        case .goldBoost: return "金币翻倍"
        case .doorRepair: return "紧急维修"
        case .freezeGhost: return "冰冻"
        case .invincible: return "无敌护盾"
        case .barrier: return "房门屏障"
        case .slowTrap: return "迟缓陷阱"
        }
    }

    private func effectIcon(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp: return "figure.run"
        case .goldBoost: return "dollarsign.circle.fill"
        case .doorRepair: return "wrench.and.screwdriver.fill"
        case .freezeGhost: return "snowflake"
        case .invincible: return "shield.fill"
        case .barrier: return "door.left.hand.open"
        case .slowTrap: return "tortoise.fill"
        }
    }

    private func effectTint(_ type: Item.ItemType) -> Color {
        switch type {
        case .speedUp: return .blue
        case .goldBoost: return .yellow
        case .doorRepair: return .green
        case .freezeGhost: return .cyan
        case .invincible: return .purple
        case .barrier: return .orange
        case .slowTrap: return .pink
        }
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
    var needsCollapsedChrome: Bool { size.height < 820 || size.width < 390 }
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
