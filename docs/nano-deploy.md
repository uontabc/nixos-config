# nano · VPS 部署

[← 返回首页](../README.md)

用于 VLESS + REALITY + Vision 代理节点，配置入口为 `hosts/nano/`。
当前是**未来整盘重装模板**，主机清单未启用，不用于原地转换现有系统。

## 安装前检查

> Disko 配置会重建目标磁盘布局。先备份数据、确认救援入口，再准备安装；
> 不要在仍需保留的运行系统根磁盘上执行初始化。

启用前完成以下事项：

1. 确认 CPU 架构，在 `hosts/default.nix` 中选择 `x86_64-linux` 或 `aarch64-linux`。
2. 在 `hosts/nano/machine.nix` 填写 `fleet.storage.vps.disk`，使用现场确认的整盘 by-id 路径。
3. 填写 `firmware = "uefi"` 或 `"bios"`；BIOS 模板仅适用于 x86。
4. 导入云平台硬件与网络配置，声明 SSH 服务、登录账号和公钥。
5. 为新安装设置 `system.stateVersion`，确认目标上的仓库位置 `configRoot`。
6. 完成核对后移除 `machine.nix` 中人为的安装保护，取消 nano 清单注释。

布局为未加密 ext4 根分区：UEFI 增加 1 GiB ESP，BIOS 增加 1 MiB BIOS boot 分区。
UEFI 使用 GRUB removable 路径，不依赖可写 NVRAM。
不能照搬 carbon 的分区级流程；核对配置后可从本地通过以下 nixos-anywhere 流程安装。

## 使用 nixos-anywhere 远程安装

> **以下安装命令会擦除 `fleet.storage.vps.disk` 指定的整盘，并重启 VPS。**
> 仅用于已备份、允许整盘重装的 nano；不要用于 carbon、WSL 或日常更新。
> 保留云平台控制台 / 救援入口，以便修复网络或引导失败。

### 准备配置和连接

在装有 Nix 的本地 Linux（包括 WSL2）上运行，启用 `nix-command flakes`。
工具随仓库的 nixpkgs 锁定，无需添加独立输入或更新 `flake.lock`。
远端需要 SSH 可达，使用 root 或可免密 sudo 的用户，具备有线 / 云网络和外网访问能力。
普通 Linux 救援系统需要支持 kexec，且至少有 1.5 GiB 内存（不含 swap）；
不支持 kexec 时先从云平台启动 NixOS 安装介质，再通过 SSH 安装。

先在救援环境检查架构、磁盘与固件，不根据设备编号猜测目标盘：

```sh
ssh root@VPS_IP
uname -m
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/
test -d /sys/firmware/efi && echo UEFI || echo BIOS
exit
```

此处 SSH 用户和密钥属于**当前救援系统**，不等于新系统的登录配置。
完成上方安装前检查，在 `machine.nix` 中导入实际硬件 / 云平台网络配置，
并显式配置新系统的 SSH 服务和公钥，例如：

```nix
services.openssh.enable = true;
services.openssh.settings.PermitRootLogin = "prohibit-password";
users.users.root.openssh.authorizedKeys.keys = [ "替换为你的完整 SSH 公钥" ];
```

只将公钥写入配置，私钥留在本地。若不允许 root 登录，应改配普通用户、相应公钥与 sudo 策略。
不要依赖救援系统的临时 IP 配置自动保留；按云平台要求声明 DHCP / 静态地址、网关与 DNS，
并确认云防火墙放行 SSH。硬件文件应来自真实目标或云平台模块，不要复制 graphene 的配置。

取消 nano 清单注释、移除人为安装保护后，在本地仓库预检：

```sh
cd ~/nixos-config
# 先检查没有私钥等秘密，再暂存新增的主机配置，供 Git Flake 读取
git add hosts/nano hosts/default.nix
nix eval --raw .#nixosConfigurations.nano.config.networking.hostName
nix eval --json .#nixosConfigurations.nano.config.assertions \
  --apply 'xs: map (x: x.message) (builtins.filter (x: !x.assertion) xs)'
nix run .#nixos-anywhere -- --help
```

预期主机名为 `nano`、失败断言为 `[]`。硬件配置应已就绪并被导入。
本地与 VPS 同架构时，建议先执行 `nix build --no-link .#nixosConfigurations.nano.config.system.build.toplevel`；
需要原生构建器或模拟器的跨架构构建不能仅靠修改 `system` 完成。

### 执行首次安装

确认备份、整盘路径和新系统登录配置无误后，替换 IP 与本地私钥路径再执行：

```sh
nix run .#nixos-anywhere -- \
  --flake .#nano \
  --target-host root@VPS_IP \
  -i ~/.ssh/id_ed25519
```

该命令默认依次执行 kexec、Disko 分区格式化、系统安装和重启；
已在受支持的 NixOS 安装环境中时会跳过 kexec。
若 SSH 不使用 22 端口，增加 `--ssh-port PORT`；kexec 后安装环境默认使用 22，需同时允许该端口访问。
本地与目标架构不同或希望在远端构建时可增加 `--build-on remote`，
但远端安装环境仍需足够的内存、磁盘空间和网络。ARM 的引导与镜像支持也需按云平台验证。
可先用 `--vm-test` 在具备虚拟化支持的本地环境测试配置，但它不能验证真实硬件、云网络或磁盘选择。

安装不会把完整源码仓库自动部署到 `configRoot`。重启后先通过云控制台核对 SSH 主机指纹，
如指纹改变，确认是此次重装后再清理本地旧 `known_hosts` 条目，重新登录：

```sh
ssh root@VPS_IP
hostname
systemctl --failed
exit
# 将完整仓库（含 flake.lock 和本次主机配置，不含私钥）同步到 configRoot
tar --exclude='./.git' -czf - . | \
  ssh root@VPS_IP 'mkdir -p /etc/nixos && tar -xzf - -C /etc/nixos'
```

默认 `configRoot` 为 `/etc/nixos`；如清单中已修改，替换同步路径。
随后按下一节生成 REALITY 凭据并执行 `sudo systemctl restart sing-box`。
凭据准备前 sing-box 可能启动失败，不要把它误认为系统安装失败。
安装中断时先检查目标当前环境和已完成阶段，**不要盲目重跑默认命令再次擦盘**；
修复已安装系统或后续更新应使用救援流程 / nixos-rebuild，而不是重新初始化磁盘。

## REALITY 凭据

修改 `hosts/nano/proxy.nix` 设置监听端口、握手域名和凭据目录：

| 项目 | 默认值 |
| --- | --- |
| TCP 端口 | `443` |
| 握手域名 / SNI | `www.microsoft.com`，需确认 VPS 可达 |
| 流控 | `xtls-rprx-vision` |
| 凭据目录 | `/var/lib/sing-box-secrets` |

首次启动代理服务前在 VPS 生成凭据（nixos-anywhere 安装后可立即执行）。假设仓库位于 `/etc/nixos`：

```sh
sudo nix --extra-experimental-features 'nix-command flakes' shell \
  --inputs-from path:/etc/nixos nixpkgs#sing-box nixpkgs#python312 \
  -c python3.12 /etc/nixos/scripts/init-reality.py
```

脚本创建 `uuid`、`private-key`、`public-key`、`short-id`，已有凭据不会被覆盖。
目录权限为 0700，文件为 0600；服务启动时读取秘密，私钥不进入 Nix store 或 Git。
系统安装完成后也可使用 `sudo reality-init`。

云平台入站规则需放行所选 TCP 端口。客户端填写 VPS 地址、端口、UUID、相同的 SNI、
REALITY 公钥、short ID 与 `xtls-rprx-vision`；**私钥仅留在 VPS**。

## 安装后的更新

以下命令用于已安装、SSH 可达的 nano，**不会执行 Disko，也不会同步仓库**：

```sh
nixos-rebuild build --flake .#nano
nixos-rebuild switch --flake .#nano --target-host USER@VPS_IP --sudo
```

跨架构构建可增加 `--build-host USER@VPS_IP`。若在远端直接运行 `rebuild`，
先将完整仓库同步到主机清单配置的 `configRoot`（模板为 `/etc/nixos`）。

```sh
sudo systemctl status sing-box
sudo journalctl -u sing-box -e
```

## 参考

[VLESS](https://sing-box.sagernet.org/configuration/inbound/vless/) ·
[REALITY](https://sing-box.sagernet.org/configuration/shared/tls/#reality-fields) ·
[Disko](https://github.com/nix-community/disko) ·
[nixos-anywhere 快速入门](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md) ·
[nixos-anywhere 参数](https://github.com/nix-community/nixos-anywhere/blob/main/docs/reference.md)
