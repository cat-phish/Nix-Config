# Agent tooling for the `code` VM (code.vm.lan). This is the swappable layer: changing which agent CLI
# or multiplexer the VM runs should only mean editing this file.
{
  pkgs,
  inputs,
  ...
}: let
  # TEMPORARY: codex fails to build on current unstable (aws-lc-sys wants a system AWS-LC), so
  # it comes from the nixpkgs-hold input, same as modules/home/dev-environment.nix. Move it back
  # into the list below once it builds again (see backlog.md).
  pkgs-hold = import inputs.nixpkgs-hold {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  # Lets prebuilt Linux binaries run (pip wheels with C extensions, uv-downloaded Pythons,
  # npm packages that ship binaries). Without it they fail with "No such file or directory".
  programs.nix-ld.enable = true;

  # Rootless Docker: each user runs their own daemon (`docker`/`docker compose` just work,
  # no docker group, which would be root-equivalent). LAN egress is blocked outside the
  # guest by the Proxmox firewall, so container traffic is covered either way.
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true; # sets DOCKER_HOST for every user
  };
  # Rootless containers need subordinate UID/GID ranges for the user running them.
  users.users.agent.autoSubUidGidRange = true;

  environment.systemPackages = with pkgs; [
    # --- Agent CLIs ---
    antigravity-cli
    claude-code
    pkgs-hold.codex # held back, see the let block above
    opencode

    # --- Dev basics ---
    fd
    gh
    gitleaks # repos' pre-commit hooks (barista-assistant, ~/.nix) refuse to commit without it
    jq
    nodejs_22
    python3
    uv
    ripgrep
    tmux

    # --- herdr ---
    # herdr-core provides `hc`; herdr-app on the desktop attaches over SSH (`ssh agent@code.vm.lan hc connect`, or the `code` alias from docs/code-vm.md).
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
