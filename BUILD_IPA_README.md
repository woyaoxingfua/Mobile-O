# Mobile-O 未签名 IPA 构建指南

本指南说明如何使用 GitHub Actions 在云端编译 Mobile-O 的未签名 IPA 文件（支持 iOS 18.0+）。

## 📁 工作流文件说明

仓库包含以下 GitHub Actions 工作流：

| 工作流文件 | 说明 |
|-----------|------|
| `build-ios.yml` | **主要工作流**，使用自签名证书确保 Frameworks 正确嵌入 |
| `build.yml` | 完整版本，包含详细日志和验证 |
| `build-debug.yml` | Debug 配置，包含更多调试信息 |

## 🚀 使用方法

### 方法一：自动触发（推送到主分支）

当代码推送到 `main` 或 `master` 分支时，会自动触发构建：

```bash
git add .
git commit -m "Build unsigned IPA"
git push origin main
```

### 方法二：手动触发

1. 打开 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择 **Build iOS IPA** 工作流
4. 点击 **Run workflow**
5. 点击 **Run workflow**

### 方法三：Pull Request 触发

提交 Pull Request 到 `main` 或 `master` 分支时会自动触发构建。

## 📋 构建输出

构建完成后，可在以下位置下载 IPA 文件：

1. GitHub Actions 页面 → 构建运行 → Artifacts
2. 文件名称：`MobileO-unsigned.ipa`

## 🔧 技术细节

### 关键修复说明

#### 问题 1：Frameworks 未嵌入导致功能异常

**原因**：之前的构建使用了 `CODE_SIGNING_ALLOWED=NO`，这会导致 Xcode 跳过 "Embed Frameworks" 构建阶段，导致：
- Video.framework 未嵌入
- FastVLM.framework 未嵌入
- Swift Package Dependencies 链接不正确

**解决方案**：使用自签名证书 + `CODE_SIGNING_ALLOWED=YES`

```bash
# 1. 创建自签名证书
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=MobileO Self Signed"

# 2. 使用证书进行构建
xcodebuild archive \
  CODE_SIGN_STYLE="Manual" \
  CODE_SIGN_IDENTITY="MobileO Self Signed" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES

# 3. 构建完成后移除签名
codesign --remove-signature Payload/MobileO.app/MobileO
```

#### 问题 2：IPA 文件过大

**原因**：
- `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=YES` 会嵌入 Swift 标准库
- 未启用编译优化和死代码剥离
- 包含不必要的架构（如模拟器架构）

**解决方案**：
```bash
# 禁用 Swift 标准库嵌入（iOS 12.2+ 系统已包含）
ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

# 只构建 arm64 架构
ONLY_ACTIVE_ARCH=YES
ARCHS=arm64

# 启用编译优化和代码剥离
STRIP_INSTALLED_PRODUCT=YES
DEPLOYMENT_POSTPROCESSING=YES
```

### 修改的配置

构建工作流会自动修改以下 Xcode 项目配置：

| 配置项 | 原值 | 修改后 |
|-------|------|--------|
| `IPHONEOS_DEPLOYMENT_TARGET` | 18.2 / 18.0 | **18.0** |
| `CODE_SIGN_STYLE` | Automatic | **Manual** |
| `DEVELOPMENT_TEAM` | Q3GRH2LZ7S | **空** |
| `CODE_SIGN_IDENTITY` | 自动设置 | **MobileO Self Signed** |
| `CODE_SIGNING_ALLOWED` | - | **YES** (构建时) |
| `ONLY_ACTIVE_ARCH` | NO | **YES** |
| `ARCHS` | - | **arm64** |

### 构建设置

- **目标架构**: arm64 (iPhone)
- **目标系统**: iOS 18.0+
- **签名状态**: 未签名（Unsigned）
- **Xcode 版本**: 16.0+
- **运行环境**: macOS 15 (GitHub Actions)

## 📱 安装方法

由于 IPA 文件未签名，需要使用以下方式安装：

### 1. TrollStore（推荐）

- 无需 Apple ID
- 无需签名
- 永久安装
- 需要设备已安装 TrollStore

步骤：
1. 将 IPA 文件传输到 iPhone
2. 使用 TrollStore 打开并安装

### 2. AltStore

- 使用个人 Apple ID 签名
- 每 7 天需要重新签名
- 免费

步骤：
1. 安装 AltStore 到电脑和 iPhone
2. 在 AltStore 中添加 IPA 文件
3. 使用 Apple ID 签名安装

### 3. Sideloadly

- 使用个人 Apple ID 签名
- 单次安装

步骤：
1. 下载 Sideloadly
2. 连接 iPhone 到电脑
3. 选择 IPA 文件和 Apple ID
4. 开始安装

### 4. LiveContainer

- 在已越狱或使用 TrollStore 的设备上运行
- 无需重新签名

步骤：
1. 确保 LiveContainer 已安装
2. 导入 IPA 文件到 LiveContainer
3. 从 LiveContainer 启动应用

### 5. 个人开发者证书签名

如果你有付费的 Apple Developer 账号（$99/年）：

```bash
# 使用 ios-deploy 安装
ios-deploy --bundle Payload/MobileO.app

# 或使用 Xcode 直接安装
```

## ⚠️ 注意事项

1. **设备要求**: 需要 iPhone 15 或更高版本（应用需要 CoreML 和 Metal 支持）
2. **首次启动**: 应用首次启动后会下载模型文件（约 3.6GB）
3. **存储空间**: 确保设备有至少 5GB 可用空间
4. **网络**: 首次下载模型需要 WiFi 连接
5. **代码签名**: 构建时使用自签名证书确保 Frameworks 正确嵌入，但最终 IPA 是无签名的

## 🐛 故障排除

### 构建失败

如果 GitHub Actions 构建失败：

1. 检查构建日志中的错误信息
2. 确保所有 Swift Package Dependencies 可以正常解析
3. 检查 Xcode 版本兼容性
4. 检查 Frameworks 是否正确嵌入（查看 diagnostics/app-diagnostics.txt）

### 安装失败

如果安装到设备失败：

1. 确认设备是 iPhone 15 或更高版本
2. 检查 iOS 版本是否为 18.0 或更高
3. 尝试使用不同的安装工具（TrollStore/AltStore/Sideloadly/LiveContainer）

### 应用崩溃

如果应用启动后崩溃：

1. 检查设备是否有足够的存储空间
2. 确认模型文件下载完成
3. 查看设备的崩溃日志
4. 确认 Frameworks 是否正确嵌入（检查崩溃日志中是否有 "Library not loaded" 错误）

### Frameworks 未嵌入的错误

如果看到类似错误：
```
dyld: Library not loaded: @rpath/Video.framework/Video
```

这表示 Frameworks 没有正确嵌入。请使用最新版本的工作流文件（已修复此问题）。

## 📚 相关链接

- [Mobile-O 原仓库](https://github.com/woyaoxingfua/Mobile-O)
- [TrollStore 安装指南](https://github.com/opa334/TrollStore)
- [AltStore 官网](https://altstore.io/)
- [LiveContainer 指南](./LIVECONTAINER_GUIDE.md)

## 📝 许可

构建的 IPA 文件遵循原仓库的许可协议（CC BY-NC-SA 4.0）。仅供研究和非商业使用。
