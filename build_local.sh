#!/bin/bash

# 本地构建脚本 - 在 Mac 上运行
set -e

cd Mobile-O-App/app

# 1. 修改项目配置
echo "=== 修改项目配置 ==="
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18.2;/IPHONEOS_DEPLOYMENT_TARGET = 18.0;/g' MobileO.xcodeproj/project.pbxproj
sed -i '' 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Manual;/g' MobileO.xcodeproj/project.pbxproj
sed -i '' 's/DEVELOPMENT_TEAM = Q3GRH2LZ7S;/DEVELOPMENT_TEAM = "";/g' MobileO.xcodeproj/project.pbxproj

# 2. 构建 Archive
echo "=== 构建 Archive ==="
xcodebuild clean archive \
  -project MobileO.xcodeproj \
  -scheme MobileO \
  -configuration Release \
  -archivePath MobileO.xcarchive \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=18.0 \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS=arm64 \
  SWIFT_STRICT_CONCURRENCY=minimal \
  OTHER_SWIFT_FLAGS="-strict-concurrency=minimal" \
  ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=YES

# 3. 打包 IPA
echo "=== 打包 IPA ==="
rm -rf Payload
mkdir -p Payload
cp -R MobileO.xcarchive/Products/Applications/MobileO.app Payload/
rm -rf Payload/MobileO.app/_CodeSignature
rm -f Payload/MobileO.app/embedded.mobileprovision 2>/dev/null || true

# 验证
ls -la Payload/MobileO.app/
echo "=== Frameworks ==="
ls -la Payload/MobileO.app/Frameworks/ 2>/dev/null | head -20

zip -qr MobileO_LiveContainer.ipa Payload
echo "=== 构建成功 ==="
ls -lh MobileO_LiveContainer.ipa
