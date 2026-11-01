# carbon · 双系统安装

[← 返回首页](../README.md)

适用于 Lenovo 83LT / Ryzen 9 8940HX / RTX 5060 Laptop，目标为同盘保留 Windows，
新增约 512 GiB 的 NixOS，使用 Btrfs + impermanence，不加密 Linux。

> **当前仍为待安装模板。** `carbon` 未在主机清单启用，Linux 分区 PARTUUID 留空，
> 真实引导、显卡、无线网络与挂起唤醒需现场验证。以下是操作指南，不代表已经执行。

## 1. Windows 准备

1. 将重要数据备份到外部存储；如启用 BitLocker / 设备加密，保存恢复密钥。
2. 在管理员 PowerShell 中检查加密状态；仅对已启用 BitLocker 的 C: 暂停保护。
3. 关闭休眠与快速启动，避免另一系统写入休眠中的 Windows 文件系统。

```powershell
manage-bde -status C:
# 仅在已启用 BitLocker 时执行，双系统验证后手动恢复
Suspend-BitLocker -MountPoint 'C:' -RebootCount 0
powercfg /hibernate off
```

在“磁盘管理”中压缩 C:，留下约 512 GiB **未分配空间**（524288 MiB）。
以实际可压缩量和 Windows 剩余空间需求为准，不删除 ESP、MSR 或恢复分区，不格式化为 NTFS。

从 [NixOS 官网](https://nixos.org/download/) 准备近期的 x86_64 安装 U 盘，
另存一份完整仓库，包含 `flake.lock` 和未提交的配置修改。
本配置不支持 Secure Boot；先处理 BitLocker，再关闭 Secure Boot，以 **UEFI 模式**启动安装介质。

## 2. 安装环境

以下直到重启前，均在安装介质的 root shell 中执行。每一步检查成功后再继续。

```sh
sudo -i
test -d /sys/firmware/efi && echo 'UEFI OK'
uname -m
export NIX_CONFIG='experimental-features = nix-command flakes'
```

必须看到 `UEFI OK` 和 `x86_64`。通过图形菜单联网，或在支持 NetworkManager 的介质中执行：

```sh
nmcli --ask device wifi connect '实际 Wi-Fi 名称'
timedatectl status
curl -I https://cache.nixos.org
```

不要使用 WSL 专用的 `127.0.0.1:7890`；原生安装环境需直接联网或使用实际可达的代理。
将完整仓库复制或解压到 `/root/nixos-config`，然后进入该目录：

```sh
cd /root/nixos-config
# 若复制的是不含 .git 的源码，先执行 git init
git add .
```

先确认其中没有密钥等私人文件再暂存。保留原 `flake.lock`，安装过程中不升级输入。
缺少工具时，可通过 `nix shell nixpkgs#git nixpkgs#util-linux -c bash` 进入临时环境。

## 3. 创建 Linux 分区

```sh
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,PARTTYPE,PARTUUID,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

按型号、容量和 Windows 分区识别内置磁盘，不依赖 `nvme0n1` 等编号。
仅在已腾出的空闲区域创建以下两个 Linux 分区：

| 分区 | 容量 | GPT 类型 / PARTLABEL | 挂载 |
| --- | --- | --- | --- |
| 原有 Windows ESP | 约 200 MiB，保持原状 | 不修改 | `/efi`，只挂载、不格式化 |
| 新 Linux 引导分区 | 1 GiB | XBOOTLDR / EA00，`NIXOS_BOOT` | FAT32 → `/boot` |
| 新 Linux 根分区 | 剩余空间，约 511 GiB | Linux filesystem / 8300，`NIXOS_ROOT` | Btrfs |

可使用 `cfdisk`，先替换为**已核对的整盘 by-id 路径**：

```sh
CARBON_DISK='/dev/disk/by-id/REPLACE_WITH_VERIFIED_INTERNAL_DISK'
test -b "$CARBON_DISK" && cfdisk "$CARBON_DISK"
```

- 仅在 **Free space** 中新建分区；Type 设置类型，Name 设置 GPT **PARTLABEL**，不是文件系统 LABEL。
- XBOOTLDR 类型 GUID：`bc13c2ff-59e6-4262-a352-b275fd6f7172`。
- 写入前确认 Windows、ESP、MSR、Recovery 分区的起止扇区与容量均未改变。
- 如果工具要求新建整张分区表，或看不到预期 GPT 布局，立即退出。

写入后执行 `udevadm settle`，再次查看 `lsblk`，记录 root、boot、ESP 三个 PARTUUID。
它们必须是**同一块磁盘上的三个不同分区**。模板中已有的 ESP PARTUUID 也必须现场复核。
此处不执行 `mkfs`，格式化交给后面的 Disko 步骤。

## 4. 填写配置并启用 carbon

在真实笔记本上生成硬件配置，不生成文件系统声明：

```sh
nixos-generate-config --no-filesystems --show-hardware-config \
  > hosts/carbon/hardware-configuration.nix
```

检查硬件模块和平台。不要复制 WSL 硬件配置；文件系统统一由 Disko 管理。
编辑 `hosts/carbon/machine.nix`，导入硬件文件并填写现场确认的分区路径：

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

这会移除 `machine.nix` 中人为设置的 `assertion = false` 安装保护；
**只移除这一处保护，不修改 Disko 与根目录重置的内置检查。**
`fleet.storage.laptop` 是角色选项名，无需改成 carbon。

在 `hosts/default.nix` 中取消整个 carbon 条目的注释，nano 仍保持注释：

```nix
carbon = {
  system = "x86_64-linux";
  modules = [ ./carbon ];
};
```

```sh
git add hosts/carbon hosts/default.nix
nix eval --raw .#nixosConfigurations.carbon.config.networking.hostName
nix eval --json .#nixosConfigurations.carbon.config.assertions \
  --apply 'xs: map (x: x.message) (builtins.filter (x: !x.assertion) xs)'
nix build --dry-run --no-link .#nixosConfigurations.carbon.config.system.build.toplevel
```

预期主机名为 `carbon`，失败断言为 `[]`。所有求值错误解决后再操作磁盘。
`--dry-run` 不代表构建成功。保留模板的 `system.stateVersion = "26.05"` 基线。

## 5. 格式化与挂载

> **以下实际执行命令会写入文件系统。** 仅用于首次安装时确认过的空 Linux 分区。
> `destroy = false` 不能保证任意操作都无数据损失；严禁对已有系统重复格式化。

先生成并查看脚本，确认只有新的 Linux 分区会被格式化，原 Windows ESP 仅挂载：

```sh
nix run .#disko -- --mode format,mount --flake .#carbon \
  --root-mountpoint /mnt --dry-run
```

用 `less` 查看输出的脚本路径，确认后再执行：

```sh
nix run .#disko -- --mode format,mount --flake .#carbon --root-mountpoint /mnt
findmnt -R /mnt
df -h /mnt/efi /mnt/boot
test -f /mnt/efi/EFI/Microsoft/Boot/bootmgfw.efi
```

**不要改用 `destroy,format,mount` 或 `disko` 模式，也不要套用 nano 的整盘模板。**

| 挂载点 | 来源 |
| --- | --- |
| `/mnt` | NIXOS_ROOT 的 `@root` |
| `/mnt/home` | `@home` |
| `/mnt/nix` | `@nix` |
| `/mnt/persist` | `@persist` |
| `/mnt/boot` | 新 NIXOS_BOOT / XBOOTLDR |
| `/mnt/efi` | 原有 Windows ESP |

挂载关系或 Windows 引导文件检查不符时，先停止并排查。

## 6. 准备持久化状态与密码

每次启动只重建 `@root`；整个 `/home`、`/nix`、`/persist` 保留。
系统状态白名单位于 `hosts/carbon/impermanence.nix`，包括用户 ID、hjem、网络、蓝牙、Docker 和日志。
未持久化的根目录文件重启后会消失，仓库必须放在持久化 home 中。

安装前绑定用户 ID 与 hjem 状态目录，并准备 machine-id：

```sh
for state in var/lib/nixos var/lib/hjem; do
  install -d -m 0755 "/mnt/persist/$state" "/mnt/$state"
  mount --bind "/mnt/persist/$state" "/mnt/$state"
done
install -d -m 0755 /mnt/persist/etc /mnt/etc
if ! test -s /mnt/persist/etc/machine-id; then
  systemd-id128 new > /mnt/persist/etc/machine-id
fi
chmod 0444 /mnt/persist/etc/machine-id
install -m 0444 /mnt/persist/etc/machine-id /mnt/etc/machine-id
```

交互生成 `uontabc` 的密码哈希：

```sh
install -d -m 0700 /mnt/persist/secrets
nix shell --inputs-from . nixpkgs#mkpasswd -c mkpasswd -m yescrypt \
  > /mnt/persist/secrets/uontabc-password
chmod 0600 /mnt/persist/secrets/uontabc-password
test -s /mnt/persist/secrets/uontabc-password
```

密码哈希不进入 Git 或 Nix 文件。`users.mutableUsers = false`，以后改密码也应更新
`/persist/secrets/uontabc-password` 并 rebuild，不能只使用 `passwd`。
根目录重置服务会检查持久化子卷和密码文件，缺失时在删除 root 前停止。

## 7. 安装并重启

```sh
install -d -m 0755 /mnt/home/uontabc/nixos-config
cp -a /root/nixos-config/. /mnt/home/uontabc/nixos-config/
nixos-install --root /mnt --flake /root/nixos-config#carbon \
  --no-root-password --no-channel-copy
chown -R 1000:100 /mnt/home/uontabc
```

安装读取 live 环境中 root 所有的仓库，目标 home 保存相同副本，随后交还 UID 1000 的用户。
登录使用已准备的普通用户密码，不设置临时 root 密码。

若构建或网络失败，修复后可重跑 **nixos-install**，不要重跑分区或格式化。
修改配置后也要同步目标 home 中的副本。

安装成功后检查：

```sh
test -s /mnt/persist/secrets/uontabc-password
test -f /mnt/home/uontabc/nixos-config/flake.nix
test -f /mnt/efi/EFI/Microsoft/Boot/bootmgfw.efi
ls -l /mnt/efi/EFI/systemd /mnt/boot/loader/entries
findmnt -R /mnt
```

确认检查通过后卸载，卸载成功才重启：

```sh
sync
cd /
umount -R /mnt
reboot
```

取出 U 盘；固件若仍默认进入 Windows，从启动菜单选择 Linux Boot Manager，
不要删除 Windows 启动项。systemd-boot 使用共享 ESP 中的引导程序和 XBOOTLDR 中的 Linux 启动项。

## 8. 首次启动验证

在 greetd 使用 `uontabc` 和已设置的密码登录 Mango，会话内执行：

```sh
hostname
findmnt -t btrfs,vfat
systemctl --failed
sudo journalctl -b | rg reset-btrfs-root
nvidia-smi
lspci -nnk | rg -A3 'VGA|3D|Display'
systemctl is-active docker
pi mcp list
cd ~/nixos-config
nh os build --hostname carbon
```

验证持久化时，可以创建测试文件后重启：

```sh
printf 'home persists\n' > ~/impermanence-home-test
printf 'root resets\n' | sudo tee /root/impermanence-root-test >/dev/null
sudo reboot
```

home 文件应保留，root 文件应消失；确认后删除 home 测试文件。
另行检查 Wi-Fi、声音、蓝牙、亮度、触摸板、锁屏与挂起唤醒。

- NVIDIA 使用原生 open 驱动，未启用 PRIME；如需混合显卡，按实测 PCI ID 配置。
- 未配置休眠交换分区，挂起唤醒不等于休眠到磁盘可用。
- 两个系统保持本地时间 RTC 约定，不要再叠加冲突的时钟调整。
- 进入 Windows 验证引导和数据；如暂停过 BitLocker，验证后以管理员身份执行
  `Resume-BitLocker -MountPoint 'C:'`。

将实际硬件文件、PARTUUID 和启用后的清单同步回主仓库，**不要同步密码或私钥**。
以后更新使用 `cd ~/nixos-config && rebuild`，不再运行格式化命令。

## 故障处理

| 问题 | 处理 |
| --- | --- |
| 新系统代无法启动 | 在 systemd-boot 选择前一代；不会回滚 home 或关闭根目录重建 |
| 缺少持久化密码 | 用 U 盘挂载 Btrfs 顶层，补齐 `@persist/secrets/uontabc-password` 的哈希，不重新格式化 |
| 修复引导或重新安装 | 从 `@home/uontabc/nixos-config` 取回配置，确认分区后仅用 Disko `--mode mount` |
| 桌面黑屏 | `Ctrl+Alt+F2` 进入 TTY，检查 greetd、Mango 与显卡日志 |
| 需要先回 Windows | 从固件启动菜单选择 Windows Boot Manager，不修改分区表 |

## 参考

[NixOS 安装手册](https://nixos.org/manual/nixos/unstable/#sec-installation-manual) ·
[Disko 模式](https://github.com/nix-community/disko/blob/latest/docs/reference.md) ·
[impermanence](https://github.com/nix-community/impermanence) ·
[systemd-boot](https://www.freedesktop.org/software/systemd/man/latest/systemd-boot.html)
