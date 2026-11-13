{ ... }:
{
  flake.modules.nixos.management =
    {
      lib,
      pkgs,
      configRoot,
      hostKey,
      ...
    }:
    let
      nhWithAutoUpdate = pkgs.writeShellApplication {
        name = "nh";
        text = ''
          # nh normally reuses flake.lock. Update before switching, unless the
          # caller explicitly requests a pinned, offline or selective rebuild.
          if [[ "''${1-}" == os && "''${2-}" == switch ]]; then
            auto_update=true
            for arg in "''${@:3}"; do
              case "$arg" in
                --) break ;;
                -u|--update|-U|--update-input|--update-input=*|-U?*|\
                --no-update-lock-file|--no-write-lock-file|--recreate-lock-file|\
                --offline|--no-net|-n|--dry|-h|--help|\
                -f|--file|--file=*|-f?*|--expr|--expr=*)
                  auto_update=false
                  break
                  ;;
              esac
            done
            if "$auto_update"; then
              shift 2
              exec ${lib.getExe pkgs.nh} os switch --update "$@"
            fi
          fi
          exec ${lib.getExe pkgs.nh} "$@"
        '';
      };
    in
    {
      programs.nh = {
        enable = true;
        flake = configRoot;
        # Preserve upstream completions and man pages without rebuilding nh.
        package = pkgs.symlinkJoin {
          name = "nh-auto-update-${pkgs.nh.version}";
          paths = [ pkgs.nh ];
          postBuild = ''
            ln -sfn ${lib.getExe nhWithAutoUpdate} "$out/bin/nh"
          '';
          meta = pkgs.nh.meta;
        };
      };
      environment.systemPackages = [ pkgs.git ];
      environment.shellAliases.rebuild = "${lib.getExe pkgs.nixos-rebuild} switch --sudo --flake ${lib.escapeShellArg "${configRoot}#${hostKey}"}";
    };
}
