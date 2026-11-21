# nixos-config

NixOS 系统配置与 nix-maid 用户配置。系统模块由 flake-parts / import-tree
发现，再由 `modules/presets.nix` 和各主机显式组合；用户配置统一通过
`users.users.<用户名>.maid` 部署。

## 主机

| 主机 | 用途 | 状态 |
| --- | --- | --- |
| `NixOS-WorkTable` | Niri / Noctalia 桌面与开发环境 | 启用 |
| `onyx` | WSL 开发环境 | 启用 |
| `NixOS-WorkCloud` | 远程代理节点 | 尚未启用，需先完善机器配置 |

主机定义位于 `modules/hosts/`；通用功能组合位于 `modules/presets.nix`。

## 目录

| 路径 | 内容 |
| --- | --- |
| `flake.nix`、`flake.lock` | 输入及其锁定版本 |
| `lib/` | 主机构造、共享主题、nix-maid 辅助模块 |
| `modules/base/` | Shell、编辑器和基础工具 |
| `modules/desktop/` | 桌面、终端、输入法与应用设置 |
| `modules/hosts/` | 各主机的硬件、磁盘、网络等专有配置 |
| `modules/services/` | 独立服务模块 |
| `modules/flake-parts/` | flake 输出、开发环境与模板入口 |
| `overlays/` | 自定义软件包和包装器 |
| `templates/` | Python、Rust、C++ 项目模板 |

## 应用与检查

```sh
cd ~/nixos-config

# 检查待应用的改动。
git status --short
git diff --check

# 先只求值，不切换运行中的系统。
nix eval --raw 'path:.#nixosConfigurations.NixOS-WorkTable.config.system.build.toplevel.drvPath'

# 桌面主机：构建并切换。
sudo nixos-rebuild switch --flake path:.#NixOS-WorkTable

# 核对当前系统代部署的用户配置。
maid-check
systemctl --user status maid-activation.service maid-gsettings.service
```

这里使用 `path:.`，使尚未加入 Git 的新配置文件也参与构建。提交时应一并加入
被引用的新模块、资源和补丁；不要把未跟踪文件直接当作垃圾删除。

桌面配置归属、kitty 分屏快捷键、输入法冲突修复、按键常显和测试说明见
[`modules/desktop/README.md`](modules/desktop/README.md)。

## 管理边界

- NixOS 管理系统服务、软件包及权限；nix-maid 管理用户配置与用户服务。
- 需要应用写入的配置由 nix-maid 准备私有可写副本；主题生成物由 Noctalia 写入。
- 登录凭据、浏览器数据库、聊天记录、输入法学习数据不导入 Nix store。
- 构建链接、Python 缓存及编辑器备份由 `.gitignore` 排除，不作为配置源保留。
- 清理不应删除有效配置、资源、锁文件或回归测试，也不应使用 `git reset --hard`
  或无差别的 `git clean -fd` 丢弃未提交工作。
