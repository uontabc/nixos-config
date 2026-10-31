# VPS

代理节点模板：sing-box / VLESS / REALITY / `xtls-rprx-vision`，默认 TCP 443。

- `default.nix`：组合本机配置、代理参数与代理节点角色。
- `machine.nix`：替换为本机原有 NixOS 配置，保留硬件、引导、网络、SSH 和 stateVersion。
- `proxy.nix`：监听端口、握手域名、秘密文件目录。

此主机尚未注册；完成 machine.nix 后，再取消 `hosts/default.nix` 中 VPS 项的注释，
选择实际的 `x86_64-linux` 或 `aarch64-linux`。模板中的断言会阻止未配置硬件的部署。

## 首次准备凭据

先把仓库复制到 VPS。假设仓库位于 `/etc/nixos`，在 VPS 上运行：

```sh
sudo nix --extra-experimental-features 'nix-command flakes' shell \
  --inputs-from path:/etc/nixos nixpkgs#sing-box nixpkgs#python312 \
  -c python3.12 /etc/nixos/scripts/init-reality.py
```

脚本在 `/var/lib/sing-box-secrets` 生成 `uuid`、`private-key`、`public-key` 和 `short-id`。
目录权限 0700，文件权限 0600；发现已有凭据会拒绝覆盖。
NixOS 使用 `_secret` 在服务启动时读取这些值，私钥不写入 Nix store 或 Git。
模板的 `www.microsoft.com` 是示例握手域名，请按 VPS 的实际连通情况修改。

配置生效后可用 `sudo systemctl status sing-box` 检查服务，
`sudo journalctl -u sing-box -e` 查看日志。云服务商的入站规则需允许你选择的 TCP 端口。

客户端使用 VPS 地址、端口、UUID、相同的 SNI、REALITY 公钥、short ID，以及
`xtls-rprx-vision`。只向客户端提供公钥，私钥保留在 VPS。

参考：[VLESS](https://sing-box.sagernet.org/configuration/inbound/vless/)、
[REALITY](https://sing-box.sagernet.org/configuration/shared/tls/#reality-fields)。
