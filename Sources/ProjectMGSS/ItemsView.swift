import SwiftUI

struct ItemsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.04, blue: 0.12), Color(red: 0.12, green: 0.07, blue: 0.19)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        rulesCard
                        Text("可用道具")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 2)

                        ForEach(Item.ItemType.allCases, id: \.self) { itemType in
                            itemCard(itemType)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("道具与规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("夜晚宿舍防守循环")
                .font(.headline.bold())
                .foregroundColor(.white)
            ruleLine("1", "入夜后先睡觉攒金币，床等级越高收益越快。")
            ruleLine("2", "猛鬼靠近门后会进入破门状态，门耐久归零即失败。")
            ruleLine("3", "升级门提高容错，建设炮台可以反杀猛鬼。")
            ruleLine("4", "坚持到天亮或击败猛鬼即可胜利。")
            Text("说明：本版本采用原创美术表达，保留宿舍防守玩法结构与移动端操作节奏。")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.56))
        }
        .padding(14)
        .background(.black.opacity(0.50))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.purple.opacity(0.62), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func ruleLine(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text(number)
                .font(.caption.bold())
                .foregroundColor(.black)
                .frame(width: 20, height: 20)
                .background(Color.yellow)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.82))
        }
    }

    private func itemCard(_ type: Item.ItemType) -> some View {
        Button(action: { viewModel.useItem(type) }) {
            HStack(alignment: .top, spacing: 12) {
                Text(icon(type))
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(tint(type).opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(displayName(type))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(getItemDescription(type))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.68))
                    Text("点击模拟使用")
                        .font(.caption2.bold())
                        .foregroundColor(.yellow)
                }
                Spacer()
            }
            .padding(13)
            .background(.black.opacity(0.44))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(tint(type).opacity(0.66), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private func displayName(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp:
            return "急行鞋"
        case .goldBoost:
            return "金币翻倍卡"
        case .doorRepair:
            return "紧急维修包"
        case .freezeGhost:
            return "冰冻符咒"
        case .invincible:
            return "无敌护盾"
        case .barrier:
            return "房门屏障"
        case .slowTrap:
            return "迟缓陷阱"
        }
    }

    private func getItemDescription(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp:
            return "移动速度提升，预留给后续房间走位和拾取玩法。"
        case .goldBoost:
            return "金币获取速度提升 2 倍，持续 10 秒。"
        case .doorRepair:
            return "立即修复 500 点房门耐久，破门危机时使用。"
        case .freezeGhost:
            return "冻结猛鬼 8 秒，暂停移动和攻击。"
        case .invincible:
            return "无敌状态，短时间免疫所有伤害。"
        case .barrier:
            return "生成房门屏障，6 秒内阻止猛鬼破门。"
        case .slowTrap:
            return "放置陷阱，使猛鬼明显减速 6 秒。"
        }
    }

    private func icon(_ type: Item.ItemType) -> String {
        switch type {
        case .speedUp: return "👟"
        case .goldBoost: return "🪙"
        case .doorRepair: return "🧰"
        case .freezeGhost: return "🧊"
        case .invincible: return "🛡️"
        case .barrier: return "🚪"
        case .slowTrap: return "🕸️"
        }
    }

    private func tint(_ type: Item.ItemType) -> Color {
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
}

struct ItemsView_Previews: PreviewProvider {
    static var previews: some View {
        ItemsView(viewModel: GameViewModel())
    }
}
