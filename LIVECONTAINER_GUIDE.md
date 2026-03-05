# LiveContainer 安装指南

本指南说明如何在 LiveContainer 中安装和运行 Mobile-O。

## ⚠️ 已知限制

Mobile-O 使用了一些 LiveContainer 可能不完全支持的框架：
- **MLX 框架**: 需要 Metal 和特定的机器学习功能
- **CoreML**: 模型编译和推理
- **Camera**: 相机访问

## 📱 安装步骤

### 1. 下载 IPA
从 GitHub Actions 下载 `MobileO-LiveContainer-iOS18.ipa`

### 2. 安装到 LiveContainer
1. 打开 LiveContainer
2. 点击 "+" 或 "Add App"
3. 选择下载的 IPA 文件
4. 等待安装完成

### 3. 常见问题解决

#### 错误: `Bad file descriptor` 或 `(null)`
**可能原因:**
- Swift 运行时未正确加载
- Frameworks 加载失败

**尝试解决:**
1. 确保 iOS 版本 >= 18.0
2. 重启 LiveContainer
3. 尝试使用 JIT 模式（如果有）

#### 错误: App 闪退
**可能原因:**
- MLX 框架与 LiveContainer 的沙箱冲突
- Metal 功能无法正常工作

**可能无法解决**, 因为 Mobile-O 依赖 Metal 和 MLX 进行 AI 推理。

#### 错误: 模型下载失败
**解决:**
1. 检查 LiveContainer 的网络权限
2. 确保应用有互联网访问权限

## 🔧 技术要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | 18.0+ |
| LiveContainer | 最新版本 |
| 设备 | iPhone 15+（A17 Pro 或更高）|

## ⚡ 替代方案

如果 LiveContainer 无法运行，尝试：

### 1. TrollStore (推荐)
- 无需签名
- 更好的系统权限
- 支持 Metal 和 MLX

### 2. 侧载 (Sideloadly/AltStore)
- 使用个人 Apple ID 签名
- 需要每周重新签名

### 3. 企业签名
- 付费服务
- 稳定运行

## 🐛 调试信息

如果安装失败，请收集以下信息：
1. LiveContainer 版本号
2. iOS 精确版本（如 18.1.1）
3. 设备型号（如 iPhone 15 Pro）
4. 完整的错误日志

## 📋 状态

当前 GitHub Actions 构建的 IPA 包含：
- ✅ 完整的 Frameworks
- ✅ 嵌入的 Swift 标准库
- ✅ 清理的签名文件
- ⚠️ MLX 兼容性待验证

**注意**: Mobile-O 是一款资源密集型 AI 应用，即使在正常安装环境下也需要 iPhone 15 Pro 以上设备才能流畅运行。LiveContainer 的沙箱环境可能限制其性能。
