{ pkgs }:
pkgs.mkShell {
  name = "cpp-project";
  packages = with pkgs; [
    cmake
    ninja
    gnumake
    pkg-config
    ccache
    gdb
    clang-tools
  ];
  CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
}
