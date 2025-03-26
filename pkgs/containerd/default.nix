pkgs: {
  containerd = let
    version = "1.7.0";
    rev = "v${version}";
  in
    pkgs.buildGoModule rec {
      pname = "containerd";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "containerd";
        repo = "containerd";
        rev = rev;
        # Replace this if needed. If you see a mismatch, copy
        # the correct SRI hash that Nix prints in the error.
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # containerd uses Go modules => we must provide a vendorHash or goModSha256
      # If you don't have the real SRI hash yet, do:
      #    vendorHash = pkgs.lib.fakeSha256;
      # Then run a build once, take the printed hash from the error, and plug it back in.
      vendorHash = pkgs.lib.fakeSha256;

      # Each sub-package under cmd/ builds a main binary.
      subPackages = [
        "./cmd/containerd"
        "./cmd/ctr"
        "./cmd/containerd-shim-runc-v1"
        "./cmd/containerd-shim-runc-v2"
      ];

      doCheck = false; # containerd tests can be slow or require root privileges

      ldflagsArray = [
        "-s"
        "-w"
      ];

      # Copy the newly built binaries from $GOPATH/bin/ into $out/bin/
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        cp $GOPATH/bin/* "$out/bin/"
        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
