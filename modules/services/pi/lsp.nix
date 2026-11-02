{ ... }:
{
  flake.modules.nixos.pi-lsp =
    { pkgs, ... }:
    let
      lsp = pkgs.callPackage ../../../packages/pi-lsp { };
      server = command: args: languageId: extensions: rootMarkers: {
        inherit command args rootMarkers;
        requireRootMarker = true;
        languages = [ { inherit languageId extensions; } ];
      };
    in
    {
      programs.pi.coding-agent.extensions = [ "${lsp}/node_modules/@ian-pascoe/pi-lsp/src/index.ts" ];
      programs.pi.coding-agent.settings.lsp = {
        timeouts = {
          initializeMs = 60000;
          requestMs = 5000;
          workspaceRequestMs = 20000;
          diagnosticsMs = 5000;
          shutdownMs = 5000;
        };
        # These are resolved from the launching project's PATH, never installed here.
        servers = {
          nix = server "nil" [ ] "nix" [ ".nix" ] [ "flake.nix" "shell.nix" ".git" ];
          python = server "pyright-langserver" [
            "--stdio"
          ] "python" [ ".py" ".pyi" ] [ "pyproject.toml" "requirements.txt" ".git" ];
          rust = server "rust-analyzer" [ ] "rust" [ ".rs" ] [ "Cargo.toml" ".git" ];
          clangd = {
            command = "clangd";
            args = [
              "--background-index"
              "--clang-tidy"
              "--query-driver=/nix/store/*-gcc-wrapper-*/bin/*,/nix/store/*-clang-wrapper-*/bin/*,/run/current-system/sw/bin/*"
            ];
            requireRootMarker = true;
            rootMarkers = [
              "compile_commands.json"
              "CMakeLists.txt"
              ".clangd"
              ".git"
            ];
            languages = [
              {
                languageId = "c";
                extensions = [
                  ".c"
                  ".h"
                ];
              }
              {
                languageId = "cpp";
                extensions = [
                  ".cc"
                  ".cpp"
                  ".cxx"
                  ".hh"
                  ".hpp"
                  ".hxx"
                ];
              }
            ];
          };
        };
      };
    };
}
