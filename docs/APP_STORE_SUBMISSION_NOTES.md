# BillNest / SplitwiseApp — App Store Connect 提审备注

> 更新日期：2026-08-05  
> 用途：粘贴到 ASC「审核备注」；配合截图与隐私/条款 URL 使用。

## 产品定位

本地优先的 AA / 分摊记账工具。无账号、无云同步、无需演示账号。

## 审核账号

**不需要登录。** 安装后可：

1. Onboarding 选择 **Start Blank** 或 **Load Sample Data**
2. 创建群组 / 添加本地联系人 → 记一笔 Equal 分摊 → 查看余额 → Settle Up 记录还款

## 订阅（若启用 IAP）

- Product IDs（当前工程）：`app.billnest.pro.monthly` / `app.billnest.pro.yearly`
- Bundle ID：`app.billnest.ios`；显示名：**BillNest**
- 恢复购买：订阅页 **Restore Purchases**
- 法律链接：
  - Privacy：https://asynch1889.github.io/BillNest-Legal/privacy.html
  - Terms：https://asynch1889.github.io/BillNest-Legal/terms.html
  - 中文：`privacy-zh.html` / `terms-zh.html`
- Pro 门禁：OCR、Itemized、导出、高级图表、Simplify；免费可用基础分摊与记账
- DEBUG 构建才有 Mock Pro 开关；Release 恒关闭

## 权限

- 仅相册（选小票图）；无相机 / Face ID / 推送
- `PrivacyInfo.xcprivacy` 声明 UserDefaults `CA92.1`
- `ITSAppUsesNonExemptEncryption = false`

## 截图建议（审核员路径）

1. 群组列表 + Overall Balance  
2. 群组详情余额与账单  
3. 添加账单（Equal）  
4. Analytics（Pro）或 Paywall  
5. Account / 法律入口  

## 已知限制（诚实披露）

- 汇率为应用内静态表，非实时牌价  
- 债务简化为启发式「减少转账」，非全局最少笔数证明  
- 结清仅为还款记录，不发起真实支付  
- 循环账单尚未自动生成（Coming Soon）
