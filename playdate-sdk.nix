{
  pkgs,
}: let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
  # Build inputs for `pdc`
  pdcInputs = with pkgs; [
    stdenv.cc.cc.lib
    libpng
    zlib
  ];

  # Build inputs for the simulator (excluding those from pdc)
  pdsInputs = with pkgs; [
    udev
    gtk3
    pango
    cairo
    gdk-pixbuf
    glib
    webkitgtk_4_1
    xorg.libX11
    stdenv.cc.cc.lib
    libxkbcommon
    wayland
    libpulseaudio
    libpng
    gsettings-desktop-schemas
  ];

  dynamicLinker = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2";
in
  stdenv.mkDerivation rec {
    pname = "playdate-sdk";
    version = "3.0.2";
    src = pkgs.fetchurl {
      url = "https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-${version}.tar.gz";
      sha256 = "sha256-+vVnPgofsCwCcvPh/dfoBp2boC5L7083rehOVHSq+o0=";
    };

    buildInputs = pdcInputs;
    nativeBuildInputs = [ pkgs.makeWrapper pkgs.wrapGAppsHook3 ];

    installPhase = ''
      runHook preInstall

      # Install everything unpacked to the temporary build directory directly to $out
      cp -r ./ $out/

      # Patch binaries
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        --set-rpath "${lib.makeLibraryPath pdcInputs}" \
        $out/bin/pdc
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        $out/bin/pdutil
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        --set-rpath "${lib.makeLibraryPath pdsInputs}"\
        $out/bin/PlaydateSimulator

      # NixOS really hates writable install paths, so lets fake one by creating a script that creates a sandboxed environment

      cat > $out/bin/pdwrapper <<EOL
      #!/usr/bin/env bash
      if [ ! -d ".PlaydateSDK" ]; then
        read -p "pdwrapper> .PlaydateSDK not found. Create it in (\`pwd\`)? [y/n]" -n 1 -r
        echo
        if [[ ! \$REPLY =~ ^[Yy]$ ]]; then
          echo "pdwrapper> Cancelled"
          exit
        fi
        echo "pdwrapper> Creating .PlaydateSDK"
        mkdir .PlaydateSDK
        cp -TR $out/Disk .PlaydateSDK/Disk
        chmod -R 755 .PlaydateSDK/Disk
        ln -s $out/bin .PlaydateSDK/bin
        ln -s $out/C_API .PlaydateSDK/C_API
        ln -s $out/CoreLibs .PlaydateSDK/CoreLibs
        ln -s $out/Resources .PlaydateSDK/Resources
      fi
      echo "pdwrapper> Running .PlaydateSDK/bin/PlaydateSimulator";

      PLAYDATE_SDK_PATH=.PlaydateSDK exec -a \`pwd\`.PlaydateSDK/bin/PlaydateSimulator .PlaydateSDK/bin/PlaydateSimulator $@
      EOL
      chmod 555 $out/bin/pdwrapper

      runHook postInstall
    '';
    meta = with lib; {
      description = "The Panic Playdate game console SDK, contains the simulator PlaydateSimulator, the compiler pdc, and the util program pdutil";
      homepage = "https://play.date/dev/";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      maintainers = [
        "RegularTetragon"
        "redpenguinyt"
        "camerondugan"
        "CarlosMendonca"
      ];
    };
  }
