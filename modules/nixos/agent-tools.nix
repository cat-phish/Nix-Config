# Agent tooling for agent-vm. This is the swappable layer: changing which agent CLI
# or multiplexer the VM runs should only mean editing this file.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # --- Agent CLIs ---
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
    neovim
    nodejs_22
    ripgrep
    tmux

    # --- herdr ---
    # herdr-core provides `hc`; herdr-app on the desktop attaches over SSH (`ssh agent-vm hc connect`).
    # hc starts its core on demand. If it turns out not to survive SSH logout, add a
    # systemd.user.services unit here running `hc server start` (agent has linger on).
    herdr-core
  ];
}
