{
  flake.modules.nixos.niri =
    {
      config,
      inputs,
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../../lib/theme.nix;
      xwaylandSatellite = inputs.xwayland-satellite.packages.${pkgs.stdenv.hostPlatform.system}.default;
      noctalia = config.users.users.${identity.username}.maid.programs.noctalia.package;
      toggleKeyDisplay = pkgs.writeShellApplication {
        name = "toggle-key-display";
        runtimeInputs = [
          pkgs.systemd
          pkgs.libnotify
        ];
        text = ''
          notify() {
            notify-send --app-name="按键可视化" --expire-time=3000 "$@" || true
          }
          if systemctl --user is-active --quiet key-display.service; then
            systemctl --user stop key-display.service
            notify "按键显示已关闭"
          elif systemctl --user start key-display.service &&
               systemctl --user is-active --quiet key-display.service; then
            notify "按键显示已开启" "Super+Alt+K 关闭；输入密码前请关闭。"
          else
            notify --urgency=critical "按键显示启动失败" "请检查 journalctl --user -u key-display.service -b"
            exit 1
          fi
        '';
      };
      # Niri has no native minimize state. Stash windows on a temporary named
      # workspace and keep a session-local LIFO stack, without a background daemon.
      windowVisibility = pkgs.writeScriptBin "niri-window-visibility" ''
        #!${lib.getExe pkgs.python3}
        import fcntl
        import hashlib
        import json
        import os
        from pathlib import Path
        import socket
        import sys
        import time

        STASH = "__hidden"

        def request(message):
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
                connection.settimeout(3)
                connection.connect(os.environ["NIRI_SOCKET"])
                connection.sendall((json.dumps(message) + "\n").encode())
                with connection.makefile("r") as response:
                    reply = json.loads(response.readline())
            if "Err" in reply:
                raise RuntimeError(reply["Err"])
            return reply["Ok"]

        def action(kind, **arguments):
            return request({"Action": {kind: arguments}})

        def clear_empty_stash(stash):
            windows = request("Windows")["Windows"]
            if not any(w["workspace_id"] == stash["id"] for w in windows):
                action("UnsetWorkspaceName", reference={"Id": stash["id"]})

        def compact(window):
            window_id = window["id"]
            before = window["layout"]["window_size"]
            action("MoveWindowToFloating", id=window_id)
            action("SetWindowWidth", id=window_id, change={"SetProportion": 55.0})
            action("SetWindowHeight", id=window_id, change={"SetProportion": 65.0})
            # CenterWindow uses the committed size, not the requested size.
            # Wait briefly for the client to acknowledge its configure; otherwise
            # a formerly maximized window can end up centered using its old size.
            started = time.monotonic()
            previous = None
            stable = 0
            while time.monotonic() - started < 0.8:
                current = next((w for w in request("Windows")["Windows"] if w["id"] == window_id), None)
                if current is None:
                    return
                size = current["layout"]["window_size"]
                stable = stable + 1 if size == previous else 0
                if stable >= 3 and (size != before or time.monotonic() - started > 0.15):
                    break
                previous = size
                time.sleep(0.02)
            action("CenterWindow", id=window_id)

        def main():
            if len(sys.argv) != 2 or sys.argv[1] not in ("hide", "restore", "compact"):
                raise RuntimeError("usage: niri-window-visibility hide|restore|compact")
            os.umask(0o077)
            session = hashlib.sha256(os.environ["NIRI_SOCKET"].encode()).hexdigest()[:16]
            state = Path(os.environ["XDG_RUNTIME_DIR"]) / f"niri-hidden-{session}.json"
            with state.with_suffix(".lock").open("a") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                workspaces = request("Workspaces")["Workspaces"]
                windows = request("Windows")["Windows"]
                current = next((w for w in workspaces if w["is_focused"]), None)
                focused = next((w for w in windows if w["is_focused"]), None)
                if sys.argv[1] == "compact":
                    if focused is not None:
                        compact(focused)
                    return
                if current is None or current["name"] == STASH:
                    return
                stash = next((w for w in workspaces if w["name"] == STASH), None)
                try:
                    stored = json.loads(state.read_text())
                except (FileNotFoundError, json.JSONDecodeError):
                    stored = []
                if not isinstance(stored, list):
                    stored = []
                hidden = {w["id"]: w for w in windows if stash and w["workspace_id"] == stash["id"]}
                stack = list(dict.fromkeys(i for i in stored if isinstance(i, int) and i in hidden))
                # Recover manually stashed windows or a lost/corrupt state file.
                untracked = sorted(
                    (w for i, w in hidden.items() if i not in stack),
                    key=lambda w: (
                        (w.get("focus_timestamp") or {}).get("secs", 0),
                        (w.get("focus_timestamp") or {}).get("nanos", 0),
                        w["id"],
                    ),
                )
                stack = [w["id"] for w in untracked] + stack

                if sys.argv[1] == "hide":
                    if focused is None or focused["workspace_id"] != current["id"]:
                        return
                    created = stash is None
                    if created:
                        # Reuse the trailing empty workspace; do not permanently
                        # insert a named workspace at index 1 on every login.
                        empty = [
                            w for w in workspaces
                            if w["output"] == current["output"] and w["name"] is None
                            and w["id"] != current["id"] and w["active_window_id"] is None
                            and not any(window["workspace_id"] == w["id"] for window in windows)
                        ]
                        if not empty:
                            raise RuntimeError("no empty workspace available for hiding")
                        stash = max(empty, key=lambda w: w["idx"])
                        action("SetWorkspaceName", name=STASH, workspace={"Id": stash["id"]})
                    try:
                        action("DoScreenTransition", delay_ms=0)
                        action("MoveWindowToWorkspace", window_id=focused["id"],
                               reference={"Id": stash["id"]}, focus=False)
                    except Exception:
                        if created:
                            clear_empty_stash(stash)
                        raise
                    stack = [i for i in stack if i != focused["id"]] + [focused["id"]]
                else:
                    if not stack:
                        if stash:
                            clear_empty_stash(stash)
                        state.unlink(missing_ok=True)
                        return
                    window_id = stack[-1]
                    # Stable workspace IDs avoid index ambiguity across monitors.
                    action("DoScreenTransition", delay_ms=0)
                    action("MoveWindowToWorkspace", window_id=window_id,
                           reference={"Id": current["id"]}, focus=False)
                    stack.pop()
                    action("FocusWindow", id=window_id)
                    clear_empty_stash(stash)

                temporary = state.with_suffix(".tmp")
                temporary.write_text(json.dumps(stack))
                temporary.replace(state)

        if __name__ == "__main__":
            try:
                main()
            except (OSError, ValueError, KeyError, RuntimeError) as error:
                print(f"niri-window-visibility: {error}", file=sys.stderr)
                sys.exit(1)
      '';
      renderedConfig = pkgs.replaceVars ./config.kdl {
        terminal = lib.getExe pkgs.kitty;
        file_manager = lib.getExe pkgs.pcmanfm;
        noctalia = lib.getExe noctalia;
        xwayland_satellite = lib.getExe xwaylandSatellite;
        recorder = lib.getExe config.programs.obs-studio.finalPackage;
        window_visibility = lib.getExe windowVisibility;
        key_display = lib.getExe toggleKeyDisplay;
        cursor_theme = theme.cursorName;
        cursor_size = toString theme.cursorSize;
        base = theme.colors.base;
        accent = theme.colors.${theme.accent};
        inactive = theme.colors.surface1;
        urgent = theme.colors.red;
      };
    in
    {
      programs.niri = {
        enable = true;
        # Reuse the official binary cache rather than building upstream Git.
        package = pkgs.niri;
        # GTK handles file selection; the GNOME portal handles screen sharing.
        useNautilus = false;
      };

      # Use NixOS's privileged launcher rather than granting the user input-group access.
      programs.wshowkeys = {
        enable = true;
        # Upstream -t 0 clears immediately; explicitly add bounded persistent mode.
        package = pkgs.wshowkeys.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./wshowkeys-persistent.patch ];
        });
      };

      services.greetd = {
        enable = true;
        settings.default_session = {
          # Fall back to the configured user when the cache is empty after a boot.
          command = "${lib.getExe pkgs.tuigreet} --time --user ${lib.escapeShellArg identity.username} --remember --cmd ${config.programs.niri.package}/bin/niri-session";
          user = "greeter";
        };
      };
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;

      systemd.tmpfiles.settings."desktop-directories" = {
        "${config.users.users.${identity.username}.home}/Pictures/Screenshots".d = {
          mode = "0755";
          user = identity.username;
          group = config.users.users.${identity.username}.group;
        };
      };

      users.users.${identity.username}.maid = {
        packages = [
          windowVisibility
          toggleKeyDisplay
        ];
        file.xdg_data."applications/key-display.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Key Display
          Name[zh_CN]=按键可视化
          Comment=Toggle the keypress overlay (Super+Alt+K); disable before entering secrets
          Comment[zh_CN]=切换按键浮层（Super+Alt+K）；输入密码前关闭
          Exec=${lib.getExe toggleKeyDisplay}
          Icon=input-keyboard
          Terminal=false
          Categories=Utility;Accessibility;
          Keywords=keyboard;keys;按键;键盘;
          StartupNotify=false
        '';
        # Requested persistent display: start with Niri; retain the manual toggle.
        systemd.services.key-display = {
          description = "Persistent keypress overlay (Super+Alt+K to toggle)";
          wantedBy = [ "niri.service" ];
          requisite = [ "niri.service" ];
          partOf = [ "niri.service" ];
          after = [ "niri.service" ];
          enableDefaultPath = false;
          serviceConfig = {
            Type = "exec";
            ExecStart =
              "/run/wrappers/bin/wshowkeys "
              + lib.escapeShellArgs [
                "-a"
                "bottom"
                "-a"
                "right"
                "-m"
                "24"
                "-t"
                "0"
                "-F"
                "${theme.fonts.mono} 22"
                "-b"
                "${theme.colors.base}e6"
                "-f"
                theme.colors.text
                "-s"
                theme.colors.${theme.accent}
              ];
            # Never persist displayed keystrokes in the journal.
            StandardOutput = "null";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
        systemd.services.kanshi = {
          description = "Switch between external-only and laptop displays";
          wantedBy = [ "niri.service" ];
          partOf = [ "niri.service" ];
          after = [ "niri.service" ];
          enableDefaultPath = false;
          restartTriggers = [ ./kanshi.conf ];
          serviceConfig = {
            # Read $XDG_CONFIG_HOME/kanshi/config, deployed by nix-maid below.
            ExecStart = lib.getExe pkgs.kanshi;
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
        file.xdg_config."kanshi/config".source = ./kanshi.conf;
        # Reject invalid rules/keybindings at build time, before touching the session.
        file.xdg_config."niri/config.kdl".source = pkgs.runCommand "niri-config.kdl" { } ''
          ${lib.getExe config.programs.niri.package} validate -c ${renderedConfig}
          cp ${renderedConfig} $out
        '';
      };

      environment.systemPackages = [
        pkgs.wl-clipboard
        xwaylandSatellite
        pkgs.xdg-utils
      ];
    };
}
