# NixOS Config

使用 Nix Flakes + [flake-parts](https://github.com/hercules-ci/flake-parts) 管理 WSL、双系统笔记本与 VPS，
使用 hjem 管理用户配置。系统跟随 `nixos-unstable`，依赖版本由 `flake.lock` 固定。

[日常维护](#日常维护) · [远程安装](#远程安装) · [目录结构](#目录结构) · [开发环境](#开发环境) · [桌面与主题](#桌面与主题) · [WSL](#wsl)

## 主机

| 主机 | 用途 | 状态 | 安装与部署 |
| --- | --- | --- | --- |
| `onyx` | WSL 开发环境 | 已启用 | [WSL 配置说明](#wsl) |
| `obsidian` | Windows / NixOS 双系统笔记本 | 待安装，清单暂未启用 | [双系统安装指南](docs/obsidian-install.md) |
| `umbra` | VPS · VLESS + REALITY + Vision | 重装模板，清单暂未启用 | [部署说明](docs/umbra-deploy.md) |

主机名、Flake 目标和 `rebuild` 目标保持一致。主机清单位于 `hosts/default.nix`，
用户身份集中在 `modules/hosts.nix` 的 `identity` 中，当前用户为 `uontabc`。

## 日常维护

在已安装的主机上执行：

```sh
cd ~/nixos-config
# 修改配置；新增文件需先 git add，才能被 Git Flake 读取
nix fmt
git diff
nh os build --hostname onyx    # 只构建；笔记本改为 obsidian
rebuild                           # 构建并应用当前主机
```

`rebuild` 使用主机绑定的仓库路径和目标，普通用户负责构建，激活时通过 sudo 提权。
也可使用 `nh os switch --hostname onyx`。VPS 的仓库路径由 `configRoot` 指定。

| 操作 | 命令 |
| --- | --- |
| 更新依赖 | `nix flake update`，然后先构建、再应用 |
| 回滚系统 | `sudo nixos-rebuild switch --rollback` |
| 查看系统信息 | `fastfetch`（开发环境） |

- `system.stateVersion` 保留首次安装时的值，不随依赖升级修改。
- NixOS-WSL 跟随 `main`；切换 nixpkgs 分支时一并检查兼容性。
- 默认每周清理超过 30 天的旧代；回滚不恢复个人文件，也不能替代备份。
- 日常 rebuild **不会执行 Disko 分区或格式化**。

## 远程安装

仓库提供由 `flake.lock` 中 nixpkgs 锁定的 `nixos-anywhere`，无需全局安装：

```sh
cd ~/nixos-config
nix run .#nixos-anywhere -- --help
# 或进入仓库维护环境
nix develop
nixos-anywhere --help
```

首次安装 umbra 的完整准备与命令见 [VPS 部署指南](docs/umbra-deploy.md#使用-nixos-anywhere-远程安装)。
**默认安装会通过 Disko 擦除目标整盘，不用于日常更新，也不要对 obsidian 双系统照搬执行。**
`umbra` 仍需核对磁盘、硬件、网络与 SSH 后手动启用；此工具不会绕过安装保护。
WSL 使用其专用安装方式，obsidian 继续使用[保留 Windows 的分区级流程](docs/obsidian-install.md)。

## 目录结构

```text
flake.nix          输入与 mkFlake + import-tree 自动导入入口
hosts/             主机清单及各机硬件、磁盘、桌面或服务配置
lib/               主机构造函数、共享主题
modules/           自动发现的 flake-parts 模块；NixOS 配置经 flake.modules.nixos 导出
modules/common/    Nix 设置、nh 与 rebuild
modules/profiles/  开发环境、笔记本、代理节点角色
modules/services/  Docker、Pi、sing-box
modules/wsl/       WSL 网络代理与 GPU 驱动桥接
home/              hjem 管理的 Zsh、LazyVim、Starship、Ghostty 等配置
shells/            仓库维护环境及语言工具链快捷入口
templates/         独立的 Python、Rust、C++ 项目模板
packages/          Pi 扩展打包与依赖锁
scripts/           分区检查、根目录重置、REALITY 初始化与 MCP 维护
mcp/               Windows Codex 使用的 MCP 依赖锁
docs/              安装与部署指南
```

### Flake 模块约定

入口参考 [ocfox/island](https://github.com/ocfox/island) 的写法，不另设 `flake/` 目录：

```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
```

`import-tree` 递归发现 `modules/` 中的 `.nix` 文件；这些文件全部是 flake-parts 模块。
新增文件不必维护入口导入列表，但 Git Flake 仍要求先 `git add`。路径含 `/_` 的辅助文件默认不自动导入。

- `modules/flake-parts.nix`：启用官方 `flakeModules.modules` 注册表，声明 `systems`、
  `perSystem.apps`、`perSystem.devShells`、`perSystem.formatter`，保留 `allowUnfree` 策略。
- `modules/hosts.nix`：用户身份、`flake.nixosConfigurations` 与 `flake.lib.mkHost`；主机清单仍是 `hosts/default.nix`。
- `modules/templates.nix`：`flake.templates`，独立项目模板与其锁文件保持独立。
- 其他文件将 NixOS 配置定义在 `flake.modules.nixos.<名称>` 内，而不是直接在外层写 NixOS 选项。
  自动发现只注册模块，不会自动启用所有服务；角色与主机通过 `self.modules.nixos.<名称>` 显式组合。

例如新增功能文件可写为：

```nix
{ ... }:
{
  flake.modules.nixos.example = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.hello ];
  };
}
```

随后在需要该功能的主机或角色中导入 `self.modules.nixos.example`。
`lib/mk-host.nix` 提供 NixOS 层的 `self`、`inputs`、`identity` 等参数；
flake-parts 外层参数与内层 NixOS 参数是两个作用域，不要混用 `config` / `pkgs`。

`systems` 声明 `x86_64-linux` 和 `aarch64-linux`，安装工具、开发 Shell 与格式化器统一在这两个平台导出。
这不会自动启用 obsidian / umbra，也不会改变主机平台或移除安装保护。
这里只采用 island 的模块组织方式，不引入其 Kix、私有缓存、主机或密钥配置。
细节参考 [flake-parts 文档](https://flake.parts/module-arguments)和 [import-tree 文档](https://github.com/vic/import-tree)。

## 开发环境

全局仅保留日常工具和 Nix / Lua 配置支持；编译器、语言服务和格式化器由项目提供。

| 模板 | 工具链 |
| --- | --- |
| `python` | Python 3.12、uv、Ruff、Pyright |
| `rust` | rustc、Cargo、Clippy、rustfmt、rust-analyzer、原生链接器 |
| `cpp` | GCC、CMake、Ninja、Make、pkg-config、ccache、GDB、clangd / clang-format |

### 创建项目

```sh
mkdir -p ~/projects/my-python && cd ~/projects/my-python
git init
nix flake init --template ~/nixos-config#python
git add flake.nix flake.lock shell.nix .envrc .gitignore
nix develop -c zsh                 # 简写：dev
uv init --bare
uv add requests
nvim
```

其他语言将模板名换成 `rust` 或 `cpp`。已有项目应手动合并模板，避免覆盖现有文件。

- 在项目的 `shell.nix` 中维护工具和系统依赖；它由 `flake.nix` 导入，不是独立的 nix-shell 入口。
- 提交项目的 `flake.lock` 及 `uv.lock` / `Cargo.lock` 等语言锁文件。
- 模板复制后完全独立；更新系统不会改变项目工具链。项目升级用 `nix flake update nixpkgs`。
- 使用自动环境加载：执行 `direnv allow`；修改 `.envrc` 后需重新授权。
- 从项目环境启动 `nvim` 或 `pi`，已打开的进程不会自动继承其他终端的新环境。

临时使用工具链可运行 `nix develop ~/nixos-config#python -c zsh`，也提供 `#rust`、`#cpp`。
仓库默认 Shell 包含 Nix 配置工具和 `nixos-anywhere`，不提供语言工具链或 CUDA Toolkit。

### Pi

```sh
cd ~/projects/your-project
nix develop -c pi
# Pi 内：/login 登录，/model 选择模型
```

Pi 及扩展由 `modules/services/pi/` 声明，WSL 与笔记本共用；修改后 rebuild 并重启 Pi。
认证、会话和个人设置保存在 `~/.pi/agent`，不要提交到 Git。

| 功能 | 入口 |
| --- | --- |
| 计划模式 | `/plan` 切换，`/todos` 查看步骤 |
| 问答 | 请模型使用 `questionnaire` 确认需求 |
| 交互程序 | `!nvim README.md`、`!lazygit` |
| 语言服务 | `/lsp` 查看状态；从项目 PATH 加载语言工具 |
| NixOS MCP | `/mcp` 查看；终端执行 `pi mcp list` 检查连接 |
| 网页搜索 | 请模型调用 `web_search`；Gemini / Ollama Cloud 另提供 `url_context` |
| 界面设置 | `/open-tui`；个人偏好保存在 `open-tui.json` |

NixOS MCP 使用各主机的配置仓库作为工作目录，不依赖 WSL 的 `/opt` 安装。
Nix 声明会合并到个人设置，受管理项以仓库为准；移除 MCP 声明后，
如需清理旧连接，执行 `pi mcp remove nixos`。

> Pi 使用当前用户权限，计划模式不是系统级沙箱。密钥应留在认证文件或环境变量中。

#### 网页搜索

`pi-web-search` 固定为 `1.7.0`，由 `packages/pi-web-search/` 下载并校验，
通过 `modules/services/pi/web-search.nix` 加载；不需要再执行 `pi install`。
rebuild 并重启 Pi 后，可输入“请搜索最新的 NixOS 安装文档并附来源”来使用 `web_search`。

默认使用当前对话模型及其 Pi 认证；用 `/model` 选择支持原生搜索的模型，
通过 `/login` 或对应提供商的 API key 环境变量完成认证。
支持 Gemini、OpenAI Responses（含 Codex / Azure / Copilot）、xAI、Anthropic、DeepSeek、
Ollama Cloud 及部分 OpenCode 模型。第三方中转也必须支持相应的原生搜索 API；
仅兼容 Chat Completions 不够。搜索会产生提供商的请求 / 搜索费用，并可能继承当前思考等级。

如需将搜索与对话模型分开，在 `~/.pi/agent/web-search.json` 中手动指定，例如：

```json
{
  "provider": "openai",
  "model": "gpt-5.1"
}
```

所选模型必须已在 Pi 注册、认证且支持原生搜索；按自己的可用模型修改示例。
该文件保留为个人配置，不由 Nix 覆盖；修改 `PI_CODING_AGENT_DIR` 时放在对应 agent 目录下。
未指定时不会自动寻找其他模型，不支持搜索的当前模型会直接报错。
`url_context` 跟随当前对话模型，仅 Gemini / Ollama Cloud 可用，不是通用网页抓取器。
不要同时加载其他注册同名 `web_search` 工具的扩展；密钥不要写进此文件、仓库或 Nix store。

### LazyVim

配置位于 `home/nvim/`，修改后 rebuild。Mason 自动下载已禁用，
语言工具从项目环境读取；常用 Tree-sitter 解析器由 Nix 提供。

`Space` 是 Leader，以下为普通模式常用键；按空格后稍等可查看完整提示。

| 快捷键 | 操作 |
| --- | --- |
| `Space Space` / `Space /` | 查找文件 / 搜索项目内容 |
| `Space e` / `Space ,` | 文件树 / 已打开的缓冲区 |
| `gd` / `gr` / `K` | 定义 / 引用 / 文档 |
| `Space c a` / `Space c r` | 代码操作 / 重命名符号 |
| `Space c f` / `Space u f` | 格式化 / 切换自动格式化 |
| `[d` / `]d` | 上个 / 下个诊断 |
| `Shift+h` / `Shift+l` | 上个 / 下个缓冲区 |
| `Space b d` | 关闭缓冲区，不删除文件 |
| `Space -` / `Space \|` | 向下 / 向右分屏 |
| `Ctrl+h/j/k/l` | 切换窗口 |
| `Space g g` | Lazygit |
| `Space u w` | 切换折行 |
| `Space s k` / `Space c l` | 搜索键位 / 查看 LSP 状态 |

插入模式下，`Ctrl+Space` 打开补全，`Ctrl+n/p` 选择，`Enter` 接受已选项，
`Tab` / `Shift+Tab` 跳转代码片段占位符。LSP 操作需有对应语言服务。

LazyVim 和 lazy.nvim 由 Flake 锁定，其余插件锁在 `~/.local/state/nvim/lazy-lock.json`。
重装时可将 `home/nvim/lazy-lock.snapshot.json` 复制到该位置，再执行 `:Lazy restore`。
完整键位见 [LazyVim 文档](https://www.lazyvim.org/keymaps)。

### 终端分屏与会话

- **WSL（onyx）**：安装 Zellij，执行 `zellij` 手动启动。不自动进入会话，不托管
  Zellij 配置；需要时自行配置 `~/.config/zellij/config.kdl`。
- **笔记本（obsidian）**：使用 Ghostty 自带标签页与分屏，不额外安装终端多路复用器。
- 开发角色不再安装或配置 tmux；VPS 代理角色仍保留 tmux。

Ghostty 的 Linux 默认快捷键：

| 快捷键 | 操作 |
| --- | --- |
| `Ctrl+Shift+o` / `Ctrl+Shift+e` | 向右 / 向下分屏 |
| `Ctrl+Alt+方向键` | 切换分屏焦点 |
| `Ctrl+Shift+Enter` | 当前分屏最大化 / 恢复 |
| `Ctrl+Shift+t` | 新建标签页 |

可用 `ghostty +list-keybinds --default` 查看当前版本默认键位。
Ghostty 分屏不等同于后台会话保持；需要断开终端后继续运行任务时，再考虑 Zellij 等工具。

### Docker

开发角色启用原生 Docker Engine、Compose 与 Buildx，VPS 代理角色不启用。

```sh
docker run --rm hello-world
docker compose up -d               # 在含 compose.yaml 的项目中执行
docker compose logs -f
docker compose down
docker system df
```

配置位于 `modules/services/docker.nix`：Docker Hub 镜像源为
`https://docker.m.daocloud.io`，日志使用 `local` 驱动（10 MB × 3），不自动清理镜像或卷。
用户属于 `docker` 组，**该组具有近似 root 的宿主机控制权限**；加入组后需重新登录。

WSL daemon 继承系统代理，容器内部不自动继承；容器内的 `127.0.0.1` 不是宿主机。
GPU 容器运行时未启用，需要另配 NVIDIA Container Toolkit。

## 桌面与主题

obsidian 使用 MangoWM + Noctalia，Ghostty 为终端，Vicinae 为启动器，PCManFM（GTK 3 版）为默认文件管理器。
PCManFM 配套启用 GVfs（回收站与远程文件访问）和 UDisks2（可移动设备支持），使用自身的缩略图功能。
PCManFM 只以文件管理模式运行，不启用 `pcmanfm --desktop`。
共享主题为 Catppuccin Mocha / Mauve，界面字体为 Noto Sans，终端字体为 JetBrainsMono Nerd Font。
obsidian 的 UEFI 引导使用 GRUB，独立采用 sleek-grub-theme 的 light 变体（Sleek-theme-light）。
游戏环境启用 Steam、RTX 5060 Laptop 的 NVIDIA beta 驱动（开源内核模块）及 32 位 OpenGL / Vulkan 支持，
按独显直连使用，不配置 PRIME 双显卡切换。Windows 游戏在 Steam「设置 → 兼容性」中启用 Steam Play / Proton；
具体游戏的兼容性和反作弊限制仍需逐一确认。

| 修改内容 | 配置位置 |
| --- | --- |
| GRUB 引导与 Sleek light 主题 | `modules/profiles/laptop.nix` |
| 色板、字体与主题名称 | `lib/theme.nix` |
| 终端、命令行与编辑器配色 | `home/theme.nix`、`home/nvim/` |
| 窗口管理与快捷键 | `home/mango/config.conf` |
| 面板、通知、锁屏、文件管理器、Steam | `hosts/obsidian/desktop.nix` |
| RTX 5060 Laptop beta 驱动与 32 位图形支持 | `hosts/obsidian/graphics.nix` |
| GTK / Qt 外观 | `hosts/obsidian/appearance.nix` |
| 启动器 | `hosts/obsidian/vicinae.nix` |

| 快捷键 | 操作 |
| --- | --- |
| `Super+Enter` / `Super+Space` | 终端 / 启动器 |
| `Super+E` | PCManFM 文件管理器 |
| `Super+S` / `Super+,` | 控制中心 / 设置 |
| `Super+L` | 锁屏 |
| `Super+Q` / `Super+F` | 关闭窗口 / 全屏 |
| `Super+方向键` | 切换焦点；加 Shift 移动窗口 |
| `Super+1–9` | 切换工作区；加 Shift 移动窗口 |
| `Super+R` / `Super+Shift+E` | 重载窗口配置 / 退出会话 |

空闲 10 分钟锁屏、11 分钟熄屏，挂起前锁屏，不自动定时挂起。
主题修改后 rebuild，必要时重启应用；Noctalia 的应用主题写入功能已关闭，避免覆盖 hjem 文件。

## WSL

Windows 中的发行版注册名为 `NixOS`，与 Linux 主机名 `onyx` 不同。

WSL 的终端文件管理器为 Yazi，仅在 `onyx` 启用，配置位于 `home/yazi.nix`。
主题使用 `lib/theme.nix` 的 Catppuccin Mocha 色板和 Mauve 强调色，由 hjem 生成
`~/.config/yazi/theme.toml`，无需手动下载 flavor。

- `y` / `y 路径`：打开 Yazi，按 `q` 退出后终端跟随到所在目录；`Q` 退出但不切换目录。
- `yazi`：直接启动，不改变父 shell 的目录。
- `h/j/k/l` 导航，空格选择，`~` 查看快捷键帮助。
- 文件图标需要在 **Windows 终端**中选择 Nerd Font（如 JetBrainsMono Nerd Font）。
  图片预览效果取决于终端的图像协议支持。

- Windows `.wslconfig` 使用 `networkingMode=mirrored`。
- 命令行、nix-daemon 和 Docker daemon 使用 `http://127.0.0.1:7890`；先启动 Windows 代理。
- 代理端口统一在 `modules/wsl/network.nix` 修改，不用于原生笔记本或 VPS。
- Windows PATH 导入已关闭；`/mnt/c`、剪贴板、GPU 桥接和显式 `.exe` 路径仍可用。
- 项目建议放在 `~/projects`。`nvidia-smi` 显示的是驱动支持能力，不代表安装了 CUDA Toolkit。

更改 WSL 自身设置后，保存工作并从 PowerShell 重启发行版：

```powershell
wsl --terminate NixOS
wsl -d NixOS
```

### Windows Codex MCP

这是独立于 Pi 的 MCP 环境，Windows 端启动命令为：

```text
wsl.exe -d NixOS -- /opt/mcp-nixos/bin/mcp-nixos
```

依赖锁位于 `mcp/requirements-lock.txt`，解释器有独立的 Nix GC root。
重装使用 `sudo bash ~/nixos-config/scripts/install-mcp.sh`，然后重启 Codex 或重新加载 MCP。

## Zsh 历史保护

历史位于 `~/.local/state/zsh/history`。新终端启动时检查历史，保留两份有效快照；
损坏原件保存为 `history.corrupt-*`。无有效备份时暂停当前会话的磁盘历史写入。
配置在 `home/zsh/`，WSL 和笔记本共用，更新后执行 `exec zsh`。
历史和快照可能包含敏感命令，应按私人数据保管；这项保护不能替代备份。
