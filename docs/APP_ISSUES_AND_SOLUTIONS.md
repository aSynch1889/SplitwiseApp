# SplitwiseApp 深度问题分析与解决方案

> 初评日期：2026-07-27
> 最近复评：2026-07-29（commit `1480a9906a0c`）
> 评估范围：源码、产品逻辑、数据层、变现、国际化、工程与体验  
> 目标：系统性列出当前仍存在的问题，并给出可落地的修复方案（按优先级排序）

---

## 0. 本次复评基线与状态

### 0.1 状态定义

| 状态 | 含义 |
|------|------|
| ✅ 已修复 | 代码与验证均证明问题已关闭 |
| ⚠️ 部分修复 / 待外部核验 | 仅完成部分，或必须在 ASC/真机继续验证 |
| ❌ 未修复 | 当前源码仍可直接定位到问题 |
| ℹ️ 结论修正 | 初评描述或严重度有误，本次已校正 |

### 0.2 复评结果

- 初评的 **I-01 已修复**；**I-02～I-16 仍未修复**；其中 I-14（JPEG 图标）由 P1 调整为 P3 质量项，不再表述为“必然上传失败”。
- 本次新增 **I-17～I-25**，其中 I-17（个人账单错误分摊）和 I-18（缺失 Required Reason API 隐私清单）属于新的 P0。
- **Debug 与 Release 模拟器构建均成功**（Xcode 26.3），但均产生 `ProSubscriptionManager.swift:28` 的 2 类警告。
- `xcodebuild test` 失败：Scheme 未配置 Test Action；工程只有 1 个 App target，无 XCTest/UI Test target。
- String Catalog 共 **208** 个 key，`zh-Hans` 与 `zh-Hant` 各只有 **9 个已翻译（4.3%）**。
- Release App 内未包含 `PrivacyInfo.xcprivacy`；二进制仍可检出 Mock Pro、Pro Demo、Splitwise 品牌与原 Product ID。

### 0.3 验证命令

```bash
xcodebuild -project SplitwiseApp.xcodeproj -scheme SplitwiseApp \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SplitwiseApp.xcodeproj -scheme SplitwiseApp \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SplitwiseApp.xcodeproj -scheme SplitwiseApp \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO test
```

> 构建成功只证明当前工具链可以生成二进制，不代表业务正确、IAP 可购买、真机权限可用或 App Store 可通过。

---

## 1. 执行摘要

本应用是一套 **离线优先的 SwiftUI + SwiftData 账单分摊 Demo/原型**。UI 覆盖面较全（群组、好友、分摊、结清、图表、导出、StoreKit 壳），但核心金额正确性、产品诚实性、IAP 生命周期和提交合规仍未达到可上线水平。

| 维度 | 当前水平 | 结论 |
|------|----------|------|
| 核心记账 UI | 中高 | 主流程基本可走通 |
| 业务正确性 | 低 | 当前用户 ID、个人账单、多币种、分摊校验、图表均存在硬伤 |
| Pro/付费墙 | 低 | 默认 Mock Pro，几乎无真实门禁 |
| 协同/账号 | 缺失 | 无登录、无云同步、邀请文案误导 |
| 合规与品牌 | 极高风险 | 商标名、隐私政策、订阅合规、隐私清单均未就绪 |
| 工程化 | 低 | 可构建但有警告；无 Test target、CI、迁移与错误恢复 |
| 国际化 | 极低 | 208 个 key 中，简中/繁中各仅 9 个已翻译 |

**建议发布策略：** 先完成 P0/P1 修复与品牌重命名，再以「本地 AA 记账工具」定位提交；不要以「官方 Splitwise 复刻」叙事上架。

---

## 2. 问题分级说明

| 级别 | 含义 |
|------|------|
| **P0 阻断** | 核心数据错误 / 审核必挂 / 法律风险，上线前必须修 |
| **P1 严重** | 明显功能缺陷或虚假宣传，会显著伤害信任或转化 |
| **P2 重要** | 体验与可维护性问题，首发可妥协但应排期 |
| **P3 优化** | 体验打磨、性能与扩展性 |

---

## 3. P0 阻断级问题

### 3.1 `currentUserId` 与真实用户严重脱节（核心余额全错）

**状态：✅ 已修复（I-01）**

**现象（历史）**

- `AppState.currentUserId` 在 `init` 时默认为 `UUID()`（每次冷启动可能是新随机 ID）。
- 样例数据与业务以 `User.isCurrentUser == true` 标识「我」。
- 大量 UI 用 `appState.currentUserId` 判断「You」、计算群组/好友净余额（`GroupListView`、`FriendDetailView`、`FriendsListView`、`GroupDetailView` 等）。

**修复说明**

1. `AppState` 将 `currentUserId` 持久化到 `UserDefaults`（`app_current_user_id`）。
2. `MainView.onAppear` 在样例数据填充后调用 `resolveCurrentUser(from:)`，以 SwiftData 中 `isCurrentUser == true` 为准写回 `AppState`。
3. 若库中无 `isCurrentUser` 但持久化 ID 仍匹配某用户，则标记该用户为当前用户。

**仍待（Phase 1）**

- 增加单元测试：样例数据下整体净余额、群组余额与手工验算一致。

---

### 3.2 品牌与商标：直接使用「Splitwise」命名

**现象**

- `CFBundleName`、启动页、导航、Pro 文案、PDF 元数据、StoreKit 商品名均使用 **Splitwise / Splitwise Pro**。
- Bundle ID：`com.splitwise.ios.app`。
- README 写「完整复刻 Splitwise」。

**后果**

- 商标侵权与 App Store 4.1（抄袭/混淆）高风险。
- 即使功能做完，品牌不过关也会被拒或被下架。

**解决方案**

1. **立即重命名产品**（建议原创名，如 BillFlow / SplitNest / FairShare 等，并做商标检索）。
2. 全量替换显示名、Bundle ID、StoreKit Product ID、PDF 作者字段、本地化字符串。
3. 营销文案改为「灵感来自常见 AA 场景」，禁止「官方复刻 / 兼容 Splitwise」表述。
4. 应用图标、颜色体系避免高度仿官方品牌识别。

---

### 3.3 Pro 默认开启 + 模拟器 Mock 开关上线可见

**现象**

```swift
// ProSubscriptionManager
public var isMockPro: Bool = true  // 默认 true → isPro 恒为 true
```

- 订阅页暴露 `Simulator Mock Pro Mode` Toggle。
- 产品拉取失败时 `purchasePlan` 直接 `isMockPro = true`。
- 全项目几乎**没有**基于 `isPro` 的功能门禁（导出/OCR/图表/债务简化均免费可用）。

**后果**

- 商业模型失效；审核员可免费使用全部「Pro」能力。
- 若宣称付费权益，属于**误导性 IAP**（Guideline 3.1.x / 2.3.x）。
- Mock 开关上架会被视为未完成/测试构建。

**解决方案**

1. Release 构建强制：
   ```swift
   #if DEBUG
   var isMockPro = false // 仅 DEBUG 面板可开
   #else
   var isMockPro = false // 永远 false，且 UI 不展示
   #endif
   ```
2. 为 OCR、导出、高级图表、债务简化开关、Itemized 等实现统一 `ProGate`。
3. 非 Pro 点击进入标准 Paywall（权益对比 + 购买 + 恢复）。
4. 购买失败时展示错误，**禁止**自动 Mock 解锁。
5. ASC 中配置真实订阅组、价格、本地化、税务与沙盒账号测试。

---

### 3.4 订阅合规要素缺失（法律链接与动态价格）

**现象**

- 仅有一句静态免责声明，**无可点击** Privacy Policy / Terms of Use / EULA 链接。
- 价格硬编码 `$2.99 / month`、`$29.99 / year`，未使用 `Product.displayPrice`。
- 未展示订阅时长、续费规则、试用期的完整法定披露（部分地区强制）。

**解决方案**

1. 上线前准备可公网访问的：
   - Privacy Policy URL  
   - Terms of Use / EULA URL  
2. 订阅页必须用 `product.displayPrice`、`subscriptionPeriod`、introductory offer 动态文案。
3. 提供 **Restore Purchases**（已有）并在失败时有明确 Toast/Alert。
4. App 描述、截图、ASC 订阅元数据与 App 内文案一致。
5. Account/About 增加法律入口；设置 `ITSAppUsesNonExemptEncryption` 等导出合规声明。

---

### 3.5 隐私声明与真实能力不一致

| 声明 | 实际实现 | 风险 |
|------|----------|------|
| `NSCameraUsageDescription` | 仅有 `PhotosPicker`，无相机拍摄 | 未使用权限 + 描述夸大 |
| `NSFaceIDUsageDescription` | Face ID Toggle 无 `LocalAuthentication` | 虚假权限 / 功能欺诈感 |
| `NSPhotoLibraryUsageDescription` | 使用 PhotosPicker | 基本合理，但文案可更准确 |
| Push Notifications Toggle | 无 APNs 注册 | 空开关误导用户 |

**解决方案**

1. **不做就删**：移除 Face ID / Camera / Push 的 Info.plist 与 UI，或完整实现。
2. 若要做相册 OCR：保留 Photos；若要拍照：接入 `UIImagePickerController` / `AVCapture` 并真请求相机。
3. 若要做锁屏：用 `LAContext` 在 `scenePhase == .active` 时鉴权，失败则遮罩。
4. 隐私清单（Privacy Nutrition Labels）与实际数据收集一致：当前为本地存储，应声明「不收集」或仅「设备上处理」。

---

### 3.6 债务计算不支持多币种混合

**现象**

- `DebtSimplifier` 直接对 `expense.amount` / `settlement.amount` 做加减，**不看 currency**。
- 用户可在账单级选不同币种；群组有 `defaultCurrency`。
- 图表 `totalSpent` 亦直接 `sum(amount)`，跨币种数字无意义。

**后果**

- 东京旅行（USD）+ 房租（USD）尚可；一旦混入 JPY/CNY，余额与「简化债务」错误。
- 「实时汇率」实为 `CurrencyFormatter` 内写死静态表，且未接入余额引擎。

**解决方案**

1. 引擎层统一：所有金额先换算到 **群组基准币种** 再算净额。
2. 换算源：
   - 短期：App 内手动汇率表 + 时间戳标注「非实时」。
   - 中期：接入公开汇率 API，并缓存；失败回退上次缓存。
3. UI 明确展示：余额币种、换算提示、无法换算时的错误态。
4. 禁止在未换算时跨币种相加（断言/过滤 + 单元测试）。

---

### 3.7 「No Group (Individual)」会错误分摊给全部用户（新增）

**状态：❌ 未修复（I-17）**

**证据**

- `AddExpenseView.groupMembers` 在没有选中群组时直接返回 `users`，即 SwiftData 中的全部用户。
- 随后 `recalculateSplits()` 为这些用户全部创建分摊；Save 只校验标题与总额。
- iPhone 端没有全局 Add Expense 入口，`FriendDetailView.showingAddExpense` 也从未使用，导致好友 1 对 1 记账入口事实上断裂。
- 如果数据库没有 `isCurrentUser`，`payerId` 会保留随机 UUID，仍可能保存成无法关联用户的账单。

**后果**

- 用户选择“个人账单”时，账单可能被 Alex/Sarah 等所有本地联系人共同分摊，直接污染余额。
- 存在孤儿 `payerId`、空 splits 或错误参与者集合，后续无法可靠修复。

**解决方案**

1. 明确产品语义：无群组账单必须要求选择一个目标好友，或只记录当前用户个人支出。
2. `payerId`、参与者集合、当前用户缺失时禁止保存并展示可恢复错误。
3. 为 iPhone 好友详情补上明确的 Add Expense 入口，并预选当前用户与该好友。
4. 增加测试：无群组、无当前用户、空群组、好友 1 对 1 四条路径。

---

### 3.8 缺少 Required Reason API 隐私清单（新增）

**状态：❌ 未修复（I-18）**

**证据**

- `AppState` 与 `@AppStorage` 使用 `UserDefaults`。
- 源码与实际 Release App 均无 `PrivacyInfo.xcprivacy`。
- Apple 将 `UserDefaults` 列为 Required Reason API；App 自身仅访问本 App 域时通常应声明 `NSPrivacyAccessedAPICategoryUserDefaults` + `CA92.1`。

**后果**

- Apple 自 2024-05-01 起要求提交包声明 Required Reason API；缺失声明可能在 App Store Connect 上传/处理阶段被拒。

**解决方案**

1. 新建并加入 App target 的 `PrivacyInfo.xcprivacy`。
2. 声明 `NSPrivacyAccessedAPICategoryUserDefaults`，理由按实际用途选择；当前代码对应 `CA92.1`。
3. Archive 后用 Xcode Privacy Report 和最终 `.app` 内容复核，而不是只检查源码文件存在。

Apple 官方依据：[Required Reason API](https://developer.apple.com/documentation/BundleResources/describing-use-of-required-reason-api)、[UserDefaults reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)。

---

## 4. P1 严重问题

### 4.1 无账号体系，但文案承诺「邀请加入 Splitwise」

**现象**

- `AddFriendView` 提示可发邮件邀请好友加入，实际只本地 `insert User`。
- 无登录、无多人实时同步、无冲突合并。

**解决方案（二选一）**

| 路线 | 做法 |
|------|------|
| **A. 诚实的本地工具** | 删除「邀请加入」文案；改为「添加本地联系人/参与方」；分享用导出 PDF/链接文本 |
| **B. 真协同产品** | 账号（Sign in with Apple）、云库（CloudKit/自建后端）、邀请链接、权限与冲突解决 |

首发建议 **路线 A**，显著降低范围与审核复杂度。

---

### 4.2 Freemium 与 PRD 不一致

**PRD 承诺**：OCR、Itemized、汇率、导出、图表、债务简化开关为 Pro；免费含广告预留。  
**代码现实**：无 Paywall 门禁、无广告、Mock Pro 默认开。

**解决方案**

1. 实现单一权限源：`FeatureFlag` / `ProEntitlement`。
2. 免费版明确可用：Equal/Exact 分摊、基础群组好友、简单余额。
3. 锁功能时用一致的 `ProBadge` + 订阅 Sheet。
4. 若暂不做广告，**删除**「100% Ad-Free」卖点，避免虚假对比。

---

### 4.3 分摊逻辑与校验不完整

**现象（`AddExpenseView` / `SplitOptionsView`）**

- 切换金额/群组时 `recalculateSplits()` 常重置为 **Equal**，可能覆盖用户在 Options 里配置的 Exact/%/Shares。
- Exact 模式是否强制「分摊合计 = 总额」需在 UI 层严格校验（Save 前）。
- Percentage 需强制合计 100%。
- Itemized OCR 结果与成员归属未完成「逐项指派」闭环时，易产生金额不一致。
- 角分（0.01）舍入在 Equal 模式未做「差额补到最后一人」的稳健策略（部分场景有，需统一）。
- OCR 回调只使用 `title` 与 `totalAmount`，`lineItems` 被完全丢弃；随后仅创建等额 splits，却把方法标成 Itemized。
- 切换分摊方法时直接修改父级 `splitMethod`；若用户下滑取消 Sheet，方法可能已变但 splits 未提交。
- Shares 全部设为 0 时，计算函数直接返回，旧的金额仍可被保存。

**解决方案**

1. 拆分「默认初始化 splits」与「用户已自定义 splits」状态；仅在成员集合变化时重算。
2. Save 按钮 `disabled` 条件绑定校验函数：
   - Equal：自动修复尾差  
   - Exact：`abs(sum - total) < 0.01`  
   - %：`abs(sum% - 100) < 0.01`  
   - Shares：总份数 > 0  
   - Itemized：各项归属完整且合计匹配  
3. 用属性测试 / 单元测试覆盖样例金额（3 人、7 人、奇数分）。

---

### 4.4 循环账单 `RepeatFrequency` 仅为展示字段

**现象**

- 模型有 `weekly/monthly/yearly`，保存后 **无调度、无自动生成后续账单**。

**解决方案**

- 短期：UI 标注「Coming Soon」或移除选项。  
- 中期：用 `BGAppRefresh` / 本地通知 + 打开 App 时补生成，或 EventKit 式规则引擎。

---

### 4.5 结清（Settle Up）不唤起真实支付

**现象**

- 支持记录 Cash/PayPal/Venmo/微信/支付宝等 **记账备注**，但不跳转支付、不验证到账。

**解决方案**

- 文案改为「记录一笔已发生的还款」。  
- 可选：深度链接到 Venmo/PayPal（能力有限且地区差异大）。  
- 切勿宣传「一键支付结清」。

---

### 4.6 OCR 失败静默回落 Mock 小票

**现象**

```swift
// 识别失败 → mockReceiptResult()
// total 为 0 → 写死 48.50
// items 空 → 填入 Trader Joe's 假明细
```

**后果**

- 用户拍真实小票却得到虚假 Trader Joe's 数据，财务风险极高。

**解决方案**

1. 失败时返回明确错误态：「未能识别，请手动填写」。  
2. **禁止**用演示数据污染用户输入。  
3. Demo 按钮与真扫描路径分离，且 Demo 仅 DEBUG 可见。  
4. 识别语言设置 `recognitionLanguages`，支持中英文小票。  
5. 改进解析：TOTAL/合计优先、排除日期电话、置信度阈值。

---

### 4.7 语言切换无效 + 本地化严重不完整

**现象**

- Account 有语言 Picker，但未设置 `AppleLanguages` / 自定义 `Bundle` / `environment(\.locale)`。  
- `Localizable.xcstrings` 共 **208 keys，zh-Hans 与 zh-Hant 各仅 9 条已翻译（4.3%）**；大量 key 为空壳。
- Onboarding、Pro、大量业务字符串硬编码英文。

**解决方案**

1. 短期：语言跟随系统，移除无效 Picker。  
2. 中期：完整翻译 en / zh-Hans / zh-Hant；用 String Catalog 状态跟踪。  
3. 若要做应用内语言：重启生效或 `id` 刷新根视图 + 自定义 localization bundle。  
4. 截图与 ASC 本地化语言与实际可用语言一致。

---

### 4.8 样例数据与「重置 Demo」面向生产用户

**现象**

- 首次进入自动 `SampleData.populateIfEmpty`。  
- Account 有 **Reset Demo Sample Data** 破坏性操作。  
- 用户真实数据会被演示人设（Alex Johnson 等）淹没认知。

**解决方案**

1. 首次引导二选一：「从空白开始」/「加载示例数据」。  
2. Reset 仅 DEBUG 或移到隐藏手势，并二次确认。  
3. 生产默认空白库；示例用单独「Demo Mode」入口。

---

### 4.9 删除账单无动态日志 / 编辑能力弱

**现象**

- `ExpenseDetailView` 可删除，但不写 `ActivityLog.deletedExpense`。  
- 编辑账单能力不完整（若仅有详情只读+删除）。  
- 删除后余额变化无审计。

**解决方案**

- 删除/编辑前后写 Activity；支持撤销（短时）或软删除。  
- 完善 Edit Expense 与分摊再平衡。

---

### 4.10 App Icon 使用 JPEG

**状态：ℹ️ 结论修正，质量项仍未处理（I-14，P3）**

**现象**

- `AppIcon-1024.jpg` 为 1024×1024、无 alpha 的 JPEG。
- Xcode 26.3 的 Debug/Release 构建都成功，资产编译器生成了最终 PNG 图标，因此不能再把它描述为确定的上传阻断。
- Apple 当前 HIG 对光栅 App Icon **推荐 PNG**，主要理由是无损质量与多外观工作流。

**解决方案**

- 仍建议更换为 1024×1024 无损 PNG 或采用 Icon Composer，并检查 Default/Dark/Tinted 外观。
- 该项优先级低于品牌、隐私清单、金额正确性和 IAP；不要把它当成“先修即可过审”的关键项。

---

### 4.11 订阅权益冷启动不会恢复，且任意 IAP 都可解锁 Pro（新增）

**状态：❌ 未修复（I-19）**

- `ProSubscriptionManager.init()` 只拉产品并监听未来交易，没有启动时调用 `updatePurchasedIdentifiers()`。
- 一旦关闭 Mock，已有订阅用户冷启动后可能仍显示非 Pro，直到购买、恢复或收到新交易更新。
- `isPro = !purchasedIdentifiers.isEmpty` 未限定月/年 Pro Product ID；未来任何有效 entitlement 都会解锁 Pro。
- 购买与恢复错误被 `try?` 吞掉，用户没有可靠反馈。

**修复**：启动时遍历 `Transaction.currentEntitlements`；仅接受允许的 Pro ID；保存监听 Task 并明确生命周期；为恢复、待处理、取消、验证失败提供状态与测试。

---

### 4.12 “最少笔数”算法与 Raw Debts 结果不可靠（新增）

**状态：❌ 未修复（I-20）**

- 当前是排序后双指针贪心，不是 Min-Cost Flow，也不保证全局最少笔数。
- 反例：债权 `[3, 2]`、债务 `[2, 2, 1]` 时当前算法产生 4 笔，最优只需 3 笔。
- `computeRawPairwiseDebts()` 仅在已有同向直接债务时扣减 settlement；超额还款、反向债务和净额抵消会被忽略。
- 分摊合计不等于账单金额时，净余额不守恒，而简化循环会静默丢掉未匹配残差。

**修复**：若只承诺“减少转账”则修正文案；若承诺最少笔数，采用可证明/可验证算法并限制群组规模。所有入口先验证 `sum(splits) == amount` 与净额守恒。

---

### 4.13 图表的时间、币种与“个人消费”语义错误（新增）

**状态：❌ 未修复（I-21）**

- 总额/分类/群组图直接累加不同币种。
- “Total Spending” 累加所有群组完整账单，而不是当前用户的 share，容易被理解为个人消费。
- 月度趋势忽略已选 timeframe，始终使用全部 expenses。
- 只用 `MMM` 分组会把不同年份同月合并，并按月份文本字母顺序排序。

**修复**：先定义“个人应付 / 本人垫付 / 群组总支出”指标；统一汇率基准；以 `DateComponents(year, month)` 分组排序；所有图共享同一过滤结果。

---

### 4.14 归档与 Simplify 开关只有展示效果（新增）

**状态：❌ 未修复（I-22）**

- Overall Balance 仍计算全部 groups/expenses，归档群组不会从总体提醒中排除，与设置页文案冲突。
- `group.simplifyDebts` 只显示 badge；Simplify 按钮和算法始终可用，开关没有业务效果。

**修复**：明确归档是否影响总余额，并统一查询；关闭 simplify 时展示 raw pairwise 结果或隐藏简化入口，同时加入状态测试。

---

### 4.15 好友直接记账在 iPhone 上不可达（新增）

**状态：❌ 未修复（I-23）**

- 全局 Add Expense 只存在 iPad Sidebar。
- `FriendDetailView` 声明了 `showingAddExpense`，但没有按钮或 Sheet 使用它。
- 因此 iPhone 用户无法从好友页创建 1 对 1 账单；即使从无群组 Add Expense 进入，也会触发 I-17。

**修复**：好友详情提供 Add Expense，预选当前用户与好友；把“参与者选择”与“群组选择”建模为明确状态。

---

### 4.16 持久化、重置与导出错误被静默吞掉（新增）

**状态：❌ 未修复（I-24）**

- 保存、删除、恢复购买、图片加载、文件写入大量使用 `try?`；失败后仍 dismiss 或打开分享页。
- Reset Demo 无二次确认，且按模型分五次删除；部分失败会留下孤儿数据。
- `populateIfEmpty` 只看 User 是否为空，无法修复“有用户但没有当前用户”的损坏库。

**修复**：为 mutation 建立统一错误处理和用户反馈；Reset 使用确认与可恢复策略；保存失败不关闭页面；增加数据完整性检查/修复入口。

---

## 5. P2 重要问题

### 5.1 无网络同步与备份

- 卸载/换机数据全丢。  
- **方案**：iCloud（SwiftData + CloudKit）、导出备份 JSON、或「导出全部 CSV」。

### 5.2 无单元测试 / UI 测试

- 债务算法、分摊舍入、结算符号最需要测试。  
- **方案**：为 `DebtSimplifier`、`CurrencyFormatter`、`Split` 校验加 XCTest；关键 CI。

### 5.3 `fatalError` 初始化 ModelContainer

- 迁移失败直接崩溃。  
- **方案**：错误 UI + 重建/迁移策略；SwiftData 版本迁移计划。

### 5.4 PDF 导出分页与大数据（复评升为 P1）

- **状态：❌ 未修复，并比初评更严重（I-16）**
- PDF 明确使用 `expenses.prefix(30)`，第 31 条起被静默丢弃；`settlements` 参数完全未绘制。
- 换页后不重绘标题/表头，摘要又直接混加多币种。
- CSV 未处理以 `=`, `+`, `-`, `@` 开头的用户输入，导入表格软件时存在公式注入风险；姓名的引号/换行转义也不完整。
- **方案**：完整分页、重复表头、包含 settlements、导出前币种策略；对 CSV 所有字段做 RFC 4180 转义与公式前缀防护，并测试 0/30/31/1000 条。

### 5.5 好友/群组成员管理

- 移除成员、转让「当前用户」、合并重复好友等缺失。  
- 成员改名后历史 `ExpenseSplit.userName` 可能过期（冗余字段）。  
- **方案**：展示时以 `userId` 查表；历史快照可选保留。

### 5.6 通知与安全开关无效

- 见 3.5。实现或删除。

### 5.7 iPad 体验

- 有 `NavigationSplitView`，但全局加账单 sheet、多栏深度链接、键盘与指针优化不足。  
- **方案**：按 size class 做双栏详情、列宽、快捷键。

### 5.8 无障碍与动态字体

- 部分固定字号、图标按钮缺 `accessibilityLabel`。  
- **方案**：Dynamic Type、VoiceOver 标签、对比度检查。

### 5.9 性能

- 列表中反复全量 `filter` 全库 expenses 算余额，数据量大时卡顿。  
- **方案**：按 `groupId` 索引查询、缓存净额、后台计算。

### 5.10 工程元数据

- `SWIFT_VERSION: "5.0"` 与 README「Swift 6」不一致。  
- Debug/Release 构建成功，但订阅监听产生“无效 await / Task 未使用”警告，违反 PRD 的零警告目标。
- 强制展示 1.5 秒 Launch Screen，与 PRD “启动时间 < 1.0s”自相矛盾。
- **方案**：统一 Swift 版本声明；持有交易监听 Task；去掉人为启动延迟；PrivacyInfo 见 P0 I-18。

### 5.11 构建通过，但不存在可执行测试基线

- **状态：❌ 未修复（I-25）**
- Debug/Release 模拟器构建均成功，说明源码与资产在 Xcode 26.3 下可编译。
- `xcodebuild test` 返回 “Scheme SplitwiseApp is not currently configured for the test action”；当前没有 Test target，而不是“测试为 0 个但通过”。
- **方案**：新增 Unit Test 与 UI Test target；先覆盖身份解析、分摊不变量、多币种、settlement 正负号、订阅 entitlement 和 3 分钟审核主路径。

---

## 6. P3 优化建议

1. **空状态插画与引导**：新用户无示例时的任务引导（创建群组 → 加一笔 → 看余额）。  
2. **搜索**：账单、好友、群组全文搜索。  
3. **标签/自定义分类**：扩展 `ExpenseCategory`。  
4. **小组件 / 快捷指令**：查看「我欠多少」。  
5. **Haptic / 成功动效**：保存账单与结清反馈。  
6. **债务简化可视化**：简单图布局（节点=成员）。  
7. **多付款人**：一笔账单多人垫付（模型 `paidShare` 已预留，引擎未完整用）。  
8. **主题**：品牌色 token 已有，可扩展自定义强调色。

---

## 7. 架构与产品定位建议

### 7.1 当前真实定位

```
本地单机 AA 记账 Demo
  ├─ SwiftData 持久化
  ├─ 分摊 UI + 简化债务算法
  ├─ Vision OCR 试验性
  └─ StoreKit 外壳（未产品化）
```

### 7.2 建议 MVP 边界（可上架）

**必须有**

- 正确的「当前用户」与余额  
- 群组/好友/等额与精确分摊  
- 结清记录  
- 原创品牌与隐私政策  
- 稳定无崩溃主路径  

**可延后**

- 云同步、真邀请、真支付  
- 实时汇率、高级 OCR  
- 订阅（可先免费上架，或上架后再开 IAP）  

**若保留订阅**

- 必须有真实可验证的 Pro 权益差异  

---

## 8. 推荐修复路线图

### Phase 0（1–2 天）— 止血

- [x] 修复 `currentUserId` 绑定  
- [ ] 修复 No Group/好友 1 对 1 参与者模型，禁止随机 payer 与空 splits
- [ ] 关闭默认 Mock Pro；隐藏 DEBUG 开关  
- [ ] 产品改名评估与 Bundle ID 规划  
- [ ] OCR 失败禁止 Mock 污染  
- [ ] 删除或实现 Face ID / 相机 / 推送声明  
- [ ] 添加 `PrivacyInfo.xcprivacy` 并声明 UserDefaults Required Reason

### Phase 1（3–5 天）— 可演示正确性

- [ ] 多币种统一换算进余额引擎  
- [ ] 分摊校验与尾差  
- [ ] 让 Itemized 真正接收 OCR items 并支持逐项归属
- [ ] 修复订阅冷启动权益与 Product ID 白名单
- [ ] 修正文案或更换可证明的债务最少笔数算法
- [ ] 修复图表 timeframe / 年月排序 / 指标口径
- [ ] 样例数据可选  
- [ ] 基础单元测试（DebtSimplifier + Split）  
- [ ] 导出完整性（31+ 条、settlements、CSV 注入）

### Phase 2（1 周）— 合规可提审

- [ ] 隐私政策 / 条款网页 + 应用内链接  
- [ ] 订阅动态价格与完整披露（若启用 IAP）  
- [ ] Pro 门禁与恢复购买验收  
- [ ] 本地化至少 en + 一个目标市场语言  
- [ ] ASC 截图、审核备注、演示账号说明（本地 App 可说明无需账号）  

### Phase 3（后续）— 产品化

- [ ] 备份/iCloud  
- [ ] 编辑账单完善  
- [ ] 性能与无障碍  
- [ ] 可选账号体系  

---

## 9. 问题清单速查表

| ID | 状态 | 级别 | 问题 | 关键证据 |
|----|------|------|------|----------|
| I-01 | ✅ | P0 | currentUserId 随机导致余额错误 | 已持久化 + `resolveCurrentUser` 与 `isCurrentUser` 对齐 |
| I-02 | ❌ | P0 | 商标/品牌 Splitwise | Release 二进制、Info、Bundle ID、IAP ID |
| I-03 | ❌ | P0 | isMockPro 默认 true | `ProSubscriptionManager.swift:18` |
| I-04 | ❌ | P0 | 无隐私政策/条款可点击链接、价格写死 | `SplitwiseProView.swift` |
| I-05 | ❌ | P0 | Camera/Face ID/Push 声明与实现不符 | `Info.plist`, `AccountView.swift` |
| I-06 | ❌ | P0 | 多币种未换算 | `DebtSimplifier.swift`, `ChartsView.swift` |
| I-07 | ❌ | P1 | 邀请/协同虚假承诺 | `AddFriendView.swift` |
| I-08 | ❌ | P1 | Pro 无门禁 | 全 Views |
| I-09 | ❌ | P1 | 分摊覆盖、无校验、Itemized 丢条目 | `AddExpenseView.swift:187-224`, `SplitOptionsView.swift` |
| I-10 | ❌ | P1 | 循环账单仅存字段 | `Expense.swift`, `AddExpenseView.swift` |
| I-11 | ❌ | P1 | OCR 失败写入 Mock 数据 | `ReceiptScannerService.swift` |
| I-12 | ❌ | P1 | 语言切换无效；中/繁各 9/208 | `Localizable.xcstrings`, `AppState.swift` |
| I-13 | ❌ | P1 | 强制样例数据、危险 Reset Demo | `MainView.swift`, `AccountView.swift` |
| I-14 | ℹ️ | P3 | JPEG 图标为有损质量项，不是已证实阻断 | 1024×1024、无 alpha；两配置构建成功 |
| I-15 | ❌ | P2 | 无测试、迁移与容器失败恢复 | 无 Test target；`fatalError` |
| I-16 | ❌ | P1 | PDF 截断/漏 settlement、CSV 注入 | `ExportManager.swift:105` |
| I-17 | ❌ | P0 | No Group 错分给全部用户/可保存孤儿 payer | `AddExpenseView.swift:38-43, 203` |
| I-18 | ❌ | P0 | 缺少 Required Reason API 隐私清单 | Release App 无 `PrivacyInfo.xcprivacy` |
| I-19 | ❌ | P1 | 订阅冷启动不恢复、任意 entitlement 解锁 | `ProSubscriptionManager.swift:24-29, 109-110` |
| I-20 | ❌ | P1 | 债务算法不保证最少笔数，Raw 结算不完整 | `DebtSimplifier.swift` |
| I-21 | ❌ | P1 | 图表 timeframe/年月/币种/指标口径错误 | `ChartsView.swift:51-223` |
| I-22 | ❌ | P1 | Archived 与 simplify 开关不影响行为 | `GroupListView.swift`, `GroupDetailView.swift` |
| I-23 | ❌ | P1 | iPhone 好友直接记账不可达 | `FriendDetailView.swift` |
| I-24 | ❌ | P1 | 持久化/重置/导出错误静默吞掉 | 全项目至少 12 处 mutation `try?` |
| I-25 | ❌ | P2 | 可构建但有警告且无可执行测试基线 | Xcode Debug/Release build；test action 缺失 |

---

## 10. 结论

该项目作为 **学习型 / 原型型** 实现已经具备可观的界面广度，但在 **身份模型、参与者集合、金额正确性、付费真实性、品牌合规、隐私合规** 六个维度存在上线阻断项。

优先顺序建议：

1. **正确性**（用户 ID + No Group 参与者 + 多币种 + 分摊校验）
2. **诚实性**（文案、Mock、权限、Demo 数据）  
3. **合规性**（改名、隐私清单、隐私政策、IAP）
4. **完成度**（本地化、测试、备份）  

完成 Phase 0–2 后，再评估 App Store 提交；单独的审核拒绝风险清单见：  
**[APP_STORE_REVIEW_RISKS.md](./APP_STORE_REVIEW_RISKS.md)**。
