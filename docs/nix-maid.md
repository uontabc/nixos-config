# 用户配置：nix-maid

原 Hjem 配置现统一声明在 `users.users.${identity.username}.maid` 下：

- `file.home`、`file.xdg_config`、`file.xdg_data` 管理单个配置文件，不锁定整个应用目录。
- `systemd.services` 管理 Noctalia、kanshi 和休眠前锁屏服务。
- `lib/maid-noctalia.nix` 提供 Noctalia 的 nix-maid 模块，保留 TOML 构建期校验、自定义调色板及服务重启触发条件。
- `lib/maid-config-file.nix` 为 btop、kitty 等需要写回配置的应用生成可写副本。副本位于 `$XDG_STATE_HOME/nix-maid/writable`，权限为 `0600`。配置来源不变时保留应用修改，Nix 中的默认配置变化时使用新的副本。
- Noctalia 的 GUI 覆盖、插件状态、Rime 词库和 Neovim 的运行时锁文件仍由应用写入，不纳入只读链接管理。

nix-maid 的状态保存在用户的 `~/.local/state/nix-maid` 中；该主机的 `/home` 已持久化，无需另设 `/var/lib/hjem` 持久化目录。

## 首次切换

**nix-maid 接管文件时会替换目标文件，并接管整个 `~/.config/systemd/user` 目录。** 如果有仓库外手动添加的用户服务，先备份并将其迁入 nix-maid，不能仅留在该目录。

建议先备份现有用户服务和可写配置（在普通用户终端执行）：

```bash
backup="$HOME/.local/state/before-nix-maid-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
(
  cd "$HOME"
  cp -a --parents .config/systemd/user .config/btop/btop.conf .config/kitty/kitty.conf "$backup/"
)
```

首次启用可写配置会使用仓库声明的默认值；如需保留旧布局，可在切换后从备份恢复相应内容。不要提前删除旧 Hjem 状态，以便回滚旧系统版本。

```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#NixOS-WorkTable
# WSL 主机使用 .#onyx

systemctl --user status maid-activation.service
systemctl --user status noctalia.service kanshi.service niri-lock-before-sleep.service
nix --version  # 应显示 Lix
```

之后正常使用 `nixos-rebuild switch` 即可。需要重新落地配置时：

```bash
systemctl --user restart maid-activation.service
```

字体调整使用全局文楷 Medium（包含等宽版本），不改变英文代码字体。切换后重启浏览器、终端等应用，或注销后重新登录，确保字体缓存与进程内字体匹配都已更新。

## 无副作用验证

```bash
bash tests/maid-files.sh
```

测试会构建两台主机的用户配置，在临时 HOME 内验证所有声明文件均能落地、旧链接能被替换、可写配置权限正确且重复激活保留应用修改。它只执行指定的 tmpfiles 规则，不会切换系统或重启当前用户服务。
