# carbon · 保留 Windows 的 NixOS 双系统安装指南

[← 返回首页](../README.md)

本指南用于在 **Lenovo 83LT / Ryzen 9 8940HX / RTX 5060 Laptop** 上保留现有 Windows，
仅使用从 C: 压缩出的约 512 GiB 空间安装 NixOS。

> **当前状态：待安装模板，不是已经完成的实机安装记录。**
> `carbon` 默认未在 `hosts/default.nix` 启用，Linux 分区 PARTUUID 留空，
> `hosts/carbon/machine.nix` 中保留阻止误安装的断言。
> 本文中的分区路径必须现场填写；显卡、无线网络、引导和挂起唤醒需要实机验证。

## 目录

- [0. 先了解安装方案与安全边界](#0-先了解安装方案与安全边界)
- [1. 在 Windows 中备份并腾出空间](#1-在-windows-中备份并腾出空间)
- [2. 准备安装介质与配置副本](#2-准备安装介质与配置副本)
- [3. 进入 Live 环境并检查联网](#3-进入-live-环境并检查联网)
- [4. 核对磁盘并创建两个 Linux 分区](#4-核对磁盘并创建两个-linux-分区)
- [5. 填写硬件配置和主机清单](#5-填写硬件配置和主机清单)
- [6. 格式化前进行配置预检](#6-格式化前进行配置预检)
- [7. 首次创建文件系统并挂载](#7-首次创建文件系统并挂载)
- [8. 准备持久化状态和登录密码](#8-准备持久化状态和登录密码)
- [9. 安装 NixOS 并保存配置](#9-安装-nixos-并保存配置)
- [10. 重启前核对 GRUB、Windows 和挂载](#10-重启前核对-grubwindows-和挂载)
- [11. 首次启动验收](#11-首次启动验收)
- [12. 安装后的维护与备份](#12-安装后的维护与备份)
- [13. 故障定位与 Live 救援](#13-故障定位与-live-救援)
- [14. 配置入口与参考资料](#14-配置入口与参考资料)

## 0. 先了解安装方案与安全边界

### 0.1 最终布局

| 项目 | 本仓库的选择 |
| --- | --- |
| 主机名 / Flake 目标 | `carbon` / `.#nixosConfigurations.carbon` |
| 用户 | `uontabc`，UID `1000`，主组 GID `100` |
| 固件与引导 | UEFI + GRUB；本配置不支持 Secure Boot |
| 引导主题 | `sleek-grub-theme` 的 `light` 变体，即 Sleek-theme-light |
| Windows | 保留现有系统、数据、ESP、MSR 和恢复分区 |
| 新 Linux 引导分区 | 1 GiB FAT32，挂载到 `/boot` |
| 新 Linux 根分区 | 剩余空间，Btrfs，不加密 |
| 持久化 | `/home`、`/nix`、`/persist` 各自使用独立 Btrfs 子卷 |
| 根目录 | 每次启动重建 `@root`，只保留声明过的系统状态 |
| 桌面 | greetd + MangoWM + Noctalia |

引导文件分工如下，不需要扩大或格式化 Windows ESP：

```text
原有 Windows ESP → /efi
├── EFI/Microsoft/Boot/bootmgfw.efi   Windows 原有引导程序
└── EFI/<NixOS 对应目录>/grubx64.efi GRUB EFI 程序

新 Linux 引导分区 → /boot
├── grub/                           GRUB 菜单和 Sleek light 主题
└── kernels/                        NixOS 内核与 initrd

新 Linux Btrfs 分区
├── @root    → /                    每次启动重建
├── @home    → /home                 保留个人文件和配置仓库
├── @nix     → /nix                  保留 Nix store 和系统代
└── @persist → /persist              保留密码哈希和系统状态白名单
```

GRUB 启用 Windows 自动探测，保留最多 5 个 NixOS 系统代，菜单等待 5 秒。
自动探测不是引导成功保证：重启前仍要检查实际生成的菜单。

### 0.2 哪些操作会写磁盘？

| 操作 | 作用 | 使用时机 |
| --- | --- | --- |
| `lsblk`、`blkid`、`nix eval` | 查看设备或求值，不格式化目标磁盘 | 检查阶段 |
| `nix build --dry-run` | 评估构建需求，不执行系统构建或安装 | 配置预检 |
| `cfdisk` 中的 **Write** | 写入分区表 | 仅在空闲区域创建新分区时 |
| Disko `--dry-run` | 构建并输出脚本路径，不执行磁盘操作 | 每次真正操作前审阅脚本 |
| Disko `--mode format,mount` | 创建所需文件系统并挂载，可能写入新 Linux 分区 | **仅首次安装确认过的空分区** |
| Disko `--mode mount` | 挂载已有文件系统，不执行格式化步骤 | 安装中断后的重新挂载、救援 |
| `nixos-install` | 安装系统、生成菜单、写入 GRUB EFI 程序和固件启动项 | 文件系统与状态准备好之后 |
| `rebuild` | 构建并应用系统配置，不执行 Disko 格式化 | 安装后的日常维护 |

**不可跨越的安全边界：**

- 不删除、移动、格式化 Windows、ESP、MSR、Recovery 分区。
- 不把整盘路径填入 `rootPartition`、`bootPartition` 或 `espPartition`。
- 不使用 nano 的整盘安装模板，也不对 carbon 执行 `nixos-anywhere`。
- 不使用 Disko 的 `destroy`、`destroy,format,mount` 或旧别名 `disko`。
- `destroy = false` 和分区标签检查只是防误操作措施，**不是数据无损保证**。
- 中途报错就停止当前阶段，不通过删除断言、清空磁盘或重新格式化来“试一下”。

### 0.3 命令在哪执行？

- 标注 **Windows 管理员 PowerShell**：在 Windows 中执行。
- 标注 **现有 WSL**：只用于打包配置，不在 WSL 中操作笔记本分区或安装引导器。
- 第 3～10 节：默认在 **安装 U 盘的 Live 环境 root Bash** 中执行。
- 第 11～12 节：在 **安装完成后的 carbon** 中执行。
- 命令中的 `实际…`、`REPLACE_WITH_…` 都是占位符，必须替换；不要整段盲目粘贴。

## 1. 在 Windows 中备份并腾出空间

### 1.1 先备份，再改固件或分区

开始前确认：

- [ ] 重要文件已备份到另一块磁盘或其他独立存储，且抽查能够打开。
- [ ] 如启用 BitLocker / 设备加密，恢复密钥已保存到本机以外，且能取回。
- [ ] 已准备 Windows 恢复途径和 NixOS 安装 U 盘。
- [ ] 笔记本接通电源，不依赖低电量电池执行安装。

在 **Windows 管理员 PowerShell** 检查加密状态：

```powershell
manage-bde -status C:
```

仅在 C: 已启用 BitLocker 保护时暂停保护：

```powershell
Suspend-BitLocker -MountPoint 'C:' -RebootCount 0
```

`RebootCount 0` 表示不会按重启次数自动恢复，双系统验证完后需要手动恢复。
暂停保护不等于解密，也不能代替恢复密钥备份。

### 1.2 关闭休眠与快速启动

仍在管理员 PowerShell 执行：

```powershell
powercfg /hibernate off
```

避免 Linux 访问处于休眠或快速启动状态的 Windows 文件系统。
不要在 Windows 未完全关机时强制从 Linux 读写其 NTFS 分区。

### 1.3 压缩 C:，留下未分配空间

打开“磁盘管理”，对 C: 执行“压缩卷”，计划释放约 **524288 MiB / 512 GiB**。
实际可释放大小以 Windows 报告和剩余使用需求为准，不要求为了凑整数牺牲 Windows 空间。

压缩完成后：

- 新区域必须保持 **未分配**。
- 不创建 NTFS 卷，也不合并、删除其他分区。
- 记录磁盘型号、总容量、现有分区顺序和释放空间大小，最好保存截图。
- 若压缩空间不足，先在 Windows 中处理；不要在安装过程中临时缩小现有分区。

**本阶段检查点：** Windows 仍可正常使用，重要数据和恢复密钥均有独立备份。

## 2. 准备安装介质与配置副本

### 2.1 准备 U 盘与 UEFI 设置

从 [NixOS 官网](https://nixos.org/download/) 下载近期的 **x86_64-linux 图形安装镜像**，
按官方方式制作启动 U 盘。图形镜像更便于查看本文、联网和编辑配置。

进入固件设置：

1. 在完成 BitLocker 准备后关闭 Secure Boot；本仓库没有配置签名引导。
2. 保留 UEFI 模式，不切换 Legacy / CSM。
3. 不随意改变存储控制器模式、RAID / AHCI 或其他与本次安装无关的选项。
4. 从固件启动菜单选择 U 盘的 **UEFI 启动项**。

### 2.2 提前准备私有仓库副本

`uontabc/nixos-config` 是私有仓库，Live 环境不能默认通过匿名 HTTPS 克隆。
**推荐先在现有 WSL 中导出已提交的配置，带到安装环境**，这样不用临时搬运 GitHub 私钥。

在 **现有 WSL** 中执行：

```sh
cd ~/nixos-config
git status --short
git log -1 --oneline
git archive --format=tar.gz --output="$HOME/carbon-config.tar.gz" HEAD
sha256sum "$HOME/carbon-config.tar.gz"
```

注意：

- `git archive ... HEAD` **只导出已提交文件**，不包含未提交修改或未跟踪文件。
- 先确认使用的是你准备安装的提交，归档中必须有 `flake.lock`。
- 把 `carbon-config.tar.gz` 和校验值保存到 Live 环境能访问的存储，如另一只数据 U 盘。
- 不要往已经制作好的启动盘上随意重新分区；使用其可写数据区或另一存储。
- 不复制 `~/.ssh`、`~/.pi/agent`、Token、浏览器认证文件或密码文件到仓库。

也可以在已经登录的浏览器下载 GitHub 源码归档，或者在 Live 环境自行完成 GitHub 认证后克隆。
本文后续统一假设配置位于 **`/root/nixos-config`**，不依赖获取方式。

## 3. 进入 Live 环境并检查联网

### 3.1 确认真实硬件、权限和启动模式

打开终端，进入 root Bash：

```sh
sudo -i
bash
export NIX_CONFIG='experimental-features = nix-command flakes'
test -d /sys/firmware/efi && echo 'UEFI OK'
uname -m
```

必须看到 `UEFI OK` 和 `x86_64`。
没有 `/sys/firmware/efi` 时，先重新以 UEFI 模式启动 U 盘，不继续安装 GRUB。

### 3.2 联网与时间检查

优先通过安装环境的图形菜单联网。若介质提供 NetworkManager，也可执行：

```sh
nmcli device status
nmcli --ask device wifi connect '实际 Wi-Fi 名称'
timedatectl status
curl -I https://cache.nixos.org
```

有线已联网时不需要执行 Wi-Fi 连接命令。若出现证书错误，先检查系统时间和网络。
这些命令不是要求所有安装镜像都必须运行相同的网络服务；无 `nmcli` 时按介质提供的联网方式操作。

**不要沿用 WSL 的 `http://127.0.0.1:7890`。** 原生 Linux 中这个地址指向笔记本本身，
不是 Windows 里的代理程序。若必须使用代理，填写 Live 环境实际可达的地址。

### 3.3 导入配置副本

用文件管理器或 `lsblk -f` 找到数据 U 盘的挂载位置，核对归档校验值。
把下面路径替换为实际路径：

```sh
ARCHIVE='/实际挂载位置/carbon-config.tar.gz'
test -f "$ARCHIVE"
sha256sum "$ARCHIVE"
install -d -m 0755 /root/nixos-config
tar -xzf "$ARCHIVE" -C /root/nixos-config
cd /root/nixos-config
test -f flake.nix && test -f flake.lock && echo '配置文件齐全'
```

这里的归档指上一节 `git archive` 生成、没有外层目录的归档。
GitHub 下载的 ZIP / TAR 通常带仓库外层目录，解压后需把实际仓库根目录放到 `/root/nixos-config`，
不能让 `flake.nix` 再套一层。

缺少 Git 等工具时，先进入临时环境；此时配置已存在，可以沿用其锁定输入：

```sh
nix shell --inputs-from . nixpkgs#git nixpkgs#util-linux nixpkgs#btrfs-progs \
  nixpkgs#efibootmgr nixpkgs#ripgrep nixpkgs#pciutils -c bash
```

这是临时 Bash，不是修改目标系统。后续仍保持 root 身份、工作目录 `/root/nixos-config`。
不要在操作中运行 `nix flake update`；保留带来的 `flake.lock`。

若使用不含 `.git` 的归档，初始化 Git，再把核对过的源码加入索引：

```sh
test -d .git || git init
# 先检查文件列表中没有私人文件
git status --short
git add .
```

Git Flake 只读取纳入跟踪的文件。接下来生成硬件文件后，还需要再次 `git add`。

## 4. 核对磁盘并创建两个 Linux 分区

### 4.1 确定整盘与现有分区

先只查看，不写盘：

```sh
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,PARTTYPE,PARTUUID,MOUNTPOINTS
lsblk -d -o NAME,MODEL,SERIAL,SIZE,TRAN
ls -l /dev/disk/by-id/
```

按 **型号、容量、序列号、现有 Windows 分区和空闲空间** 识别内置磁盘。
不要仅凭 `nvme0n1`、`sda` 等枚举编号判断，也不要误选启动 U 盘。

为后面的分区工具设置整盘变量：

```sh
CARBON_DISK='/dev/disk/by-id/REPLACE_WITH_VERIFIED_INTERNAL_DISK'
test -b "$CARBON_DISK"
lsblk -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL,PARTTYPE,PARTUUID "$CARBON_DISK"
sfdisk --dump "$CARBON_DISK" > /root/carbon-partitions-before.sfdisk
```

把分区表记录复制到独立存储。这个文件只是布局记录，**不是数据备份**，也不要在故障时盲目回写。

### 4.2 只在未分配空间中新建分区

目标布局：

| 分区 | 大小 | GPT 类型 | GPT PARTLABEL | 文件系统与挂载 |
| --- | --- | --- | --- | --- |
| 原有 Windows ESP | 约 200 MiB，以实机为准 | 保持原状 | 保持原状 | 原有 FAT32 → `/efi`，不格式化 |
| 新 Linux boot | 1 GiB | XBOOTLDR / EA00 | `NIXOS_BOOT` | 由 Disko 创建 FAT32 → `/boot` |
| 新 Linux root | 剩余空闲空间，约 511 GiB | Linux filesystem / 8300 | `NIXOS_ROOT` | 由 Disko 创建 Btrfs |

执行：

```sh
cfdisk "$CARBON_DISK"
```

在界面中按顺序操作：

1. 找到 Windows 中压缩出的 **Free space**，核对大小。
2. 在其中创建 1 GiB 分区，Type 选择 **Linux extended boot / XBOOTLDR**。
3. 使用 Name 将其 GPT **PARTLABEL** 设置为 `NIXOS_BOOT`。
4. 用剩余空闲空间创建 Linux filesystem 分区，PARTLABEL 设置为 `NIXOS_ROOT`。
5. 逐项对照原布局，确认 Windows、ESP、MSR、Recovery 的起止扇区与容量未变。
6. 只有全部确认后才选择 **Write**，按提示确认，再退出。

这里的 **PARTLABEL 是 GPT 分区名称，不是文件系统 LABEL**。
当前安全检查依赖精确的 `NIXOS_BOOT`、`NIXOS_ROOT`，大小写也要一致。

独立 `/boot` 沿用 XBOOTLDR 类型 GUID：

```text
bc13c2ff-59e6-4262-a352-b275fd6f7172
```

这是本仓库分区模板和检查脚本的约定；**GRUB 本身不要求 XBOOTLDR 类型**。
不需要额外创建 BIOS boot 分区，也不需要再建一块 ESP。

若工具要求新建整张分区表、看不到 Windows 分区，或空闲区域与计划不符：**退出，不写入**。

### 4.3 记录三个 PARTUUID 并核对 ESP

```sh
udevadm settle
lsblk -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL,PARTTYPE,PARTUUID "$CARBON_DISK"
```

填写一份记录：

| 配置字段 | 实际设备 | 实际 PARTUUID |
| --- | --- | --- |
| `rootPartition` | 新 `NIXOS_ROOT` 分区 | 现场填写 |
| `bootPartition` | 新 `NIXOS_BOOT` 分区 | 现场填写 |
| `espPartition` | 原有 Windows ESP | 现场填写 |

三者必须是同一块目标磁盘上的 **三个不同分区**。
模板现有 ESP PARTUUID 是历史记录，不能跳过现场核对。

建议先以只读方式确认 ESP 上确实存在 Windows 引导文件：

```sh
ESP_PART='/dev/disk/by-partuuid/实际-Windows-ESP-PARTUUID'
install -d -m 0755 /run/carbon-esp-check
mount -o ro "$ESP_PART" /run/carbon-esp-check
test -f /run/carbon-esp-check/EFI/Microsoft/Boot/bootmgfw.efi \
  && echo 'Windows EFI 文件存在'
umount /run/carbon-esp-check
```

文件不存在时先排查是否选错 ESP，不创建、覆盖或格式化它。
**此阶段不执行 `mkfs`；新 Linux 分区的文件系统由第 7 节创建。**

## 5. 填写硬件配置和主机清单

### 5.1 生成本机硬件配置

确认仍在 Live 环境、仓库根目录：

```sh
cd /root/nixos-config
nixos-generate-config --no-filesystems --show-hardware-config \
  > hosts/carbon/hardware-configuration.nix
```

查看生成文件，核对 CPU、initrd 存储模块和平台。文件系统统一由 Disko 管理，
所以这里使用 `--no-filesystems`，不要混入旧系统的 UUID 挂载声明，也不要复制 WSL 硬件配置。

NVIDIA 当前配置使用 open 驱动，没有启用 PRIME offload。
若 Live 环境发现核显和独显，记录实际 PCI ID；不要照搬网上其他机型的 Bus ID。

### 5.2 完成 `hosts/carbon/machine.nix`

核对数据后，将该文件的模板内容替换为如下结构，三个 PARTUUID 全部使用实测值：

```nix
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  fleet.storage.laptop = {
    rootPartition = "/dev/disk/by-partuuid/实际-NIXOS_ROOT-PARTUUID";
    bootPartition = "/dev/disk/by-partuuid/实际-NIXOS_BOOT-PARTUUID";
    espPartition = "/dev/disk/by-partuuid/实际-Windows-ESP-PARTUUID";
  };
}
```

这一步只移除 `machine.nix` 中人为设置的 `assertion = false` 安装保护。
**不要移除 Disko 的分区检查或 `scripts/reset-btrfs-root.sh` 的保护逻辑。**
`fleet.storage.laptop` 是角色选项名，不需要改成 `carbon`。

### 5.3 在 `hosts/default.nix` 中启用 carbon

只取消 carbon 条目的注释，保留现有 graphene，nano 仍保持注释：

```nix
carbon = {
  system = "x86_64-linux";
  modules = [ ./carbon ];
};
```

保留 `hosts/carbon/default.nix` 中的 `system.stateVersion = "26.05"` 基线。
它不是“当前最新版本”，安装后也不要随 nixpkgs 更新而递增。

把新增硬件文件与修改纳入 Git 跟踪，然后审阅差异：

```sh
git add hosts/carbon/hardware-configuration.nix hosts/carbon/machine.nix hosts/default.nix
git diff --cached --stat
git diff --cached -- hosts/carbon/machine.nix hosts/default.nix
```

这里的暂存只用于让 Git Flake 看见文件，不要求现在登录 GitHub 或推送。

## 6. 格式化前进行配置预检

### 6.1 检查主机名、断言与引导配置

```sh
nix eval --raw .#nixosConfigurations.carbon.config.networking.hostName
nix eval --json .#nixosConfigurations.carbon.config.assertions \
  --apply 'xs: map (x: x.message) (builtins.filter (x: !x.assertion) xs)'
nix eval --raw .#nixosConfigurations.carbon.config.system.boot.loader.id
nix eval --raw .#nixosConfigurations.carbon.config.boot.loader.grub.theme
nix eval --json .#nixosConfigurations.carbon.config.fileSystems \
  --apply 'fs: builtins.mapAttrs (_: v: { inherit (v) device fsType options; }) fs'
```

逐项确认：

- 主机名为 `carbon`，失败断言为 `[]`，引导器 ID 为 `grub`。
- 主题指向 Nix store 中的 `sleek-grub-theme`；本仓库明确选择 `withStyle = "light"`。
- `/`、`/home`、`/nix`、`/persist` 来自新 Linux root 的不同 Btrfs 子卷。
- `/boot` 来自新 `NIXOS_BOOT`，`/efi` 来自原 Windows ESP。
- 没有占位符、`null` 分区或重复 PARTUUID。

`nix eval --raw` 的输出可能不自动换行，不影响结果。

### 6.2 检查系统能否求值和需要构建的内容

```sh
nix build --dry-run --no-link .#nixosConfigurations.carbon.config.system.build.toplevel
```

这一步不安装系统，也不证明所有构建都会成功；它用于提前发现求值、依赖和下载问题。
有条件时可以先完成一次实际构建：

```sh
# 可选：会下载/构建依赖，占用 Live 环境的存储或内存空间
nix build --no-link .#nixosConfigurations.carbon.config.system.build.toplevel
```

Live 环境空间不足时，不要反复尝试把完整桌面构建塞入内存；后续 `nixos-install`
会把系统安装到已挂载目标。无论选择哪条路径，所有已出现的配置错误都应先解决。

**进入下一阶段前：** 确认目标分区、配置、备份均已复核，准备操作的确实是空 Linux 分区。

## 7. 首次创建文件系统并挂载

> **本节的实际执行命令可能写入 Linux 文件系统。**
> 只用于首次安装的空分区。已有系统、安装中断重试和救援请使用第 13 节的仅挂载流程。

### 7.1 先生成脚本，不执行

```sh
nix run .#disko -- --mode format,mount --flake .#carbon \
  --root-mountpoint /mnt --dry-run
```

输出会包含 Disko 版本及生成的可执行脚本路径。用 `less` 打开实际输出的脚本路径，
必要时继续查看它引用的脚本：

```sh
less /nix/store/实际输出的脚本路径
```

必须确认：

- 只对新 root、boot 分区创建所需文件系统，没有整盘重建分区表的操作。
- `NIXOS_ROOT`、`NIXOS_BOOT` 的路径与记录一致。
- Windows ESP 只有挂载操作，没有格式化命令。
- 没有对 Windows、MSR、Recovery 的擦除或分区操作。

**Disko 的 `--dry-run` 只是输出脚本，不会模拟真实磁盘操作或证明选盘正确。**
检查脚本与实物设备是两项都必须完成的工作。

### 7.2 执行一次创建与挂载

全部确认后：

```sh
nix run .#disko -- --mode format,mount --flake .#carbon --root-mountpoint /mnt
```

如果命令失败，先根据错误排查。不要盲目重复，不添加 `--yes-wipe-all-disks`，
也不要切换为 `destroy,format,mount`。
即使已有文件系统可能被 Disko 跳过，也不应把 `format,mount` 当作救援用法。

### 7.3 核对实际挂载结果

```sh
findmnt -R /mnt
for target in /mnt /mnt/home /mnt/nix /mnt/persist /mnt/boot /mnt/efi; do
  findmnt --mountpoint "$target" -o TARGET,SOURCE,FSTYPE,OPTIONS
done
df -h /mnt /mnt/nix /mnt/boot /mnt/efi
test -f /mnt/efi/EFI/Microsoft/Boot/bootmgfw.efi && echo 'Windows 引导仍在'
```

应有：

| 挂载点 | 来源 | 本次允许创建文件系统？ |
| --- | --- | --- |
| `/mnt` | `NIXOS_ROOT` 的 `@root` | 是，仅空 Linux root |
| `/mnt/home` | 同一 Btrfs 的 `@home` | 子卷 |
| `/mnt/nix` | 同一 Btrfs 的 `@nix` | 子卷 |
| `/mnt/persist` | 同一 Btrfs 的 `@persist` | 子卷 |
| `/mnt/boot` | 新 `NIXOS_BOOT`，FAT32 | 是，仅空 Linux boot |
| `/mnt/efi` | 原有 Windows ESP，FAT32 | **否** |

容量、来源、子卷或 Windows 引导文件不符时，停止，不执行安装。

## 8. 准备持久化状态和登录密码

### 8.1 为什么不能跳过？

首次启动时，initrd 会删除并重建 `@root`。因此：

- 仓库和个人文件放 `/home`，不放 `/root` 或 `/etc/nixos`。
- Nix store 和系统代保留在 `/nix`。
- 用户状态和登录密码哈希必须先放入 `/persist`。
- 根目录重置脚本会检查 `@home`、`@nix`、`@persist` 和非空密码文件；缺失会停止启动。

这是“每次重建根目录”，不是“每次删除所有数据”，也不是备份或磁盘加密。
白名单以 `hosts/carbon/impermanence.nix` 为准；未声明的根目录数据重启会丢失。

### 8.2 在安装前绑定用户与 hjem 状态目录

```sh
for state in var/lib/nixos var/lib/hjem; do
  install -d -m 0755 "/mnt/persist/$state" "/mnt/$state"
  if ! mountpoint -q "/mnt/$state"; then
    mount --bind "/mnt/persist/$state" "/mnt/$state"
  fi
done
for target in /mnt/var/lib/nixos /mnt/var/lib/hjem; do
  findmnt --mountpoint "$target" -o TARGET,SOURCE,FSTYPE,OPTIONS
done
```

绑定是为了让首次安装建立的用户 / 组分配和 hjem 状态直接进入持久化目录。
若目录已经挂载，核对其来源确实是对应的 `/mnt/persist` 路径，不叠加其他绑定。

准备一个稳定的 machine-id：

```sh
install -d -m 0755 /mnt/persist/etc /mnt/etc
if ! test -s /mnt/persist/etc/machine-id; then
  systemd-id128 new > /mnt/persist/etc/machine-id
fi
chmod 0444 /mnt/persist/etc/machine-id
install -m 0444 /mnt/persist/etc/machine-id /mnt/etc/machine-id
```

已有有效 machine-id 时不重新生成。上面的准备步骤用于首次安装；恢复已安装系统时，
先检查 `/mnt/etc/machine-id` 是否已经绑定到持久化文件，不覆盖正在绑定的同一文件。

### 8.3 交互生成普通用户密码哈希

```sh
install -d -m 0700 /mnt/persist/secrets
umask 077
PASSWORD_TMP=$(mktemp /mnt/persist/secrets/.uontabc-password.XXXXXX)
if nix shell --inputs-from . nixpkgs#mkpasswd -c mkpasswd -m yescrypt > "$PASSWORD_TMP" \
  && test -s "$PASSWORD_TMP"; then
  chmod 0600 "$PASSWORD_TMP"
  mv "$PASSWORD_TMP" /mnt/persist/secrets/uontabc-password
else
  rm -f "$PASSWORD_TMP"
  echo '密码哈希生成失败；停止安装并重做本步。' >&2
fi
```

按提示输入并记住密码；不要把密码放在命令参数里。
临时文件成功生成后才替换正式文件，避免失败时清空已有密码哈希。
如果看到失败提示，不继续下一步。

只检查文件是否存在与权限，不需要打印哈希内容：

```sh
test -s /mnt/persist/secrets/uontabc-password && echo '密码哈希已准备'
stat -c '%a %U:%G %n' /mnt/persist/secrets /mnt/persist/secrets/uontabc-password
```

预期目录 `700`、文件 `600`，所有者均为 root。
密码哈希也应当作敏感数据，不放入 Git、Nix 表达式、截图或聊天记录。

本配置使用 `users.mutableUsers = false`。今后改密码要更新持久化哈希并应用配置，
不能只执行 `passwd` 后就假定会一直保留。

## 9. 安装 NixOS 并保存配置

### 9.1 先把配置放进持久化 home

```sh
install -d -m 0755 /mnt/home/uontabc/nixos-config
cp -a /root/nixos-config/. /mnt/home/uontabc/nixos-config/
```

安装命令仍从 Live 环境的 root 所有仓库读取；目标 home 中的副本用于以后维护。
两份配置的硬件文件、PARTUUID、主机清单和 `flake.lock` 应保持一致。

### 9.2 执行安装

```sh
nixos-install --root /mnt --flake /root/nixos-config#carbon \
  --no-root-password --no-channel-copy
```

这一步下载 / 构建系统、激活目标配置并安装 GRUB。
无需手动运行 `grub-install`、`grub-mkconfig` 或 Sleek 主题的上游安装脚本。

- `--no-root-password`：不交互设置临时 root 密码；登录使用已准备的 `uontabc` 密码。
- `--no-channel-copy`：依赖由 Flake 管理，不复制 Live 环境的 channel 配置。
- 下载或构建失败：修复网络 / 配置后重跑 **这条安装命令**，不是重做分区或格式化。
- 若中途修改源仓库，安装成功后再次把修改同步到目标 home 副本。

### 9.3 交还仓库所有权

安装成功后：

```sh
chown -R 1000:100 /mnt/home/uontabc
test -f /mnt/home/uontabc/nixos-config/hosts/carbon/hardware-configuration.nix
```

UID `1000` 在 carbon 的持久化配置中已固定，GID `100` 对应默认 `users` 组。
不要把安装介质的 `/root/.ssh` 或其他认证文件顺便复制进目标仓库。

## 10. 重启前核对 GRUB、Windows 和挂载

### 10.1 检查文件和生成的菜单

```sh
test -s /mnt/persist/secrets/uontabc-password
test -f /mnt/home/uontabc/nixos-config/flake.nix
test -f /mnt/efi/EFI/Microsoft/Boot/bootmgfw.efi
find /mnt/efi/EFI -maxdepth 2 -iname 'grubx64.efi' -print
test -s /mnt/boot/grub/grub.cfg
rg 'set theme=' /mnt/boot/grub/grub.cfg
rg 'Windows Boot Manager' /mnt/boot/grub/grub.cfg
efibootmgr -v
findmnt -R /mnt
```

分别确认，不要只看最后一条命令的退出码：

- [ ] 普通用户的持久化密码文件非空。
- [ ] 目标 home 中保存了本次实际安装配置。
- [ ] Windows 的 `bootmgfw.efi` 仍存在。
- [ ] ESP 中有 GRUB EFI 程序，`/boot/grub/grub.cfg` 非空。
- [ ] 菜单设置了主题，主题资源来自本仓库选择的 Sleek light 变体。
- [ ] NixOS 启动项和系统路径正确。
- [ ] Windows 菜单项已经生成；没有生成则记录并按第 13 节排查。
- [ ] `efibootmgr -v` 中保留 Windows Boot Manager，并有 NixOS 对应启动项。

ESP 上 GRUB 的目录 / 固件显示名称以实际生成结果为准，不硬编码为 `EFI/systemd` 或某个启动标签。
安装会为 NixOS 添加 EFI 文件和启动项，不应覆盖 Windows 的 EFI 程序。

### 10.2 安全卸载并重启

确认安装成功、检查完成，关闭仍在访问 `/mnt` 的终端或文件管理器：

```sh
sync
cd /
umount -R /mnt
```

**只有卸载成功后**再执行：

```sh
reboot
```

若提示 busy，用 `findmnt -R /mnt` 和 `fuser -vm /mnt` 定位占用，先退出相关 shell / 程序。
不要为了赶进度直接使用强制或 lazy 卸载。

取出 U 盘。固件仍默认进入 Windows 时，在启动菜单选择 NixOS 对应的 GRUB 项；
不要删除 Windows Boot Manager，也不要因此重新安装或格式化。

## 11. 首次启动验收

### 11.1 登录与基础检查

确认显示 Sleek light 的 GRUB 菜单，选择 NixOS。
在 greetd / tuigreet 使用 `uontabc` 和第 8 节设置的密码登录 Mango。
登录后用 `Super+Enter` 打开终端。

以下在 **已安装 carbon 的普通用户终端**执行：

```sh
hostname
id
findmnt -t btrfs,vfat
systemctl --failed
sudo journalctl -b -u reset-btrfs-root.service
cd ~/nixos-config
nh os build --hostname carbon
```

预期主机名 `carbon`、UID `1000`，挂载与规划一致；系统构建成功。
initrd 服务日志若未按 unit 筛出，可用 `sudo journalctl -b | rg 'reset-btrfs-root|Recreate'` 查找。
不要仅凭桌面能打开就跳过挂载和启动日志检查。

### 11.2 验证 impermanence 的边界

创建两个无关紧要的测试文件：

```sh
printf 'home persists\n' > ~/impermanence-home-test
printf 'root resets\n' | sudo tee /root/impermanence-root-test >/dev/null
sudo reboot
```

再次登录后：

```sh
test -f ~/impermanence-home-test && echo 'home 保留：正常'
sudo test ! -e /root/impermanence-root-test && echo 'root 重建：正常'
rm ~/impermanence-home-test
```

任一结果不符就先排查，不用真实重要数据测试。
**根目录重建会递归删除旧 `@root` 中的数据；不要在其中存放未备份的重要文件或子卷。**

### 11.3 硬件与应用验收清单

```sh
nvidia-smi
lspci -nnk | rg -A3 'VGA|3D|Display'
nmcli device status
systemctl is-active docker
pi mcp list
```

逐项手动验证：

- [ ] 内屏正常、分辨率 / 刷新率正确，外接显示器按实际需要测试。
- [ ] Wi-Fi 重连、声音、麦克风、蓝牙可用；蓝牙默认不自动开电源。
- [ ] 触摸板、键盘、亮度快捷键、锁屏可用。
- [ ] 接电与电池模式正常，挂起后能够唤醒。
- [ ] NVIDIA 驱动正常；如需 PRIME，先确认真实 GPU 与 PCI ID 再配置。
- [ ] Docker daemon 正常；拉取镜像还需要单独验证网络 / 镜像源。
- [ ] Pi MCP 配置可加载；提供商登录、Token 等仍需用户单独配置。

未配置休眠交换分区，**挂起成功不代表休眠到磁盘可用**。
不建议一开始同时改 GPU 路由、休眠、电源策略和主题；一次改一类，方便定位问题。

### 11.4 回到 Windows 验证

通过 GRUB 的 Windows 项，或固件的 Windows Boot Manager 启动 Windows：

1. 检查 Windows 能启动、文件和分区正常。
2. 两个系统沿用本地时间 RTC 约定，不再叠加冲突的时钟调整。
3. 若此前暂停 BitLocker，在确认引导路径稳定且持有恢复密钥后，用管理员 PowerShell 恢复：

```powershell
Resume-BitLocker -MountPoint 'C:'
manage-bde -status C:
```

不建议为了本配置重新开启 Secure Boot；当前 GRUB 没有配置相应签名链。

## 12. 安装后的维护与备份

### 12.1 同步实机配置

保留并同步以下内容回主仓库：

- `hosts/carbon/hardware-configuration.nix`。
- 填入真实 PARTUUID、移除模板保护后的 `hosts/carbon/machine.nix`。
- 已启用 carbon 的 `hosts/default.nix`。
- 安装过程中确实需要的其他硬件修正。

从归档初始化的 Git 仓库可能没有原历史和远程，**不要直接把它强推覆盖 GitHub**。
可先将上述文件复制回原有 WSL 克隆，审阅差异后提交；或者在 carbon 完成 GitHub 认证后，
另行克隆远程仓库，再迁入这些文件。
公钥、私钥、密码哈希与应用 Token 不属于这些配置文件。

### 12.2 日常更新

```sh
cd ~/nixos-config
# 修改配置后先检查和构建
nix fmt
git diff
nh os build --hostname carbon
# 构建正常后再应用
rebuild
```

更新依赖时才运行 `nix flake update`，随后同样先构建再应用。
日常维护不运行 Disko `format,mount`，也不重复运行安装时的分区步骤。

需要回滚系统配置时：

```sh
sudo nixos-rebuild switch --rollback
```

回滚不恢复 `/home`、数据库、密码文件或其他持久化数据，也不会关闭根目录重建。
GRUB 菜单最多列出 5 代，垃圾回收也会影响旧代可用性，不能把它当作备份。

### 12.3 密码与持久化备份

改密码时，用 root 权限在 `/persist/secrets` 中生成新的 yescrypt 哈希，
先写权限为 `600` 的临时文件，确认成功后再替换 `uontabc-password`，然后 `rebuild`。
遵循第 8 节相同的“先生成成功，再替换”原则，不把明文密码放在命令行参数中。

建议备份：

- `/home` 中的重要文件、SSH 私钥与必要的应用状态。
- `/persist` 中的系统状态及密码文件，备份介质需有合适的访问控制或加密。
- 远端 Git 配置仓库，以及 Windows 数据 / BitLocker 恢复密钥。

当前没有启用 SSH 服务或持久化系统 SSH 主机密钥。以后若添加 SSH、agenix 或其他
依赖机器身份的服务，应同时设计其私钥的持久化与恢复，不能仅把路径写进 Nix 配置。

## 13. 故障定位与 Live 救援

### 13.1 先区分故障位置

| 现象 | 优先检查 | 不应该做什么 |
| --- | --- | --- |
| 固件直接进入 Windows | 固件启动顺序、NixOS 的 EFI 项 | 不删除 Windows 项，不重新分区 |
| GRUB 可见，最新 NixOS 启动失败 | GRUB 的 NixOS 历史代子菜单、启动日志 | 不认为回滚会恢复个人数据 |
| GRUB 没有 Windows 项 | ESP 挂载、`bootmgfw.efi`、os-prober 输出 | 不格式化 ESP、不强制挂载休眠 NTFS |
| initrd 停在根目录重置 | root PARTUUID、Btrfs 子卷、持久化密码文件 | 不删除 reset 脚本保护 |
| 普通用户不能登录 | 密码哈希、UID / 用户状态持久化 | 不只用 `passwd` 临时绕过 |
| 桌面黑屏但能进 TTY | greetd、Mango、NVIDIA 与实际 GPU 路由 | 不同时修改多项无关配置 |
| 安装下载 / 构建失败 | 网络、代理、时间、空间、具体构建错误 | 不重跑格式化 |
| I/O 错误、磁盘布局不符 | 立即停止写盘，检查硬件并保护数据 | 不运行盲目修复、重新建表或 `btrfs check --repair` |

桌面问题可尝试 `Ctrl+Alt+F2` 进入 TTY，登录后查看：

```sh
systemctl status greetd
journalctl -b -u greetd
journalctl --user -b
nvidia-smi
```

Windows 未被自动发现时，先使用固件 Windows Boot Manager 保持可启动，
在 Linux 中核对 `/efi` 和探测日志后再重新生成引导配置；不要手改生成的 `grub.cfg` 作为长期方案。

### 13.2 从 Live 环境取回配置

以 UEFI 模式启动安装 U 盘，联网，进入 root Bash，并恢复 Flake 实验特性设置。
如果配置副本丢失，可先 **只读挂载 Btrfs 顶层**，从保留的 home 取回：

```sh
ROOT_PART='/dev/disk/by-partuuid/实际-NIXOS_ROOT-PARTUUID'
install -d -m 0755 /run/carbon-recovery
mount -t btrfs -o ro,subvolid=5 "$ROOT_PART" /run/carbon-recovery
ls /run/carbon-recovery
install -d -m 0755 /root/nixos-config
cp -a /run/carbon-recovery/@home/uontabc/nixos-config/. /root/nixos-config/
umount /run/carbon-recovery
cd /root/nixos-config
```

若 `@home`、`@nix`、`@persist` 缺失或读取报错，停止；不要创建新文件系统覆盖原数据。
重新核对配置中的三个 PARTUUID，并确认 carbon 仍已启用、硬件文件齐全。

### 13.3 只挂载已有系统

先生成并检查 mount 脚本：

```sh
nix run .#disko -- --mode mount --flake .#carbon --root-mountpoint /mnt --dry-run
```

确认只挂载原有分区后：

```sh
nix run .#disko -- --mode mount --flake .#carbon --root-mountpoint /mnt
findmnt -R /mnt
test -f /mnt/efi/EFI/Microsoft/Boot/bootmgfw.efi
```

**注意这里是 `mount`，没有 `format`。**
若根子卷缺失或挂载失败，先检查根目录重置日志和现有子卷，不改用格式化命令。

### 13.4 修复密码或重新安装引导

- **缺少密码哈希：** 挂载成功后，按第 8.3 节在 `/mnt/persist/secrets` 补齐文件。
  若要更改已安装系统的登录密码，还需要重新应用用户配置；仅换哈希文件不等于立即更新账户。
- **继续中断的首次安装：** 核对第 8 节的绑定、machine-id 和密码，再重跑第 9 节
  `nixos-install`。不要重跑分区 / 格式化。
- **系统可用但 GRUB 丢失：** 完成 mount 后，可进入目标系统重新安装引导器：

```sh
nixos-enter --root /mnt -c \
  'nixos-rebuild boot --flake /home/uontabc/nixos-config#carbon --install-bootloader'
```

该命令会构建启动配置并重装引导器，不是只读检查；执行前再次确认 `/boot`、`/efi` 的来源。
若目标系统不完整或无法进入，回到 Live 的完整配置，按安装流程重新应用系统，保留原文件系统。

修复完再次执行第 10 节的检查与卸载，再重启。不要把“修复安装”理解为“清空后重装”。

## 14. 配置入口与参考资料

### 14.1 仓库内的事实来源

| 文件 | 负责内容 |
| --- | --- |
| [`hosts/default.nix`](../hosts/default.nix) | carbon 是否启用 |
| [`hosts/carbon/machine.nix`](../hosts/carbon/machine.nix) | 分区 PARTUUID、硬件导入、模板安装保护 |
| [`hosts/carbon/disko.nix`](../hosts/carbon/disko.nix) | 分区级文件系统、挂载和安全断言 |
| [`hosts/carbon/impermanence.nix`](../hosts/carbon/impermanence.nix) | 根目录重建、持久化白名单、密码文件 |
| [`modules/profiles/laptop.nix`](../modules/profiles/laptop.nix) | UEFI GRUB、Sleek light、Windows 探测和笔记本基础服务 |
| [`hosts/carbon/graphics.nix`](../hosts/carbon/graphics.nix) | NVIDIA 驱动与图形设置 |
| [`scripts/check-linux-partition.sh`](../scripts/check-linux-partition.sh) | 拒绝整盘、检查分区名称与 boot 类型 |
| [`scripts/reset-btrfs-root.sh`](../scripts/reset-btrfs-root.sh) | 启动时检查持久化状态并重建 `@root` |

本文与配置不一致时先排查差异，不靠删除保护检查继续。
外部文档可能随上游变化，实际依赖版本以本仓库 `flake.lock` 为准。

### 14.2 外部资料

- [NixOS 安装手册](https://nixos.org/manual/nixos/unstable/#sec-installation-manual)
- [Disko 命令行模式说明](https://github.com/nix-community/disko/blob/latest/docs/reference.md)
- [impermanence](https://github.com/nix-community/impermanence)
- [NixOS Wiki：Bootloader / GRUB](https://wiki.nixos.org/wiki/Bootloader#GRUB)
- [Sleek GRUB themes](https://github.com/sandesh236/sleek--themes)
