{ fetchFromGitHub }:
# pi-open-tui 0.4.0 has no runtime dependencies beyond Pi's own APIs.
fetchFromGitHub {
  name = "pi-open-tui-0.4.0";
  owner = "OldSuns";
  repo = "pi-open-tui";
  rev = "7bf1a00d19ef90a786059562fe61e4551a3f83c0";
  hash = "sha256-yaE9l4JWH/TzTjH/AuLtv3WOcxHBAWDPIEKBw4zKsO8=";
}
