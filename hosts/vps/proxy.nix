{ ... }:
{
  fleet.reality = {
    enable = true;
    port = 443;
    # Example SNI/handshake target. Confirm it is reachable from your VPS.
    handshakeHost = "www.microsoft.com";
    handshakePort = 443;
    secretDirectory = "/var/lib/sing-box-secrets";
  };
}
