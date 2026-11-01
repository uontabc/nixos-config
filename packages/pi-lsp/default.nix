{
  buildNpmPackage,
  importNpmLock,
  lib,
}:
buildNpmPackage {
  pname = "fleet-pi-lsp";
  version = "0.15.2";
  src = ./.;
  npmDeps = importNpmLock { npmRoot = ./.; };
  npmConfigHook = importNpmLock.npmConfigHook;
  # Pi supplies its own API, TUI and typebox; do not install duplicate peers.
  npmFlags = [
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];
  dontNpmBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r node_modules "$out/"
    runHook postInstall
  '';
  meta = {
    description = "Pinned language-server tools for Pi";
    homepage = "https://github.com/ian-pascoe/pi-extensions/tree/main/packages/pi-lsp";
    license = lib.licenses.mit;
  };
}
