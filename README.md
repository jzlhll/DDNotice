# Slice / DDNotice

一个自己使用的 macOS 倒计时小工具，方便掌握时间。支持自定义提醒文字、声音提醒和菜单栏倒计时。

![Slice 计时工具](https://upload-images.jianshu.io/upload_images/1106214-2ef452181b188f6b.png)

## macOS 兼容性

本次更新适配较新的 macOS 和 Xcode，使用 Swift 5 语言模式，保留原有 AppKit / Storyboard 界面。

- 支持 Intel 和 Apple Silicon，Release 包包含 `x86_64`、`arm64` 两种架构。
- 面向 macOS 11 及以上版本使用，已使用本机 Xcode 26.5 / macOS 26.5 SDK 编译验证。
- 工程最低部署目标为 macOS 10.13；旧系统和不同 macOS 版本仍需实机确认。
- 更新菜单栏、字符串和设置保存相关 API，修复暂停/恢复、取消计时和重复提醒问题。
- 已移除不再使用的 CocoaPods / SnapKit，无需安装第三方依赖。

## 编译和验证

打开 `Slice.xcodeproj`，选择共享的 `Slice` Scheme 即可运行。默认使用本地 ad-hoc 签名；分发时可设置自己的开发团队。

```bash
xcodebuild -project "$PWD/Slice.xcodeproj" -scheme Slice \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath /tmp/DDNotice-DerivedData \
  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO build

bash Tests/run-timer-regressions.sh
```

计时器自动检查覆盖暂停/恢复、单次结束通知、取消、重启和无效输入。菜单栏交互、窗口显示及声音播放仍需桌面实测。

本地压缩包采用 ad-hoc 签名，未经过 Apple 公证。
