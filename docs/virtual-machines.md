# Obsidian 虚拟机

使用 **virt-manager → libvirt → QEMU/KVM**，连接地址为 `qemu:///system`。

## 应用配置

```sh
sudo nixos-rebuild switch --flake /home/uontabc/nixos-config#obsidian --no-write-lock-file
```

第一次安装后注销并重新登录，让 `libvirtd`、`kvm` 组权限和会话环境生效。
如需让本次新增的 VFIO/IOMMU 启动设置生效，请重启。

配置包含：

- virt-manager、virt-viewer、virsh 和 PCI 设备检查工具。
- 以非 root 身份运行 QEMU；提供 UEFI 固件、软件 TPM 和 virtiofsd。
- `default` NAT 网络和 `/var/lib/libvirt/images` 默认存储池，均自动启动。
- 持久化整个 `/var/lib/libvirt`，包括磁盘、虚拟机定义、UEFI NVRAM 和 TPM 状态。
- 宿主关机时请求客机关机；不会在开机时自动恢复上次运行的客机。

## 创建虚拟机

1. 打开“虚拟系统管理器”，使用 **QEMU/KVM 系统连接**，不要改成用户会话连接。
2. 安装 ISO 放在 `/var/lib/libvirt/images`，不要依赖 QEMU 无法遍历的私有主目录。
   例如：

   ```sh
   sudo install -o qemu-libvirtd -g libvirtd -m 0640 /path/to/windows.iso /var/lib/libvirt/images/windows.iso
   ```

3. 创建虚拟机，选择 ISO，将 qcow2 磁盘保存在默认存储池。
4. 主机只有 16 GiB 内存，建议先给客机 4 个 vCPU、4–6 GiB 内存。
5. Windows 11 选择 Q35、UEFI 和 TPM 2.0；使用 VirtIO 磁盘/网卡时，另准备 virtio-win 驱动 ISO。

检查服务和默认资源：

```sh
virsh --connect qemu:///system list --all
virsh --connect qemu:///system net-list --all
virsh --connect qemu:///system pool-list --all
systemctl status libvirt-defaults.service
```

libvirtd 使用套接字激活，空闲时主进程退出不代表服务故障。

## 显卡直通边界

安装时系统只检测到一张正在被宿主使用的 NVIDIA 显卡：

- `0000:01:00.0`：显卡。
- `0000:01:00.1`：同一 IOMMU 组内的音频功能。

本配置仅启用 IOMMU 和加载 VFIO 模块。**没有绑定显卡到 vfio-pci、屏蔽 NVIDIA 驱动，
也没有安装会停止桌面的 libvirt hooks。单显卡自动交接尚未配置，不能把这一步当作
显卡直通已经可用。**

后续应先判断固件能否启用核显并由核显承载 Linux 桌面，再把独显专供客机。
若必须使用单显卡，需要在有 SSH/TTY 恢复手段的情况下，另行设计、测试停止图形会话、
解绑显卡、启动客机和恢复宿主的 hooks。不要直接在当前桌面里启动占用该显卡的客机，
也不要给这类客机开启自动启动。

参考：[NixOS PCI passthrough](https://wiki.nixos.org/wiki/PCI_passthrough)。
