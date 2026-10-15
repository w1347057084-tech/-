#!/usr/bin/env bash
#
# 在 macOS 上构建「元素周期表查询与背诵」的未签名 iOS 安装包（.ipa）。
#
# 用法：
#   bash tool/build_unsigned_ipa.sh            # release（默认）
#   bash tool/build_unsigned_ipa.sh profile
#   bash tool/build_unsigned_ipa.sh debug
#
# 产物：build/ios/ipa_unsigned/periodic_table_study-<mode>.ipa
#
# 未签名 IPA 不能直接安装到 iPhone/iPad，需要用 Xcode 或 Sideloadly、
# AltStore 等工具以你自己的 Apple ID 重新签名后再安装。

set -euo pipefail

MODE="${1:-release}"
case "$MODE" in
  debug | profile | release) ;;
  *)
    echo "用法: bash tool/build_unsigned_ipa.sh [debug|profile|release]" >&2
    exit 2
    ;;
esac

HOST_OS="$(uname -s 2>/dev/null || echo unknown)"
if [[ "$HOST_OS" != "Darwin" ]]; then
  echo "错误：iOS 构建需要 macOS 与 Xcode，当前系统为 ${HOST_OS}。" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "错误：未找到 flutter，请先把 Flutter SDK 的 bin 目录加入 PATH。" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "错误：未找到 xcodebuild，请安装 Xcode 并执行 sudo xcode-select -s /Applications/Xcode.app" >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build ios --$MODE --no-codesign"
flutter build ios --"$MODE" --no-codesign

APP_PATH="build/ios/iphoneos/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "错误：未找到 $APP_PATH，构建未产出可打包的 .app。" >&2
  exit 1
fi

OUT_DIR="build/ios/ipa_unsigned"
IPA_PATH="$OUT_DIR/periodic_table_study-${MODE}.ipa"
PAYLOAD_DIR="$(mktemp -d)"
trap 'rm -rf "$PAYLOAD_DIR"' EXIT

echo "==> 打包未签名 IPA"
mkdir -p "$PAYLOAD_DIR/Payload"
cp -R "$APP_PATH" "$PAYLOAD_DIR/Payload/"
mkdir -p "$OUT_DIR"
rm -f "$IPA_PATH"
(cd "$PAYLOAD_DIR" && zip -qry "$PROJECT_DIR/$IPA_PATH" Payload)

echo
echo "完成：$IPA_PATH"
echo "大小：$(du -h "$IPA_PATH" | cut -f1)"
echo
echo "该 IPA 未签名，安装前需要重新签名："
echo "  - Xcode 打开 ios/Runner.xcworkspace，配置自己的 Team 后直接运行到真机；或"
echo "  - 用 Sideloadly / AltStore 载入该 IPA，以免费 Apple ID 签名后安装。"
