# uontabc · NixOS fleet

一个 Flake 仓库分别管理 WSL、VPS 和 Windows/NixOS 双系统笔记本。主配置位于
`/home/uontabc/nixos-config`，`/etc/nixos` 指向这里。本文是唯一的配置文档。

| 主机 | 用途 | 当前状态 |
| --- | --- | --- |
| `wsl` | Windows 开发工作站、CUDA | 已启用 |
| `vps` | sing-box / VLESS / REALITY / Vision | 模板，待接入本机配置 |
| `laptop` | 同盘双系统、MangoWM + Noctalia、项目开发 | 不加密模板，尚未划定安装空间 |

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
hosts/laptop/             双系统笔记本：硬件入口、桌面、原生显卡
lib/mk-host.nix            创建主机的共用入口
modules/common/           共享 Nix 设置与管理命令
modules/profiles/         开发环境、笔记本、代理节点角色
modules/services/         sing-box REALITY 服务
modules/wsl/              Windows 代理、WSL GPU 驱动桥接
home/                     hjem、Zsh、Starship、Git、LazyVim
shells/                   通用与 CUDA 开发环境
scripts/                  GPU 检测、REALITY 初始化、MCP 安装
mcp/                      MCP 依赖锁
```

用户身份集中在 `flake.nix` 的 `identity` 中。当前用户为 `uontabc`，
系统使用英文和 `Asia/Shanghai` 时区，hjem 管理用户配置文件。

## 启用 VPS 与笔记本

`hosts/default.nix` 的 VPS 和笔记本条目目前保持注释状态，只有 WSL 已启用。
各主机独立选择硬件、服务和引导，Windows 代理与驱动桥接只由 WSL 导入。

VPS 沿用现有 NixOS：把原 `/etc/nixos` 配置树复制到 `hosts/vps/existing/`，
替换 `machine.nix` 导入原入口并移除待配置断言，保留磁盘、网络、SSH 和原始
stateVersion；再在主机清单中填写架构与 `configRoot`，按下一节准备代理凭据。
原配置与新角色重复的选项需要在迁移时处理。

```sh
# VPS 注册后
nixos-rebuild build --flake .#vps
nixos-rebuild switch --flake .#vps --target-host USER@VPS --sudo
```

异架构远程构建可再加 `--build-host USER@VPS`。
`--target-host` 只部署系统闭包，不会复制 Git 仓库；远端直接使用 `rebuild`
需要把仓库放到该主机的 `configRoot`。

### 笔记本双系统模板

`laptop` 对应当前笔记本上的原生 NixOS，与 Windows 安装在同一块硬盘。
检测到的硬件为 Lenovo 83LT、Ryzen 9 8940HX、RTX 5060 Laptop，
一块约 1 TB 的 GPT 硬盘。Windows 当前只暴露 NVIDIA 显卡。

- `hosts/laptop/desktop.nix`：MangoWM + Noctalia 5、greetd 登录、hjem 用户配置。
- `hosts/laptop/graphics.nix`：原生 NVIDIA open 驱动与 CUDA 库路径。
- `modules/profiles/laptop.nix`：UEFI systemd-boot、NetworkManager、声音、
  蓝牙、触摸板、电源管理和 AMD 微码；RTC 使用 Windows 现有的本地时间约定。
- `hosts/laptop/machine.nix`：实际安装时填写不加密的根分区和 EFI 挂载。

笔记本复用 Python、Rust、C++、Zsh、LazyVim 和 hjem，默认用户为 `uontabc`。
新安装的兼容基线为 `system.stateVersion = "26.05"`。
没有预设密码或自动登录，安装时需要为该用户设置登录密码。

已确认采用同盘双系统、不加密，当前尚未为 NixOS 留出空间。模板不包含格式化、缩容或自动分区操作。
从 NixOS 安装介质启动、按选定方案挂载目标后，用
`nixos-generate-config --root /mnt` 生成真实硬件配置；将其复制到
`hosts/laptop/hardware-configuration.nix`，在 `machine.nix` 中导入并移除待配置断言。
然后取消主机清单中 `laptop` 的注释，先构建 `.#laptop` 再继续安装。
不要把 WSL 生成的硬件配置用于原生系统。

模板使用 systemd-boot。共享 Windows ESP 时可自动发现 Windows；
ESP、XBOOTLDR 或独立 EFI 的挂载方案需要根据实际分区与剩余空间确定。
读取到的当前 Secure Boot 状态为关闭，本次没有更改固件设置。
若之后开启 Secure Boot，需要另行配置签名引导。

PRIME 混合显卡暂未开启。若 Linux 下能看到 AMD 核显与 NVIDIA 独显，
再根据 `lspci` 的实际 PCI ID 设置 offload；模板没有编造总线地址。
原生显卡、休眠、Wi-Fi 和触摸板需要安装介质或实际安装后的硬件验证。

桌面相关输入分别固定在 `flake.lock`，保留上游所需的 nixpkgs 版本。
MangoWM 配置在 `home/mango/config.conf`，Noctalia 使用官方 hjem 模块，
主题为 Catppuccin dark，配置从 `hosts/laptop/desktop.nix` 修改后 rebuild。
Noctalia 随 Mango 会话启动，负责面板、启动器、通知、锁屏和笔记本控制。
已配置 10 分钟空闲锁屏、11 分钟熄屏，以及休眠前锁屏；没有设置自动定时挂起。

| 快捷键 | 操作 |
| --- | --- |
| Super + Enter | Foot 终端 |
| Super + Space | Noctalia 启动器 |
| Super + S / 逗号 | 控制中心 / 设置 |
| Super + L | 锁屏 |
| Super + Q / F | 关闭窗口 / 全屏 |
| Super + 方向键 | 切换焦点 |
| Super + Shift + 方向键 | 移动窗口 |
| Super + 1–9 | 切换工作区，增加 Shift 可移动窗口 |
| Super + R | 重载 Mango 配置 |
| Super + Shift + E | 退出桌面会话 |

音量和亮度功能键已接入 Noctalia。首次登录前需设置 `uontabc` 的密码；
登录和锁屏使用该用户密码，不启用自动登录。

参考：[MangoWM](https://mangowm.github.io/docs/)、
[Noctalia Mango 集成](https://docs.noctalia.dev/noctalia/compositor-settings/mango/)、
[Noctalia 的 hjem 模块](https://docs.noctalia.dev/noctalia/getting-started/nixos/#hjem-module)。

参考：[NixOS 安装手册](https://nixos.org/manual/nixos/stable/#sec-installation)、
[systemd-boot](https://www.freedesktop.org/software/systemd/man/latest/systemd-boot.html)、
[NVIDIA 内核模块](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/610/kernel-modules.html)。

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
Linux NVIDIA 内核驱动。原生笔记本使用其独立的 NVIDIA 驱动配置。

运行 `nvim` 启动 LazyVim，`:Lazy` 管理插件。语言服务器和格式化工具由 Nix
安装，Mason 下载已禁用。hjem 管理的文件从仓库 `home/nvim/` 修改后 rebuild。

LazyVim 和 lazy.nvim 固定在 `flake.lock`；其余插件版本位于
`~/.local/state/nvim/lazy-lock.json`。重装时可把仓库中的
`home/nvim/lazy-lock.snapshot.json` 复制到该位置，再执行 `:Lazy restore`。
Windows Terminal 如需显示图标，请选择 Nerd Font。

## Zsh 历史记录保护

`home/zsh/interactive.zsh` 与 `home/zsh/history-guard.py` 由 hjem 一起部署，
WSL 和笔记本共用。历史仍保存在 `~/.local/state/zsh/history`，多终端共享，
显式启用 `HIST_FCNTL_LOCK`、`HIST_SAVE_BY_COPY`，不混用互斥的增量写入选项。
锁与复制后替换的行为参考 [Zsh 官方文档](https://zsh.sourceforge.io/Doc/Release/Options.html#History)。

每次启动终端，先用独立 Zsh 进程检查历史是否可读取（不执行历史命令），
保留两份不同的有效快照 `history.last-good`、`history.previous-good`。
检测到空字节时，只移除空字节并验证；仍不可读时，尝试恢复有效快照。
恢复前将原件保存为 `history.corrupt-时间戳`，并在终端显示恢复提示。
未知损坏且没有有效备份时，保留原件并暂停当前会话的磁盘历史写入。
目录权限为 0700，历史和快照为 0600；快照可能包含敏感命令，应同历史一样保管。
快照在启动新终端时更新，不能保证保留异常关机前最后输入的命令。

这套保护降低并恢复常见损坏，不保证抵抗磁盘故障或强制断电。
更新配置后，现有终端执行 `exec zsh` 或重新打开，以加载保护。

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
