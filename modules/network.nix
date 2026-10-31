{ ... }:
let
  proxy = "http://127.0.0.1:7890";
  bypass = "localhost,127.0.0.1,::1,.localhost";
in
{
  # Windows .wslconfig must keep networkingMode=mirrored.
  networking.proxy = {
    default = proxy;
    noProxy = bypass;
  };

  # The daemon does not inherit a terminal's environment.
  systemd.services.nix-daemon.environment = {
    http_proxy = proxy;
    https_proxy = proxy;
    HTTP_PROXY = proxy;
    HTTPS_PROXY = proxy;
    no_proxy = bypass;
    NO_PROXY = bypass;
  };

  environment.sessionVariables = {
    HTTP_PROXY = proxy;
    HTTPS_PROXY = proxy;
    NO_PROXY = bypass;
  };
}
