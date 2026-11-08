# Agent tooling for agent-vm. This is the swappable layer: changing which agent CLI
# or multiplexer the VM runs should only mean editing this file.
{pkgs, ...}: {
  # Lets prebuilt Linux binaries run (pip wheels with C extensions, uv-downloaded Pythons,
  # npm packages that ship binaries). Without it they fail with "No such file or directory".
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    # --- Agent CLIs ---
    antigravity-cli
    claude-code
    codex
    # TODO: drop override once nixpkgs fixes the opencode node_modules hash (same as modules/home/dev-environment.nix)
    (opencode.overrideAttrs (old: {
      node_modules = old.node_modules.overrideAttrs {
        outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
      };
    }))

    # --- Dev basics ---
    fd
    gh
    jq
    nodejs_22
    python3
    uv
    ripgrep
    tmux

    # --- herdr ---
    # herdr-core provides `hc`; herdr-app on the desktop attaches over SSH (`ssh agent-vm hc connect`).
    herdr-core
  ];

  # Start herdr's core at boot for `agent` (linger is on, so its user manager starts
  # without a login) instead of waiting for the first client to connect.
  systemd.user.services.herdr-core = {
    description = "herdr core";
    unitConfig.ConditionUser = "agent";
    wantedBy = ["default.target"];
    after = ["network-online.target"];
    serviceConfig = {
      # `hc server start` launches the core and returns; the core stays in this unit's cgroup.
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.herdr-core}/bin/hc server start";
      ExecStop = "${pkgs.herdr-core}/bin/hc server stop";
      TimeoutStartSec = 60;
    };
  };
}
