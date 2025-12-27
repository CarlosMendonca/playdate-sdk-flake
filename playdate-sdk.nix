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
  playdateSimulatorInputs = with pkgs; [
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

    buildInputs = playdateSimulatorInputs;
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
        --set-rpath "${lib.makeLibraryPath playdateSimulatorInputs}"\
        $out/bin/PlaydateSimulator

      # Install sandbox setup script
      mkdir -p $out/libexec
      cp ${./playdate-sandbox-setup.sh} $out/libexec/playdate-sandbox-setup.sh
      substituteInPlace $out/libexec/playdate-sandbox-setup.sh \
        --replace-fail '@PLAYDATE_SDK@' "$out"
      chmod +x $out/libexec/playdate-sandbox-setup.sh

      runHook postInstall
    '';

    dontWrapGApps = true;

    postFixup = ''
      mv $out/bin/PlaydateSimulator $out/bin/.PlaydateSimulator-unwrapped
      makeShellWrapper $out/bin/.PlaydateSimulator-unwrapped $out/bin/PlaydateSimulator \
        "''${gappsWrapperArgs[@]}" \
        --run ". $out/libexec/playdate-sandbox-setup.sh"
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
