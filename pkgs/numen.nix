# numen (voice control, https://git.sr.ht/~geb/numen), built from the
# `numen-src` flake input (upstream master; `nix flake update numen-src` to
# update). Not the nixpkgs `numen`, which is an unrelated calculator library.
# Used by modules/home/app-numen.nix; see docs/numen.md.
{
  lib,
  stdenv,
  buildGoModule,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  scdoc,
  alsa-utils,
  dotool,
  gawk,
  gnused,
  coreutils,
  libnotify,
  src,
  version,
  # Vosk model used when $NUMEN_MODEL isn't set.
  model,
}: let
  # libvosk isn't in nixpkgs, and building it means building Vosk's Kaldi
  # fork; numen's own install instructions use this prebuilt release too.
  libvosk = stdenv.mkDerivation rec {
    pname = "libvosk";
    version = "0.3.45";
    src = fetchzip {
      url = "https://github.com/alphacep/vosk-api/releases/download/v${version}/vosk-linux-x86_64-${version}.zip";
      hash = "sha256-ToMDbD5ooFMHU0nNlfpLynF29kkfMknBluKO5PipLFY=";
    };
    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib];
    installPhase = ''
      install -Dm755 libvosk.so -t $out/lib
      install -Dm644 vosk_api.h -t $out/include
    '';
  };
in
  buildGoModule {
    pname = "numen";
    inherit version src;
    # Changes only when upstream changes its Go dependencies; if an update
    # fails with a hash mismatch, paste the "got:" hash here.
    vendorHash = "sha256-Y3CbAnIK+gEcUfll9IlEGZE/s3wxdhAmTJkj9zlAtoQ=";
    subPackages = ["."];

    buildInputs = [libvosk];
    nativeBuildInputs = [scdoc makeWrapper];

    ldflags = [
      "-X main.Version=${version}"
      "-X main.DefaultModelPackage=vosk-model-en-us-0.22-lgraph"
      "-X main.DefaultModelPaths=${model}"
      "-X main.DefaultPhrasesDir=${placeholder "out"}/share/numen/phrases"
    ];

    # Same layout as upstream's build.sh install, under $out/share/numen.
    postInstall = ''
      install -Dm755 numenc -t $out/bin
      install -Dm755 scripts/* -t $out/share/numen/scripts
      install -Dm644 phrases/* -t $out/share/numen/phrases
      sed -i "s:/etc/numen/scripts:$out/share/numen/scripts:g" \
        $out/share/numen/scripts/* $out/share/numen/phrases/*
      mkdir -p $out/share/man/man1
      scdoc < doc/numen.1.scd > $out/share/man/man1/numen.1

      # Suffix, not prefix: phrase actions run with the user's PATH, and a
      # dotool in /usr/local/bin (older manual installs) still wins.
      # The real binary keeps the name "numen" (wrapProgram would rename it
      # .numen-wrapped), because numen-mode and the tray find it with pgrep -x.
      mkdir -p $out/libexec/numen
      mv $out/bin/numen $out/libexec/numen/numen
      makeWrapper $out/libexec/numen/numen $out/bin/numen \
        --suffix PATH : ${lib.makeBinPath [alsa-utils dotool gawk gnused coreutils libnotify]}
    '';

    meta = {
      description = "Voice control for handsfree computing";
      homepage = "https://git.sr.ht/~geb/numen";
      license = lib.licenses.agpl3Only;
      mainProgram = "numen";
      platforms = ["x86_64-linux"];
    };
  }
