{
  appimageTools,
  desktop-file-utils,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
  writeText,
}:
let
  theme = import ../../lib/theme.nix;
  stylesheet = writeText "rkdeveloptool-gui-${theme.name}.qss" (
    import ./theme.nix { inherit theme writeText; }
  );
  pname = "rkdeveloptool-gui";
  version = "5.7.1";
  appId = "io.github.gahingwoo.rkdeveloptool_gui";
  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-Ow+WqHtZ2FqjBVLhsvZ39J8n4fqbGuS8njVYbRjqUGA=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-wiPL7pSczB6RxHu2uVBRIo7Eh79U0IfNJYbf42wKwVg=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
  src = fetchurl {
    url = "https://github.com/gahingwoo/RKDevelopTool-GUI/releases/download/${version}/RKDevelopTool-GUI-${version}-${source.arch}.AppImage";
    inherit (source) hash;
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;
  nativeBuildInputs = [ makeWrapper ];

  # Keep independently mounted homes and runtime sockets visible even when
  # the host's root directory enumeration omits those mount points.
  extraBwrapArgs = [
    "--bind-try /home /home"
    "--bind-try /run /run"
  ];

  profile = ''
    # The AppImage bundles its own Qt; host plugins may use a different ABI.
    unset QT_PLUGIN_PATH QML2_IMPORT_PATH QML_IMPORT_PATH
    # Nix owns this installation, not the AppImage self-updater.
    unset APPIMAGE
  '';

  extraInstallCommands = ''
    install -Dm644 ${stylesheet} "$out/share/rkdeveloptool-gui/theme.qss"
    # QApplication accepts -stylesheet; the upstream theme manager only sets
    # palettes, so this also survives its startup and live theme changes.
    wrapProgram "$out/bin/rkdeveloptool-gui" \
      --add-flags "-stylesheet $out/share/rkdeveloptool-gui/theme.qss"

    install -Dm644 ${appimageContents}/usr/share/applications/${appId}.desktop \
      "$out/share/applications/${appId}.desktop"
    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-fail 'Exec=rkdeveloptool-gui' "Exec=$out/bin/rkdeveloptool-gui"
    ${desktop-file-utils}/bin/desktop-file-validate "$out/share/applications/${appId}.desktop"

    mkdir -p "$out/share/icons"
    cp -r ${appimageContents}/usr/share/icons/hicolor "$out/share/icons/"
    install -Dm644 ${appimageContents}/usr/share/metainfo/${appId}.appdata.xml \
      "$out/share/metainfo/${appId}.appdata.xml"
    install -Dm644 ${./70-rkdeveloptool-gui.rules} \
      "$out/lib/udev/rules.d/70-rkdeveloptool-gui.rules"
  '';

  passthru = { inherit appimageContents; };

  meta = {
    description = "Graphical firmware flashing and device management for Rockchip boards";
    homepage = "https://github.com/gahingwoo/RKDevelopTool-GUI";
    license = lib.licenses.gpl3Only;
    platforms = builtins.attrNames sources;
    mainProgram = "rkdeveloptool-gui";
  };
}
