# Splitwise iOS 项目全套交接文档包 (Documentation Index)

欢迎查阅 **Splitwise iOS 原生 App** 的全套项目交接与开发文档包。为了帮助团队成员、产品经理或技术评审快速深入了解项目，请根据需求查阅以下分层次、多维度的专业文档：

---

## 📂 文档导航索引

| 文档名称 | 内容侧重点 | 适用人群 |
| :--- | :--- | :--- |
| 📄 **[PRD.md](./PRD.md)** | 产品需求规格、目标用户、5大分摊模式、债务极简算法逻辑、Splitwise Pro 商业变现模型 | 产品经理 (PM) / 业务评审 / 运营 |
| 🏗 **[ARCHITECTURE.md](./ARCHITECTURE.md)** | 系统分层架构、SwiftData 数据模型 E-R 图、债务极简算法图论原理、StoreKit 2 生命周期 | iOS 架构师 / 开发者 / 技术评审 |
| 🎨 **[UI_UX_PROTOTYPE.md](./UI_UX_PROTOTYPE.md)** | 页面全局交互流程图 (Mermaid)、iPhone/iPad 响应式规范、分摊模式控件 Spec | UI/UX 设计师 / 前端/iOS 开发者 |
| 💎 **[design_tokens.md](../design_tokens.md)** | 色彩 Hex/RGB、字体 Specifies、Padding 间距与 Corner Radius 圆角令牌 | UI 设计师 / 视图组件开发人员 |
| 🚀 **[README.md](../README.md)** | 快速上手指南、Xcode 项目结构、本地编译与 App Store Connect (ASC) 提交步骤 | 开发者 / DevOps / 测试人员 |

---

## ⚡️ 快速开始 (Quick Start for Developers)

1. **克隆项目与打开工程**：
   ```bash
   git clone git@github.com:aSynch1889/SplitwiseApp.git
   cd SplitwiseApp
   open SplitwiseApp.xcodeproj
   ```

2. **本地编译与测试**：
   - 最低支持环境：**macOS 14.0+**, **Xcode 15.0+**, **iOS 17.0+ Target**。
   - 在 Xcode 中选择 `SplitwiseApp` Scheme 并在 iPhone 16 模拟器上按 `Cmd + R` 即可直接编译运行。
   - 使用 `Resources/StoreKit.storekit` 可在本地沙盒测试 Splitwise Pro 内购流程。

3. **打包提交至 App Store Connect (ASC)**：
   - 切换 Target 为 `Any iOS Device (arm64)`。
   - 执行菜单栏 **Product -> Archive** 进行打包上传。
