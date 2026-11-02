{
  config,
  inputs,
  identity,
  lib,
  pkgs,
  ...
}:
let
  theme = import ../../lib/theme.nix;
  noctaliaUpstream = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # GUI dependencies must not inherit a project's older C++ runtime via LD_LIBRARY_PATH.
  noctalia = pkgs.symlinkJoin {
    name = "noctalia-${noctaliaUpstream.version}";
    version = noctaliaUpstream.version;
    paths = [ noctaliaUpstream ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/noctalia" --unset LD_LIBRARY_PATH
    '';
    meta = noctaliaUpstream.meta;
  };
  session = pkgs.writeShellScript "mango-session" ''
    . /etc/profile
    export XDG_CURRENT_DESKTOP=mango
    export XDG_SESSION_DESKTOP=mango
    export XDG_SESSION_TYPE=wayland
    trap '${pkgs.systemd}/bin/systemctl --user stop mango-session.target' EXIT
    ${lib.getExe config.programs.mango.package}
  '';
  startup = pkgs.writeShellScript "mango-startup" ''
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE PATH
    export GSETTINGS_SCHEMA_DIR=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme ${lib.escapeShellArg theme.gtkName}
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme ${lib.escapeShellArg theme.icons}
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme ${lib.escapeShellArg theme.cursorName}
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-size 24
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface font-name ${lib.escapeShellArg "${theme.fonts.sans} ${toString theme.fonts.size}"}
    ${pkgs.systemd}/bin/systemctl --user start mango-session.target
    ${lib.getExe noctalia} --daemon
    exec ${pkgs.swayidle}/bin/swayidle -w \
      before-sleep '${lib.getExe noctalia} msg session lock'
  '';
in
{
  imports = [
    inputs.mango.nixosModules.mango
    ./appearance.nix
    ./vicinae.nix
  ];
  programs.mango.enable = true;
  # Includes the Steam runtime, controller rules and 32-bit audio support.
  # Remote Play / LAN transfer firewall ports remain closed by default.
  programs.steam.enable = true;
  # PCManFM uses GVfs / UDisks for trash, remote locations and removable media.
  # Run only as a file manager, without PCManFM's desktop management.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  xdg.mime.defaultApplications."inode/directory" = "pcmanfm.desktop";

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd ${session}";
      user = "greeter";
    };
  };
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.noctalia = { };

  hjem.extraModules = [ inputs.noctalia.hjemModules.default ];
  hjem.users.${identity.username} = {
    programs.noctalia = {
      enable = true;
      package = noctalia;
      systemd.enable = false;
      settings = {
        shell = {
          font_family = theme.fonts.sans;
          lang = "en";
          polkit_agent = true;
        };
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
          templates = {
            enable_builtin_templates = false;
            enable_community_templates = false;
          };
        };
        wallpaper.enabled = false;
        idle.behavior = {
          lock = {
            enabled = true;
            timeout = 600;
            action = "lock";
          };
          screen-off = {
            enabled = true;
            timeout = 660;
            action = "screen_off";
          };
        };
      };
    };
    xdg.config.files = {
      "mango/config.conf".source = pkgs.replaceVars ../../home/mango/config.conf {
        inherit startup;
        ghostty = lib.getExe pkgs.ghostty;
        file_manager = lib.getExe pkgs.pcmanfm;
        base = lib.removePrefix "#" theme.colors.base;
        border = lib.removePrefix "#" theme.colors.surface1;
        accent = lib.removePrefix "#" theme.colors.mauve;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
    ghostty
    pcmanfm
    wl-clipboard
    xdg-utils
  ];
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
