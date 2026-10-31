# uontabc · NixOS fleet

一个 Flake 仓库分别管理 WSL、VPS 和本地开发服务器。主配置位于
`/home/uontabc/nixos-config`，`/etc/nixos` 指向这里。本文是唯一的配置文档。

| 主机 | 用途 | 当前状态 |
| --- | --- | --- |
| `wsl` | Windows 开发工作站、CUDA | 已启用 |
| `vps` | sing-box / VLESS / REALITY / Vision | 模板，待接入本机配置 |
| `server` | Python / Rust / C++ 开发服务器 | 模板，待接入本机配置 |

## 日常操作

```sh
cd ~/nixos-config
git diff                              # 查看修改
git add .                             # 让 Flakes 读取新增文件
nix fmt                               # 格式化 Nix 配置
nixos-rebuild build --flake .#wsl      # 只构建 WSL
rebuild                               # 构建并应用当前主机
sudo nixos-rebuild switch --rollback   # 回到上一代系统
```

`rebuild` 按主机绑定自己的 Flake 名称，普通用户完成求值和构建，
`--sudo` 只为激活提权。`nixos` 是 `wsl` 的兼容别名。

更新依赖用 `nix flake update`，随后先 build 再应用。
每台机器保留首次安装时的 `system.stateVersion`，它不随系统升级修改。
默认每周清理超过 30 天的旧代，回滚范围受保留时间限制。

## 目录与职责

```text
flake.nix                 输入锁定、用户身份、系统输出、开发 Shell
hosts/default.nix         主机清单：架构、模块、仓库在目标上的路径
hosts/wsl/                当前 WSL 主机
hosts/vps/                VPS 模板：machine.nix、proxy.nix、模块入口
hosts/server/             开发服务器模板：machine.nix、模块入口
lib/mk-host.nix            创建主机的共用入口
modules/common/           共享 Nix 设置与管理命令
modules/profiles/         开发环境、代理节点角色
modules/services/         sing-box REALITY 服务
modules/wsl/              Windows 代理、WSL GPU 驱动桥接
home/                     hjem、Zsh、Starship、Git、LazyVim
shells/                   通用与 CUDA 开发环境
scripts/                  GPU 检测、REALITY 初始化、MCP 安装
mcp/                      MCP 依赖锁
```

用户身份集中在 `flake.nix` 的 `identity` 中。当前用户为 `uontabc`，
系统使用英文和 `Asia/Shanghai` 时区，hjem 管理用户配置文件。

## 接入 VPS 和本地服务器

两台远程主机尚未注册为可部署输出，也未连接或修改。
每台机器分别保留自己的磁盘、引导、网络、SSH 访问和 stateVersion。

1. 把原有 `/etc/nixos` 配置树复制到对应的 `hosts/<name>/existing/`。
2. 替换该主机的 `machine.nix`，导入原有配置并移除待配置断言。
   迁移时处理原配置与新角色重复声明的选项。
3. 在 `hosts/default.nix` 取消该主机条目的注释，填写真实架构
   （`x86_64-linux` 或 `aarch64-linux`）和目标上的 `configRoot`。
4. VPS 按下一节准备凭据并修改代理参数。
5. `git add` 后先构建目标，确认成功后再应用。

模板中的断言会阻止缺少本机配置的部署。
本地服务器复用开发角色，默认用户 `uontabc` 使用 Zsh 并加入 wheel；
原有账户继续保留，密码、SSH 密钥和 sudo 策略沿用原配置。
本机显卡驱动、Docker、数据库和项目服务可加入对应主机的模块列表。

主机注册后可分别构建或通过现有 SSH 管理账户部署：

```sh
nixos-rebuild build --flake .#vps
nixos-rebuild build --flake .#server

# 同架构：在 WSL 构建，远端激活
nixos-rebuild switch --flake .#vps --target-host USER@VPS --sudo

# 异架构：在目标机器构建并激活
nixos-rebuild switch --flake .#server \
  --build-host USER@SERVER --target-host USER@SERVER --sudo
```

`--target-host` 只部署系统闭包，不会复制可编辑的 Git 仓库。
若需要在目标上直接运行 `rebuild`，还需把仓库放到其 `configRoot` 路径。
各主机的服务独立组合，Windows 代理和 GPU 桥接仅由 WSL 导入。

## VPS：VLESS + REALITY + Vision

`hosts/vps/proxy.nix` 定义监听端口、握手域名和凭据目录。
默认 TCP 443，流控为 `xtls-rprx-vision`；示例握手域名是
`www.microsoft.com`，请按 VPS 的实际连通情况修改。

首次应用前，在 VPS 上生成本机凭据。假设仓库位于 `/etc/nixos`：

```sh
sudo nix --extra-experimental-features 'nix-command flakes' shell \
  --inputs-from path:/etc/nixos nixpkgs#sing-box nixpkgs#python312 \
  -c python3.12 /etc/nixos/scripts/init-reality.py
```

脚本在 `/var/lib/sing-box-secrets` 创建 `uuid`、`private-key`、`public-key`
和 `short-id`。目录权限 0700，文件权限 0600；已有凭据不会被覆盖。
NixOS 在服务启动时通过 `_secret` 读取值，私钥不进入 Nix store 或 Git。
配置应用后，系统中的 `sudo reality-init` 也可执行初始化。

```sh
sudo systemctl status sing-box
sudo journalctl -u sing-box -e
```

云服务商入站规则需允许所选 TCP 端口。客户端填写 VPS 地址、端口、UUID、
相同的 SNI、REALITY 公钥、short ID 和 `xtls-rprx-vision`；私钥保留在 VPS。

参考：[VLESS](https://sing-box.sagernet.org/configuration/inbound/vless/)、
[REALITY](https://sing-box.sagernet.org/configuration/shared/tls/#reality-fields)。

## 开发与编辑器

Python、Rust、C++ 工具链由开发角色管理，Python 依赖放在各项目内：

```sh
mkdir -p ~/projects/model-lab && cd ~/projects/model-lab
uv venv --python python3.12
source .venv/bin/activate
# 使用 uv pip install 或 uv add 安装项目依赖
```

交互 Zsh 中，`dev` 进入通用开发环境，`cuda-dev` 进入 CUDA 环境。
其他 Shell 使用 `nix develop ~/nixos-config#default` 或
`nix develop ~/nixos-config#cuda`。

WSL 已配置 Windows NVIDIA 驱动桥接和动态库兼容层，可用 `nvidia-smi`
和 `cuda-check` 检查。RTX 5060 的计算能力为 12.0，安装模型框架时选择支持
该架构的 CUDA wheel。自定义 CUDA 编译放在 `cuda-dev` 中；WSL 内不安装
Linux NVIDIA 内核驱动。原生服务器按自身显卡选择驱动。

运行 `nvim` 启动 LazyVim，`:Lazy` 管理插件。语言服务器和格式化工具由 Nix
安装，Mason 下载已禁用。hjem 管理的文件从仓库 `home/nvim/` 修改后 rebuild。

LazyVim 和 lazy.nvim 固定在 `flake.lock`；其余插件版本位于
`~/.local/state/nvim/lazy-lock.json`。重装时可把仓库中的
`home/nvim/lazy-lock.snapshot.json` 复制到该位置，再执行 `:Lazy restore`。
Windows Terminal 如需显示图标，请选择 Nerd Font。

## WSL 网络、MCP 与备份

WSL 命令行和 nix-daemon 使用 `http://127.0.0.1:7890`，本机地址绕过代理。
Windows 代理需运行，`.wslconfig` 保持 `networkingMode=mirrored`。
更换端口修改 `modules/wsl/network.nix`。

Windows Codex 已注册 `nixos` MCP，启动命令为：

```text
wsl.exe -d NixOS -- /opt/mcp-nixos/bin/mcp-nixos
```

MCP 3.1.0 位于 `/opt/mcp-nixos/venv`，工作目录是本仓库。
依赖锁保存在 `mcp/requirements-lock.txt`，解释器有独立的 Nix GC root。
重新安装用 `sudo bash ~/nixos-config/scripts/install-mcp.sh`。
Codex 重新加载工具目录后显示该服务器；它提供 Nix 信息查询。

参考：[mcp-nixos](https://github.com/utensils/mcp-nixos)、
[Codex MCP](https://developers.openai.com/codex/mcp)。

最初 WSL 配置、用户数据库和 home 归档保存在
`/var/backups/nixos-before-uontabc-*`。用户迁移保留了 UID 1000 和原 home 数据；
WSL 沿用原有 wheel 免密码 sudo 行为。当前 WSL 未启用 SSH、Docker 或模型服务。
