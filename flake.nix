 {
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = {self, nixpkgs, ...}:
    let system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        playdate-sdk = import ./playdate-sdk.nix {
          inherit pkgs;
        };
    in {
      packages.${system}.default = playdate-sdk;
      devShells.${system}.default = pkgs.mkShell {
        packages = [playdate-sdk];
        shellHook = ''
          export PLAYDATE_SDK_PATH="${playdate-sdk}"
          export SDL_AUDIODRIVER=pulseaudio
          echo "PlaydateSimulator ready. Run 'pdwrapper' if you need writable storage."
        '';
      };
      overlays.default = final: prev: {
        playdate-sdk = final.callPackage ./playdate-sdk.nix {};
      };
      checks.${system}.default = pkgs.runCommand "playdate-sdk-check" {
        buildInputs = [ playdate-sdk ];
      } ''
        # Test that pdc --version returns the expected version
        version_output=$(pdc --version 2>&1)
        expected_version="${playdate-sdk.version}"

        if echo "$version_output" | grep -q "$expected_version"; then
          echo "✓ pdc version check passed: $version_output"
          touch $out
        else
          echo "✗ pdc version check failed"
          echo "Expected: $expected_version"
          echo "Got: $version_output"
          exit 1
        fi
      '';
  };
}
