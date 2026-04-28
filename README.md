# 猛鬼宿舍 iOS 版

基于 React + TypeScript 的 Web 游戏移植到 iOS 平台，使用 SwiftUI + SpriteKit 实现。

## 功能特性

- 🎮 完整的游戏循环：大厅 -> 游戏战斗 -> 游戏结束
- 🧠 智能 AI 系统：猛鬼 AI 和防御塔 AI
- 🛡️ 策略塔防玩法：经济系统、防御升级、道具系统
- 🎨 精美 UI 设计：Glassmorphism 风格、适配多分辨率
- 🌍 多语言支持：中文本地化

## 游戏玩法

- 通过睡觉持续获得金币
- 建造和升级防御设施（房门、炮台）
- 购买强力道具抵御猛鬼攻击
- 最终抵御猛鬼或反杀猛鬼获胜

## 技术栈

- SwiftUI + SpriteKit
- iOS 16.0+
- XcodeGen

## 构建

```bash
# 安装 XcodeGen
brew install xcodegen

# 生成项目
xcodegen

# 构建 unsigned app bundle
xcodebuild clean build \
  -project ProjectMGSS.xcodeproj \
  -scheme ProjectMGSS \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 本地打包 unsigned IPA（与 GitHub Actions 流程一致）
APP_PATH=$(find build/Build/Products/Release-iphoneos -maxdepth 1 -name "*.app" -type d | head -1)
mkdir -p artifacts/Payload
cp -R "$APP_PATH" artifacts/Payload/
(cd artifacts && zip -qry ProjectMGSS-unsigned.ipa Payload)
rm -rf artifacts/Payload
```

## CI/CD

GitHub Actions 自动构建 IPA：
- 推送代码自动触发构建
- 生成 unsigned IPA artifact
- 保留 30 天

## License

MIT
