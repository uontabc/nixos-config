# uontabc · NixOS fleet

Flakes 固定系统依赖，hjem 管理用户文件，LazyVim 管理编辑器插件。
系统：NixOS 26.05 / Zsh / 英文 / Asia/Shanghai。
多设备结构与接入方式见 [FLEET.md](./FLEET.md)。

## 配置布局

```text
flake.nix              输入、用户身份、主机和开发环境
hosts/default.nix      主机清单：每台机器独立选择架构与模块
hosts/wsl/             已启用的 WSL 主机及其 stateVersion
hosts/vps/             VPS 代理节点（等待现有主机信息）
hosts/server/          本地开发服务器（等待现有主机信息）
lib/mk-host.nix        创建主机的共用入口
modules/common/        共享 Nix 设置与本机重建命令
modules/profiles/      可选角色：开发工具与用户环境
modules/wsl/           WSL、Windows 代理和 CUDA 驱动桥接
configuration.nix      WSL 模块的兼容入口
home/                  hjem、Zsh、Starship、Git、LazyVim
shells/                通用及 CUDA 开发环境
scripts/cuda-check.py  无额外依赖的 GPU 检测
mcp/                  独立 MCP 运行环境的依赖锁
```

## 日常使用

配置安装于 `/home/uontabc/nixos-config`，默认用户为 `uontabc`。

```sh
cd /home/uontabc/nixos-config
nix fmt                       # 格式化 Nix 配置
nixos-rebuild build --flake .#wsl    # 只构建 WSL
rebuild                       # 构建并应用
sudo nixos-rebuild switch --rollback # 回到上一代系统

dev                           # 通用开发 shell（Zsh）
cuda-dev                      # CUDA shell；首次使用下载工具包
nvidia-smi
cuda-check
```

`dev` 和 `cuda-dev` 是交互 Zsh 的别名；其他 Shell 可用
`nix develop /home/uontabc/nixos-config#default` 或 `nix develop /home/uontabc/nixos-config#cuda`。
修改后若新增文件，请先 `git add`，以便 Flakes 读取。
配置已初始化为本地 Git 仓库，可用 `git diff` 查看修改。
`/etc/nixos` 是指向这里的兼容链接。重建时由当前用户求值和构建，
通过 `--sudo` 仅提升激活步骤的权限。

更新依赖是显式操作：`nix flake update`，然后先 build 再 switch。
`system.stateVersion` 保持首次安装值，不随更新修改。
系统每周清理超过 30 天的旧代，因此回滚范围受保留时间限制。

## Python 与本地模型

```sh
mkdir -p ~/projects/model-lab && cd ~/projects/model-lab
uv venv --python python3.12
source .venv/bin/activate
# 在项目内用 uv pip install 或 uv add 安装依赖。
```

RTX 5060 属于 Blackwell，选择明确支持该架构的框架及 CUDA wheel。
系统已配置 WSL 驱动桥接、动态库兼容层；Python 框架及模型按项目安装。
不在 WSL 内安装 Linux NVIDIA 内核驱动。
编译自定义 CUDA 代码时使用 `cuda-dev`，并根据 GPU 设置目标架构。

## 编辑器

运行 `nvim`。首次启动会通过代理安装 LazyVim 插件，之后可用 `:Lazy` 管理。
Python、Rust、C++ 的 LSP 和格式化程序由 Nix 安装，禁用 Mason 下载。
LazyVim 与 lazy.nvim 由 `flake.lock` 固定；其余插件版本保存在
`~/.local/state/nvim/lazy-lock.json`，备份该文件可保存插件版本。
仓库还保存了 `home/nvim/lazy-lock.snapshot.json`。重装时可复制到上述位置，
再运行 `:Lazy restore`，恢复本次验证的插件版本。
hjem 管理的文件不可直接编辑，请修改本仓库 `home/nvim/` 下的源文件后 rebuild。
如需图标，请在 Windows Terminal 中选择 Nerd Font。

## 网络

命令行及 nix-daemon 使用 `http://127.0.0.1:7890`；本机地址绕过代理。
Windows 代理程序需要保持运行，`.wslconfig` 需要保持 mirrored 模式。
更换 Windows 代理端口请修改 `modules/wsl/network.nix`。

## mcp-nixos

已在 Windows Codex 的全局配置中注册 `nixos` MCP：

```text
wsl.exe -d NixOS -- /opt/mcp-nixos/bin/mcp-nixos
```

服务器版本为 3.1.0，安装于独立的 `/opt/mcp-nixos/venv`。
这次配置完善前已通过 MCP 协议实际调用 `nix` 工具，查询 26.05 的软件包、
代理及 nix-ld 选项，并读取锁定版本中的 WSL 和 hjem 模块。
`verification/mcp-queries.json` 保存查询记录。
当前对话通过本地 MCP 客户端调用；Codex 原生工具目录需要重新加载后才能显示新服务器。

依赖版本固定在 `mcp/requirements-lock.txt`，重装命令：

```sh
sudo bash /home/uontabc/nixos-config/scripts/install-mcp.sh
```

MCP 的 Python 解释器已设置独立的 Nix GC root，不依赖临时 `result` 链接。
此 MCP 仅提供 Nix 信息查询，不负责直接修改系统配置。

参考：[mcp-nixos](https://github.com/utensils/mcp-nixos)、
[Codex MCP 配置](https://developers.openai.com/codex/mcp)。

## 用户和备份

用户身份在 `flake.nix` 的 `identity` 中集中定义。
初次部署会备份原配置，并保留 UID 1000 与原有 home 数据。
原配置、用户数据库和 home 归档位于 `/var/backups/nixos-before-uontabc-*`。
保留 WSL 原有的 wheel 免密码 sudo 行为；未启用 SSH、Docker 或模型服务。
