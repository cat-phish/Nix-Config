{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
  ];

  # sops.secrets = {
  # };

  home.packages =
    (with pkgs; [
      tailscale
    ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };

  # For non-NixOS systems, you'll need to enable the service manually
  # or use systemd user services
  systemd.user.services.tailscale = {
    Unit = {
      Description = "Tailscale client daemon";
      After = ["network-pre.target"];
      Wants = ["network-pre.target"];
    };
    Service = {
      ExecStart = "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --socket=%t/tailscaled.socket";
      Restart = "on-failure";
      RuntimeDirectory = "tailscale";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "tailscale";
      StateDirectoryMode = "0700";
      CacheDirectory = "tailscale";
      CacheDirectoryMode = "0750";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
