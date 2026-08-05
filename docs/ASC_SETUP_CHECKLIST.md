# BillNest App Store Connect 创建与提审清单

## 当前状态（2026-08-05）

| 项 | 状态 |
|----|------|
| Bundle ID `app.billnest.ios` | ✅ 已存在（`Y8FZQWSK28`） |
| Capabilities | ✅ In-App Purchase + iCloud（CloudKit / `XCODE_5`） |
| ASC App 记录 | ❌ **未创建** — API Key 无 CREATE 权限，需 `asc web` 登录 |
| 本地元数据包 | ✅ `asc-metadata/`（en-US / zh-Hans / zh-Hant / ja / ko） |
| 构建上传 | ❌ 待 Archive / Transporter |
| 截图 | ❌ 待补（提交阻断项） |
| 订阅商品 | ❌ 待 App 创建后配置 |

## 阻塞原因

App Store Connect **官方 API Key 不允许创建 App**（仅 GET/UPDATE）。创建必须：

```bash
asc web auth login --apple-id "你的AppleID邮箱"
# 按提示输入密码与双重认证码

asc web apps create \
  --name "BillNest" \
  --bundle-id "app.billnest.ios" \
  --sku "BILLNEST-IOS-2026" \
  --primary-locale "en-US" \
  --platform IOS \
  --version "1.0"
```

登录成功后把终端输出的 **App ID** 发我，即可继续自动填写：

1. 类目：Finance + Productivity  
2. `asc metadata apply` 推送五语言元数据  
3. 全球可用性 + 免费标价  
4. 年龄分级 / 加密声明  
5. 订阅组 `BillNest Pro` + `app.billnest.pro.monthly` / `yearly`  
6. 审核备注 / 隐私营养标签  
7.（你上传构建与截图后）提交审核  

## 预备元数据摘要（en-US）

- **Name**: BillNest  
- **Subtitle**: Split bills & settle up  
- **Support**: https://github.com/aSynch1889/BillNest-Legal/issues  
- **Privacy**: https://asynch1889.github.io/BillNest-Legal/privacy.html  
- **Terms**: https://asynch1889.github.io/BillNest-Legal/terms.html  
- **SKU**: BILLNEST-IOS-2026  

## 审核备注（英文，创建版本后可写入 ASC）

见 `docs/APP_STORE_SUBMISSION_NOTES.md`。要点：无需登录账号；可选 Load Sample Data；Pro 订阅可测；iCloud 需同 Apple ID；结清不转账；静态汇率；循环账单 Coming Soon。
