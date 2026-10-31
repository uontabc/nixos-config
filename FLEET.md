# 多设备管理

主配置仓库：`/home/uontabc/nixos-config`。同一个仓库保存多台机器的配置，
每台机器通过独立的 Flake 名称选择自己的系统。

| 主机 | 用途 | 状态 |
| --- | --- | --- |
| `wsl` | Windows 下的开发工作站、CUDA | 已构建并启用 |
| `vps` | sing-box / VLESS / REALITY / XTLS 代理节点 | 模板已完成，等待接入本机原配置 |
| `server` | Python / Rust / C++ 项目开发服务器 | 模板已完成，等待接入本机原配置 |

`nixos` 暂时作为 `wsl` 的兼容别名。VPS 和服务器尚未注册为可部署输出。
两份模板的 `machine.nix` 带有明确的待配置断言；未接入真实机器前不会意外部署。

## 模块如何组合

`hosts/default.nix` 是主机清单，`lib/mk-host.nix` 统一创建系统。
共享模块只配置 Nix、语言、时区和管理命令。

- `hosts/wsl/default.nix`：WSL 硬件集成、Windows 代理、开发角色。
- `modules/profiles/development.nix`：Python、Rust、C++、Zsh、LazyVim、hjem。
- `modules/wsl/`：Windows localhost 代理与 Windows GPU 驱动桥接。
- `modules/profiles/proxy-node.nix`：代理节点的服务角色。
- `modules/services/sing-box-reality.nix`：VLESS + REALITY + Vision 和运行时秘密文件。

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

1. 将每台机器现有的 `/etc/nixos` 配置树复制到各自的 `hosts/<name>/existing/`。
2. 替换对应的 `machine.nix`，导入原有入口并移除待配置断言。保留原始 stateVersion。
3. 在 `hosts/default.nix` 取消相应主机项的注释，填写真实架构和仓库在目标上的路径。
4. VPS 先按 [节点说明](./hosts/vps/README.md) 生成本机凭据并调整握手域名。
5. `git add` 后先构建目标，再应用。迁移旧配置时处理与新角色重复声明的选项。

`--target-host` 只部署系统闭包，不会自动复制可编辑的 Git 仓库。
若还想在远端直接运行 `rebuild`，仓库应放到该主机清单中 `configRoot` 指定的位置。

示例（主机注册后）：

```sh
nixos-rebuild build --flake .#vps
nixos-rebuild build --flake .#server

# 同架构时在 WSL 构建，交由现有的 SSH 管理账户激活
nixos-rebuild switch --flake .#vps --target-host USER@VPS --sudo

# 异架构时交由目标机器构建
nixos-rebuild switch --flake .#server \
  --build-host USER@SERVER --target-host USER@SERVER --sudo
```

服务开关互相独立，修改 VPS 代理参数不会启用 WSL 或开发服务器上的代理服务。
当前只验证了本地模板和 WSL，尚未连接或修改远程机器。
