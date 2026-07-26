# Splitwise iOS 原生 App (Swift & SwiftUI)

一个完整复刻 **Splitwise** 核心功能的 iOS 原生应用，基于 **SwiftUI**、**SwiftData**、**Swift Charts**、**StoreKit 2**、**Vision OCR** 与 **iOS 17 多语言国际化** 打造，支持 iPhone 与 iPad 响应式适配，具备提交至 App Store Connect (ASC) 的完整工程架构。

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2017.0%2B-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017-green.svg)

---

## ✨ 核心功能与亮点

### 1. 📱 iPhone & iPad 响应式自适应布局
- **iPhone**：采用经典的 5 标签栏 Tab 导航（群组、好友、动态、报表、账户）。
- **iPad**：自动切为现代 3 栏式 `NavigationSplitView` 侧边栏与明细布局。

### 2. 🧮 5 大 AA 账单分摊引擎 (`SplitOptionsView.swift`)
- `=/=` **等额平摊 (Equal)**：自动进行角分舍入与均衡分配。
- `$` **指定精确金额 (Exact)**：实时校验总额与剩余未分配金额。
- `%` **百分比分摊 (Percentage)**：自动校验 100% 比例并换算金额。
- `1x` **权重/份数分摊 (Shares)**：根据份数权重灵活计算个人应付。
- `🧾` **小票逐项分摊 (Itemized)**：按品类和小票明细拆分个人账单。

### 3. 🕸 智能债务简化算法 (`DebtSimplifier.swift`)
- 基于图论最小流（Min-Cost Flow / Greedy Matching）算法。
- 根据全组成员的净余额（Net Balance），自动将复杂的 N-to-N 交错欠款简化为最少笔数的转账方案。
- 提供直观的对比视图（Raw Debts vs Simplified Debts），支持一键结清平账。

### 4. 📷 Vision AI 小票识别扫描 (`ReceiptScannerService.swift`)
- 集成 Apple **Vision 框架** (`VNRecognizeTextRequest`)。
- 拍照或上传小票自动解析总金额、商户名称及具体商品明细。

### 5. 💎 Splitwise Pro 高级内购订阅 (StoreKit 2)
- 基于 Apple 最新 **StoreKit 2** (`StoreView`, `Product`, `Transaction`)。
- 解锁 Pro 专属权益：Vision OCR 小票自动识别、实时汇率换算、PDF/CSV 报表导出、债务极简优化开关、Swift Charts 统计图表、无广告体验。
- 内置 `StoreKit.storekit` Xcode 本地沙盒测试配置及模拟器 Mock Pro 开关。

### 6. 📊 统计图表与报表导出
- **Swift Charts**：提供 Category Spending 环形图、每月消费趋势折线图、群组消费对比柱状图。
- **PDF & CSV 导出**：支持一键生成专业 PDF 账单报表与 CSV 数据表，并唤起系统 Share Sheet 分享。

### 7. 🌐 多语言国际化 (Localization)
- 接入 iOS 17 String Catalog (`Localizable.xcstrings`)。
- 默认支持 **英文 (en)**、**简体中文 (zh-Hans)**、**繁体中文 (zh-Hant)**。

---

## 🛠 技术栈

| 模块 | 技术方案 |
| :--- | :--- |
| **语言 & 范式** | Swift 6 / Swift 5.10, SwiftUI, `@Observable` |
| **数据持久化** | SwiftData (iOS 17 ModelContainer / ModelContext) |
| **图表库** | Swift Charts (SectorMark, LineMark, BarMark) |
| **应用内购买** | StoreKit 2 Framework |
| **图像识别** | Vision Framework (OCR Text Recognition) |
| **国际化** | String Catalog (`Localizable.xcstrings`) |
| **最低系统要求** | iOS 17.0+ / iPadOS 17.0+ |

---

## 📂 项目目录结构

```text
SplitwiseApp/
├── App/
│   ├── SplitwiseApp.swift           # @main 入口，配置 SwiftData ModelContainer
│   ├── AppState.swift               # 全局状态 (选定币种、主题模式、语言)
│   └── Info.plist                   # ASC 权限声明 (Camera, Photos, FaceID)
├── Models/
│   ├── User.swift                   # 用户 SwiftData 模型
│   ├── Group.swift                  # 群组 SwiftData 模型
│   ├── Expense.swift                # 账单 SwiftData 模型
│   ├── ExpenseSplit.swift           # 分摊比例 Codable 模型
│   ├── Settlement.swift             # 结清/平账记录 SwiftData 模型
│   ├── ActivityLog.swift            # 动态日志 SwiftData 模型
│   └── ProSubscriptionManager.swift # StoreKit 2 订阅管理服务
├── Services/
│   ├── DebtSimplifier.swift         # 最少转账笔数债务简化算法
│   ├── ReceiptScannerService.swift  # Vision OCR 小票文本识别
│   ├── ExportManager.swift          # PDF 与 CSV 报表生成器
│   └── SampleData.swift             # 初始演示数据预加载服务
├── Utilities/
│   ├── CurrencyFormatter.swift      # 多币种格式化与实时汇率换算
│   ├── ColorTheme.swift             # 品牌 Teal & 盈亏主题色彩
│   └── LocalizedStrings.swift       # 国际化辅助工具
├── Views/
│   ├── MainView.swift               # iPhone/iPad 响应式自适应主导航
│   ├── Groups/                      # 群组列表、新建群组、群组详情、简化债务
│   ├── Friends/                     # 好友列表、添加好友、1对1平账历史
│   ├── Expense/                     # 添加/编辑账单、5种AA分摊模式、小票识别、账单明细
│   ├── Settlement/                  # 结清平账 Modal (现金/微信/支付宝/PayPal/Venmo)
│   ├── Activity/                    # 动态 Timeline 时间线
│   ├── Analytics/                   # Swift Charts 数据统计与 PDF/CSV 导出
│   ├── Account/                     # 个人账户、外观切换、Splitwise Pro 订阅页
│   └── Components/                  # BalanceBadge, CategoryIcon, CurrencyPicker
└── Resources/
    ├── Localizable.xcstrings        # 多语言字符串目录 (en, zh-Hans, zh-Hant)
    └── StoreKit.storekit            # StoreKit 本地沙盒测试配置
```

---

## 🚀 如何运行与编译

### 1. 使用 Xcode 打开项目
项目根目录下包含标准的 Xcode 工程文件：
```bash
open SplitwiseApp.xcodeproj
```
或者直接双击打开 `SplitwiseApp.xcodeproj`。

### 2. 运行与调试
- 在 Xcode 顶部 Target 中选择 `SplitwiseApp`。
- 选择目标设备为任意 `iPhone 16` 模拟器或连接的 iOS 17+ 实体设备。
- 按下 `Cmd + R` 即可编译并运行应用。

### 3. 提交至 App Store Connect (ASC)
1. 在 Xcode 中配置你的 Developer Team 签名（Signing & Capabilities）。
2. 在顶部 Target 目标中选择 **Any iOS Device (arm64)**。
3. 选择菜单栏 **Product -> Archive** 按钮。
4. 打包完成后在 Organizer 窗口点击 **Distribute App** 导出并上传至 App Store Connect！

---

## 📄 开源许可

本项目基于 MIT 许可证开源。
