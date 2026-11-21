# 桌面配置管理

桌面静态配置统一由 `users.users.<用户名>.maid` 声明并部署，不需要手工
`ln -s`，也不指向工作目录里的可变配置。修改仓库中的源文件后重建生效。

nix-maid 原生使用 `~/.config/... → ~/.local/state/nix-maid/static-... → 来源`
的链接链；这些是 nix-maid 管理的链接，不应手工替换或编辑。

| 配置 | 仓库入口 | nix-maid 部署位置 |
| --- | --- | --- |
| Kitty | `kitty.nix`、`kitty/` | `~/.config/kitty/` |
| Niri | `niri/default.nix`、`niri/config.kdl` | `~/.config/niri/config.kdl` |
| Kanshi | `niri/default.nix`、`niri/kanshi.conf` | `~/.config/kanshi/config` |
| Noctalia | `noctalia/_settings/`、`lib/maid-noctalia.nix` | `~/.config/noctalia/config.toml`、`palettes/` |
| GTK / Qt / 光标 | `gtk-qt.nix` | `~/.config/gtk-{3,4}.0/`、`qt{5,6}ct/`、光标配置 |
| Fcitx5 输入法列表 / 快捷键 / 主题 / Rime 补丁 | `input-method.nix` | `~/.config/fcitx5/profile`、`conf/{keyboard,classicui}.conf`、`~/.local/share/fcitx5/rime/default.custom.yaml` |
| 默认打开方式（含 Telegram 协议） | `apps.nix` | `~/.config/mimeapps.list` |
| GNOME 字体 / 图标 / 光标 | `gtk-qt.nix` | nix-maid 的 `maid-gsettings.service` 写入用户 dconf |
| 按键可视化入口 / 服务 | `niri/default.nix` | `~/.local/share/applications/key-display.desktop`、`key-display.service` |

NixOS 只负责系统设施、软件包及权限（如 Fcitx5 插件、dconf D-Bus 和
wshowkeys 的 setuid 包装器），不再同时用 `/etc/xdg/fcitx5`、系统 MIME 默认值或
锁定的系统 dconf 数据库管理上述用户设置。

## 动态文件的边界

- Noctalia 生成的主题配色（例如 `niri/noctalia.kdl`、`kitty/themes/noctalia.conf`、
  GTK CSS 和 Qt 配色）仍由 Noctalia 写入，静态配置负责引用它们。
- Noctalia 的 Kitty 主题钩子会写入 `kitty.conf`。`lib/maid-config-file.nix` 用
  nix-maid 的 tmpfiles 规则准备私有可写副本，再由 nix-maid 部署；不是手工链接。
  Nix 配置变更时使用新的副本，未变更时保留应用写入的内容。
- Fcitx5 的 `profile` 也通过同一机制部署可写副本，初始输入法为 Rime；输入法
  列表的默认值由 Nix 声明，当前输入法状态允许守护进程保存。
- Rime 词库/学习数据、浏览器配置档、登录凭据、聊天记录等私有运行数据不作为
  静态配置覆盖；不把整个 `~/.config` 导入公开的 Nix store。

## Kitty 分屏

- 分隔线宽度为 `2px`，仅在有相邻分屏时绘制；焦点分屏使用主题强调色。
- `Ctrl+Shift+O`：左右分屏。
- `Ctrl+Shift+E`：上下分屏。
- `Ctrl+Alt+H/J/K/L`：向左/下/上/右切换分屏，不占用直接输入的 HJKL。
- `Ctrl+Alt+方向键`：同样按方向切换分屏。
- `Ctrl+Alt+Tab`：循环切换分屏，不要求指定方向有相邻分屏。
- `Ctrl+Shift+Enter`：切换堆叠布局（堆叠时只显示一个分屏）。

Fcitx5 的英文键盘模块默认占用 `Ctrl+Alt+H/J` 来触发补全提示，会在 Wayland
客户端收到按下事件前吞掉它们。`input-method.nix` 将其重绑到
`Ctrl+Alt+Shift+H/J`，不关闭中文输入，也不改 kitty 的 HJKL 习惯。修改后运行：

```sh
busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s keyboard
```

`fcitx5-remote -r` 只重载全局配置，不会重载这个已加载的键盘模块。

这些快捷键切换的是**同一个 kitty 标签页内**的分屏；没有相邻分屏时方向键
不会绕回。若是用 `Super+Enter` 打开的两个独立终端，使用 Niri 的
`Super+H/J/K/L` 切换；kitty 标签页之间用 `Ctrl+T`。

## 按键显示

wshowkeys 随 Niri 登录自动常驻，右下角滚动保留最近 12 个按键事件，闲置时
不清空最后的显示。`Super+Alt+K` 仍可手动关闭/开启；保留 `Super+Shift+K`
原有的向上移动窗口功能。

浮层作为 nix-maid 用户服务管理，退出 Niri 时停止。上游 `-t 0` 并不代表常显；
`niri/wshowkeys-persistent.patch` 明确加入零超时常显、有限历史和空闲不轮询的
语义，避免无限积累历史。
启动器中搜索「按键可视化」或 `Key Display` 也能切换，开启/关闭时会显示通知。
也可使用：

```sh
toggle-key-display
systemctl --user stop key-display.service
journalctl --user -u key-display.service -b
```

使用 NixOS 官方 `programs.wshowkeys` 权限包装器，不把用户加入 `input` 组。
**常驻工具会读取所有按键，无法识别密码框；输入密码、其他秘密或锁屏前必须
手动关闭（`Super+Alt+K` 或 `systemctl --user stop key-display.service`）。**
按键显示不会通过标准输出写入 journal。

## 应用与检查

```sh
# 先检查其他待提交的系统修改；重建会一并应用它们。
sudo nixos-rebuild switch --flake path:/home/uontabc/nixos-config#NixOS-WorkTable

# 按 nix-maid 实际声明逐一验证链接及其最终目标是否存在。
maid-check
systemctl --user status maid-activation.service maid-gsettings.service
```

首次迁移前备份被接管的普通文件（`mimeapps.list`、`fcitx5/profile`）。首次系统
切换还会移除原来的系统 dconf 锁；仅运行用户 activation 不会移除 `/etc` 下的
旧设置。之后可用 `systemctl --user restart maid-activation.service` 重新部署
**当前系统代**的用户配置，不需要手工创建链接。

kitty 配置由文件监视器重载，也可 `kill -USR1 <kitty进程号>`，无需关闭正在工作
的终端；Niri 配置自动重载。`maid-check` 检查的是仓库声明的配置，不表示浏览器
数据库等应用运行数据也应交给 Nix。

### 回归测试

```sh
# 在运行中的 Niri 会话执行；只在临时 Kitty 窗口中发送测试按键并恢复原焦点。
# wtype 可从当前锁定的 nixpkgs 构建，传入其可执行文件路径。
kitty +launch modules/desktop/kitty/test_keybindings.py --wtype /path/to/wtype
kitty +launch modules/desktop/kitty/test_tab_bar.py
```

按键测试覆盖创建左右/上下分屏、HJKL/方向键/循环切换，以及从堆叠布局切换或
创建分屏；不是只检查配置里有没有一行 `map`。但 wtype 不经过物理键盘的
Fcitx5 抢占路径，不能用它证明没有输入法快捷键冲突。修复输入法后仍须用物理
键盘确认 H/J 能切换。wshowkeys 也需物理键盘验证，因为它读取 evdev，wtype
的虚拟 Wayland 键盘不会经过 evdev。
