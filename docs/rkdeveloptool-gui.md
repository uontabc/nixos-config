# RKDevelopTool GUI

使用上游 **5.7.1 AppImage**，由 Nix 下载、校验 SHA-256 并封装运行环境；支持
`x86_64-linux` 和 `aarch64-linux`。AppImage 已经包含 `rkdeveloptool`，不需要另外安装后端。

## 构建和启动

在配置仓库根目录执行：

```sh
nix build .#rkdeveloptool-gui
nix run .#rkdeveloptool-gui
```

这两个命令不会安装系统级 USB 规则。桌面模块已将应用加入
`environment.systemPackages`，将包内的规则加入 `services.udev.packages`。
在 WorkTable 上应用配置：

```sh
sudo nixos-rebuild switch --flake /home/uontabc/nixos-config#NixOS-WorkTable --no-write-lock-file
```

应用后可从启动器打开 **RKDevelopTool GUI**，或执行 `rkdeveloptool-gui`。
首次应用 USB 规则后，拔插一次开发板。

## Tokyo Night 主题覆盖

- `overlays/rkdeveloptool-gui/theme.nix` 从 `lib/theme.nix` 读取共享颜色、强调色和字体，
  生成应用专用 QSS；不维护另一份硬编码色板。
- 启动包装器自动传入 `-stylesheet`，覆盖窗口、分组、页签、按钮、输入框、表格、日志、
  菜单、弹窗、进度条、复选框和滚动条的样式。主操作使用蓝色，写入/备份使用绿色，
  警告使用黄色，擦除等危险操作保留红色；禁用状态单独处理。
- 应用自己的主题管理器会重设 Qt 调色板，但不会移除这份 QSS。建议将应用内主题设为
  Dark、控件风格设为 Fusion；不需要每次手动加载样式。
- 保留应用字体大小设置，不通过 QSS 固定字号；字体族跟随共享主题。
- 清理继承的 Qt 插件/QML 搜索路径，避免宿主 Qt 和 AppImage 内 Qt 的 ABI 冲突。
  不将系统的 qt5ct/qt6ct 或 Kvantum 插件硬塞进 AppImage。
- 主题只影响这个应用，不修改全局 Qt 配置，也不覆盖固件路径、历史记录或其他应用设置。

## USB 权限与安全

规则文件为 `70-rkdeveloptool-gui.rules`，匹配 Rockchip 厂商 ID `2207`，并使用
`TAG+="uaccess"` 给当前本地活动会话授权。必须在 `73-seat-late.rules` 之前运行，
因此不要把它改写成默认在 `99-local.rules` 执行的 `services.udev.extraRules`。

不需要用 root 启动 GUI，不添加 `MODE="0666"`，也不授予整个 USB 总线的访问权限。
启动测试只检查窗口、后端版本和设备枚举；刷写、擦除、加载 Loader、重置开发板均需另行确认。

仅运行 `nix run`、尚未应用桌面配置时，Qt 可能提示 portal 找不到应用的 desktop ID；
应用系统配置、安装桌面入口后再检查 portal 集成。

## 更新与目录约定

本仓库的本地包配方统一放在 `overlays/`，通过 `pkgs.callPackage` 引用；原 `pkgs/`
目录及其三个 Pi 包的引用已迁移，未改变这些包的版本或依赖。

更新 RKDevelopTool GUI 时修改 `overlays/rkdeveloptool-gui/default.nix` 的版本及两个架构
的下载哈希，然后重新构建、验证。由 Nix 管理更新，包装器清除 `APPIMAGE` 环境变量，
不启用上游针对可写 AppImage 文件的原地自更新；自动检查新版本仍可在应用设置中关闭。

验证命令：

```sh
nix flake check --no-build --all-systems
nix build .#rkdeveloptool-gui --no-link
nix build .#nixosConfigurations.NixOS-WorkTable.config.system.build.toplevel --no-link
udevadm verify overlays/rkdeveloptool-gui/70-rkdeveloptool-gui.rules
```

如没有连接 Rockchip 开发板，只能验证程序和规则构建，不能据此声称已经通过实机刷写测试。
