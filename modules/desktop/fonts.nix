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
        recursive
        nerd-fonts.symbols-only
        lxgw-wenkai
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
            "Noto Sans CJK SC"
            theme.fonts.symbols
          ];
          sansSerif = [
            theme.fonts.sans
            theme.fonts.cjk
            "Noto Sans CJK SC"
            theme.fonts.symbols
          ];
          serif = [
            "Noto Serif"
            theme.fonts.cjk
            "Noto Serif CJK SC"
          ];
          emoji = [ "Noto Color Emoji" ];
        };
        # Strong ordering prevents zh-cn coverage scoring from promoting Noto CJK
        # above WenKai, while preserving the Latin and monospace families first.
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
