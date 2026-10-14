{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
# ==============================================================================
# HOW TO SWITCH FROM OPTION B (LAUNCHER) TO OPTION A (DECLARATIVE FLATPAKS):
# 1. Comment out the `let ... in` block directly below (Option B).
# 2. Comment out `artcraft-launcher` inside `home.packages` below.
# 3. Uncomment the `home.activation.installArtCraftSuite` block at the bottom (Option A).
# 4. Run your `update-system` script (or `home-manager switch --flake ~/.nix`).
# ==============================================================================
# --- OPTION B (ACTIVE): ArtCraft Launcher AppImage Wrapper ---
let
  pname = "artcraft-launcher";
  version = "0.3.2";

  src = pkgs.fetchurl {
    url = "https://github.com/storytold/craft-launcher/releases/download/v${version}/artcraft-launcher-${version}-linux-x86_64.AppImage";
    # Upstream SHA-256 for v0.3.2. If bumping `version` later, get the new hash with:
    # nix-prefetch-url https://github.com/storytold/craft-launcher/releases/download/v<VERSION>/artcraft-launcher-<VERSION>-linux-x86_64.AppImage
    sha256 = "7edc70da35bf214a2215287948b8fda620b3dfe55076aec56e8d76be1a68a8b5";
  };

  appimageContents = pkgs.appimageTools.extractType2 {inherit pname version src;};

  artcraft-launcher = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraInstallCommands = ''
      mkdir -p $out/share/applications
      for desktopFile in ${appimageContents}/*.desktop; do
        if [ -f "$desktopFile" ]; then
          install -m 444 -D "$desktopFile" "$out/share/applications/artcraft-launcher.desktop"
          substituteInPlace "$out/share/applications/artcraft-launcher.desktop" \
            --replace-quiet 'Exec=artcraft-launcher' "Exec=$out/bin/artcraft-launcher" \
            --replace-quiet 'Exec=AppRun' "Exec=$out/bin/artcraft-launcher"
        fi
      done
      if [ -d "${appimageContents}/usr/share/icons" ]; then
        cp -r "${appimageContents}/usr/share/icons" "$out/share/"
      fi
    '';
  };
in
  # --- END OPTION B ---
  {
    # Plasma Manager KDE Configuration
    imports = [
    ];

    # sops.secrets = {
    # };

    home.packages =
      (with pkgs; [
        libreoffice-fresh
        onlyoffice-desktopeditors
        artcraft-launcher # <--- OPTION B: Comment this line out if switching to Option A
      ])
      ++ (with pkgs-stable; [
        ]);

    home.file = {
    };

    # ============================================================================
    # OPTION A (INACTIVE): Auto-install & update individual ArtCraft Flatpaks
    # Uncomment this entire `home.activation.installArtCraftSuite` block when you
    # want Home Manager to manage and update the individual apps on system rebuild.
    # ============================================================================
    /*
    home.activation.installArtCraftSuite = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if command -v flatpak >/dev/null 2>&1; then
        # Ensure Flathub is available in --user scope for shared runtimes
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

        STATE_DIR="$HOME/.local/state/artcraft-flatpaks"
        mkdir -p "$STATE_DIR"

        # Full ArtCraft Suite (Office + Creative)
        # Comment out any individual app you don't want installed:
        CRAFT_APPS=(
          # --- Office & Documents ---
          "wordcraft"    # Word processor
          "gridcraft"    # Spreadsheets
          "deckcraft"    # Presentations
          "pdfcraft"     # PDF viewer & editor (Acrobat alternative)

          # --- Creative Suite ---
          "photocraft"   # Raster image editor (Photoshop alternative)
          "vectorcraft"  # Vector illustration (Illustrator alternative)
          "lightcraft"   # RAW photography & catalog (Lightroom alternative)
          "filmcraft"    # Multi-track video editor (Premiere Pro alternative)
          "effectcraft"  # Motion graphics & compositing (After Effects alternative)
          "designcraft"  # Page layout & publishing (InDesign alternative)
          "figcraft"     # UI/UX interface design (Figma alternative)
          "cadcraft"     # CAD design
          "soundcraft"   # Audio editing & mastering
        )

        for repo in "''${CRAFT_APPS[@]}"; do
          release_json=$(${pkgs.curl}/bin/curl -fsSL "https://api.github.com/repos/storytold/$repo/releases/latest" || true)
          [ -z "$release_json" ] && continue

          latest_tag=$(echo "$release_json" \vert{} ${pkgs.jq}/bin/jq -r '.tag_name')
          bundle_url=$(echo "$release_json" | ${pkgs.jq}/bin/jq -r '.assets[] \vert{} select(.name \vert{} test("linux-x86_64\\.flatpak$")) | .browser_download_url' | head -n1)

          if [ -n "$bundle_url" ] && [ "$bundle_url" != "null" ]; then
            current_tag=""
            [ -f "$STATE_DIR/$repo.version" ] && current_tag=$(cat "$STATE_DIR/$repo.version")

            if [ "$latest_tag" != "$current_tag" ]; then
              echo "Installing/Updating ArtCraft $repo ($latest_tag)..."
              tmp_bundle=$(mktemp --suffix=.flatpak)
              if ${pkgs.curl}/bin/curl -fL "$bundle_url" -o "$tmp_bundle"; then
                $DRY_RUN_CMD flatpak install --user --or-update -y "$tmp_bundle"
                echo "$latest_tag" > "$STATE_DIR/$repo.version"
              fi
              rm -f "$tmp_bundle"
            fi
          fi
        done
      else
        echo "[!] flatpak command not found on host; skipping ArtCraft Flatpak setup."
      fi
    '';
    */
  }
