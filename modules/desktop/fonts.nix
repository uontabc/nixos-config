{
  flake.modules.nixos.fonts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
    in
    {
      fonts.packages = with pkgs; [
        nur.repos.shadowrz.hanekokoro-sans
        nur.repos.shadowrz.hanekokoro-mono
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
      ];
      fonts.fontconfig = {
        enable = true;
        # Steam and older Wine / Proton programs also use the 32-bit font cache.
        cache32Bit = true;
        defaultFonts = {
          monospace = [
            theme.fonts.mono
            theme.fonts.cjkMono
            theme.fonts.symbols
          ];
          sansSerif = [
            theme.fonts.sans
            theme.fonts.cjk
            theme.fonts.symbols
          ];
          serif = [
            "Noto Serif"
            "Noto Serif CJK SC"
          ];
          emoji = [ "Noto Color Emoji" ];
        };
        # Keep Latin families first even when matching fonts in CJK locales.
        localConf = ''
          <fontconfig>
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList
                (family: fonts: ''
                  <alias binding="strong">
                    <family>${family}</family>
                    <prefer>
                      ${lib.concatMapStringsSep "\n" (font: "<family>${font}</family>") fonts}
                    </prefer>
                  </alias>
                '')
                {
                  sans-serif = config.fonts.fontconfig.defaultFonts.sansSerif;
                  inherit (config.fonts.fontconfig.defaultFonts) monospace serif;
                }
            )}
          </fontconfig>
        '';
      };
    };
}
