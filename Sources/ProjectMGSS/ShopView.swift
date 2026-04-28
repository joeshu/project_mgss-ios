import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("防御塔")) {
                    Button(action: {
                        viewModel.addTurret(at: Position(x: 2.0, y: 2.0), cost: 500, range: 5.0, damage: 50.0)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("基础炮台")
                                    .font(.headline)
                                Text("攻击力: 50 | 射程: 5.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("500 金币")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                    }
                    .disabled(viewModel.playerGold < 500)
                    
                    Button(action: {
                        viewModel.addTurret(at: Position(x: 4.0, y: 2.0), cost: 1500, range: 6.0, damage: 100.0)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("强力炮台")
                                    .font(.headline)
                                Text("攻击力: 100 | 射程: 6.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("1500 金币")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                    }
                    .disabled(viewModel.playerGold < 1500)
                }
                
                Section(header: Text("房门升级")) {
                    Button(action: {
                        viewModel.repairDoor()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("修复房门")
                                    .font(.headline)
                                Text("恢复 500 点耐久")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("300 金币")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                    }
                    .disabled(viewModel.playerGold < 300)
                }
            }
            .navigationTitle("商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(viewModel: GameViewModel())
    }
}
