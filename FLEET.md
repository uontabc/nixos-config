# 多设备管理

主配置仓库：`/home/uontabc/nixos-config`。同一个仓库保存多台机器的配置，
每台机器通过独立的 Flake 名称选择自己的系统。

| 主机 | 用途 | 状态 |
| --- | --- | --- |
| `wsl` | Windows 下的开发工作站、CUDA | 已构建并启用 |
| `vps` | 代理节点 | 目录已预留，等待当前配置与代理软件信息 |
| `server` | 本地项目开发服务器 | 目录已预留，等待当前配置与硬件信息 |

`nixos` 暂时作为 `wsl` 的兼容别名。VPS 和服务器尚未注册为可部署输出。

## 模块如何组合

`hosts/default.nix` 是主机清单，`lib/mk-host.nix` 统一创建系统。
共享模块只配置 Nix、语言、时区和管理命令。

- `hosts/wsl/default.nix`：WSL 硬件集成、Windows 代理、开发角色。
- `modules/profiles/development.nix`：Python、Rust、C++、Zsh、LazyVim、hjem。
- `modules/wsl/`：Windows localhost 代理与 Windows GPU 驱动桥接。

每台机器独立保留架构、引导、文件系统、网卡、SSH 访问、服务及
`system.stateVersion`。开发服务器可复用开发角色，GPU 驱动按其实际硬件配置。
VPS 的代理服务按所使用的软件和协议单独声明。

## 重建某台机器

当前 WSL：

```sh
cd ~/nixos-config
nixos-rebuild build --flake .#wsl
rebuild
```

`rebuild` 会在每台主机安装时绑定它自己的主机名称。
求值和构建使用普通用户，`--sudo` 只为激活步骤提权。

服务器接入后，将分别使用 `.#vps` 和 `.#server`。从 WSL 远程部署时，
目标通过 `--target-host` 显式指定；架构不同时可在目标机器上构建。
是否启用 SSH 部署、部署账户和构建方式，需要先确认现有连接与架构。

## 接入两台现有 NixOS

下一步先通过获准的 SSH 连接读取现有配置，确认架构和状态版本，
保留各自主机的硬件与访问设置，再注册到主机清单。
当前没有更改任何远程机器。
