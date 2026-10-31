# Local server

本地开发服务器模板，复用 Python、Rust、C++、Zsh、LazyVim 和 hjem。

`machine.nix` 需要替换为这台服务器现有的 NixOS 配置，保留磁盘、引导、网络、SSH
访问和 `system.stateVersion`。完成后取消 `hosts/default.nix` 中 `server` 项的注释，
填入实际架构。模板断言会阻止尚未完成本机配置的部署。

默认开发用户是 `uontabc`，使用 Zsh 并加入 wheel。原配置中的其他账户继续保留；
本模板不设置账户密码、SSH 密钥或免密码 sudo，请沿用现有的管理方式。

本机显卡驱动、项目服务、Docker 或数据库可分别加入 `default.nix` 的模块列表。
Windows localhost 代理与 WSL CUDA 驱动桥接仅存在于 WSL 主机。
