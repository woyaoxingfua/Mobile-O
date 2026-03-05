# Mobile-O 未签名 IPA 构建指南

本指南说明如何使用 GitHub Actions 在云端编译 Mobile-O 的未签名 IPA 文件（支持 iOS 18.1）。

## 📁 工作流文件说明

仓库包含以下 GitHub Actions 工作流：

| 工作流文件 | 说明 |
|-----------|------|
| `build-unsigned-ipa.yml` | 简单版本，快速构建 |
| `build_unsigned_ipa.yml` | 完整版本，包含详细日志和验证 |
| `build_unsigned_ipa_simple.yml` | 手动触发，可选择 Debug/Release |

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
3. 选择 **Build Unsigned IPA Simple (iOS 18.1)** 工作流
4. 点击 **Run workflow**
5. 选择构建配置（Release 或 Debug）
6. 点击 **Run workflow**

### 方法三：Pull Request 触发

提交 Pull Request 到 `main` 或 `master` 分支时会自动触发构建。

## 📋 构建输出

构建完成后，可在以下位置下载 IPA 文件：

1. GitHub Actions 页面 → 构建运行 → Artifacts
2. 文件名称：`MobileO-Unsigned-iOS18.1.ipa`

## 🔧 技术细节

### 修改的配置

构建工作流会自动修改以下 Xcode 项目配置：

| 配置项 | 原值 | 修改后 |
|-------|------|--------|
| `IPHONEOS_DEPLOYMENT_TARGET` | 18.2 / 18.0 | **18.1** |
| `CODE_SIGN_STYLE` | Automatic | **Manual** |
| `DEVELOPMENT_TEAM` | Q3GRH2LZ7S | **空** |
| `CODE_SIGN_IDENTITY` | 自动设置 | **空** |

### 构建设置

- **目标架构**: arm64 (iPhone)
- **目标系统**: iOS 18.1+
- **签名状态**: 未签名（Unsigned）
- **Xcode 版本**: 16.0
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

### 4. 个人开发者证书签名

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

## 🐛 故障排除

### 构建失败

如果 GitHub Actions 构建失败：

1. 检查构建日志中的错误信息
2. 确保所有 Swift Package Dependencies 可以正常解析
3. 检查 Xcode 版本兼容性

### 安装失败

如果安装到设备失败：

1. 确认设备是 iPhone 15 或更高版本
2. 检查 iOS 版本是否为 18.1 或更高
3. 尝试使用不同的安装工具（TrollStore/AltStore/Sideloadly）

### 应用崩溃

如果应用启动后崩溃：

1. 检查设备是否有足够的存储空间
2. 确认模型文件下载完成
3. 查看设备的崩溃日志

## 📚 相关链接

- [Mobile-O 原仓库](https://github.com/woyaoxingfua/Mobile-O)
- [TrollStore 安装指南](https://github.com/opa334/TrollStore)
- [AltStore 官网](https://altstore.io/)

## 📝 许可

构建的 IPA 文件遵循原仓库的许可协议（CC BY-NC-SA 4.0）。仅供研究和非商业使用。
