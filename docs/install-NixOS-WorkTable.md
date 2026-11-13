# NixOS-WorkTable 本机重装

> **会清空整块 1 TB NVMe，包括 Windows 和当前 NixOS。**
> 先将个人数据备份到其他磁盘或远端，并把本次 ZFS 配置提交、推送到仓库。

## 1. 启动安装环境

使用近期、支持 ZFS 的 NixOS 安装 U 盘，**UEFI 启动，关闭 Secure Boot**，连接网络。
以下命令在安装环境执行，不要在当前系统里运行分区命令。

```sh
sudo -i
export NIX_CONFIG='experimental-features = nix-command flakes
extra-substituters = https://cache.lantian.pub/lantian
extra-trusted-public-keys = lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ='
nix shell nixpkgs#git nixpkgs#mkpasswd -c bash

modprobe zfs
test -d /sys/firmware/efi
git clone https://github.com/uontabc/nixos-config /tmp/nixos-config
cd /tmp/nixos-config
```

任何命令失败，先解决再继续。`modprobe zfs` 失败时换用支持 ZFS 的安装镜像。

## 2. 核对磁盘并分区

```sh
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS
readlink -f /dev/disk/by-id/nvme-eui.5cdfb804b1a00b01
```

确认这是要清空的 UMIS NVMe；不一致就先修改 `modules/hosts/NixOS-WorkTable/machine.nix` 的 `disk`。
**下面这条命令开始清盘，只执行一次：**

```sh
nix run .#disko -- --mode destroy,format,mount --flake .#NixOS-WorkTable
```

自动挂载到 `/mnt`：1 GiB EFI、2 GiB ext4 `/boot`，其余为 ZFS。

## 3. 导入本机硬件配置

```sh
nixos-generate-config --root /mnt --no-filesystems --show-hardware-config \
  > modules/hosts/NixOS-WorkTable/_hardware-configuration.nix
nano modules/hosts/NixOS-WorkTable/machine.nix
```

取消这一行的注释：

```nix
imports = [ ./_hardware-configuration.nix ];
```

将硬件配置加入 Git，避免 flake 忽略新文件：

```sh
git add modules/hosts/NixOS-WorkTable/_hardware-configuration.nix modules/hosts/NixOS-WorkTable/machine.nix
```

## 4. 设置登录密码

```sh
install -d -m 0700 /mnt/persist/secrets
(umask 077; mkpasswd -m yescrypt > /mnt/persist/secrets/uontabc-password)
```

按提示输入 **uontabc 的登录密码**。密码哈希只保存在 `/persist`，不要提交到 Git。

## 5. 安装并重启

```sh
install -d /mnt/home/uontabc
cp -a /tmp/nixos-config /mnt/home/uontabc/nixos-config
nixos-install --flake /mnt/home/uontabc/nixos-config#NixOS-WorkTable --no-root-passwd
chown -R 1000:100 /mnt/home/uontabc
```

**安装成功后**卸载、导出 ZFS 池，再重启；导出失败时不要强制操作，先检查占用：

```sh
umount -R /mnt
zpool export ontario
reboot
```

拔掉安装 U 盘，以 `uontabc` 登录。

根目录每次开机回滚；`/home`、`/nix`、`/persist` 保留。安装时已自动创建空白快照，
不需要手动创建，也不要删除 `ontario/root@blank`。

以后更新配置：

```sh
cd ~/nixos-config
rebuild
```
