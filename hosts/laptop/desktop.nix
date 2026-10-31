{
  config,
  inputs,
  identity,
  lib,
  pkgs,
  ...
}:
let
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
    exec ${lib.getExe config.programs.mango.package}
  '';
  startup = pkgs.writeShellScript "mango-startup" ''
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE PATH
    ${lib.getExe noctalia} --daemon
    exec ${pkgs.swayidle}/bin/swayidle -w \
      before-sleep '${lib.getExe noctalia} msg session lock'
  '';
in
{
  imports = [ inputs.mango.nixosModules.mango ];
  programs.mango.enable = true;

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
          font_family = "JetBrainsMono Nerd Font";
          lang = "en";
          polkit_agent = true;
        };
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
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
      };
      "foot/foot.ini".text = ''
        [main]
        font=JetBrainsMono Nerd Font:size=11
        pad=12x12
        [colors]
        alpha=0.96
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
    foot
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
