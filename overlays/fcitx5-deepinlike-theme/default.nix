{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "fcitx5-deepinlike-theme";
  version = "0-unstable-2026-11-09";

  src = fetchFromGitHub {
    owner = "SkyShadowHero";
    repo = "deepinlike-fcitx5-theme";
    rev = "abb873e686fc6e8ba5703791f1fa382a460f6db1";
    hash = "sha256-KPjKcS0Fw+wX6RBnhX4Sg8KIgBD7As3xyZWOCTWSPIA=";
  };

  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/fcitx5/themes"
    cp -r deepinExp-* "$out/share/fcitx5/themes/"
    runHook postInstall
  '';

  meta = {
    description = "Deepin-like light and dark themes for Fcitx5, including Neo variants";
    homepage = "https://github.com/SkyShadowHero/deepinlike-fcitx5-theme";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.linux;
  };
}
