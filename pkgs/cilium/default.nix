pkgs: {
  cilium = let
    version = "1.13.4";
    rev = "v${version}";
  in
    pkgs.buildGoModule rec {
      pname = "cilium";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = rev;
        # Force a mismatch by using an old containerd hash, so we see the correct SRI in the error
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # We skip specifying a real vendorHash or goModSha256 => triggers a mismatch
      vendorHash = null;

      # Cilium's main binaries are each in a subdirectory with a main.go
      # We typically want at least "cilium", "cilium-agent", "cilium-bugtool", and "cilium-operator".
      subPackages = [
        "./cmd/cilium"
        "./cmd/cilium-agent"
        "./cmd/cilium-bugtool"
        "./operator/cmd/cilium-operator"
      ];

      doCheck = false; # skip tests for speed & eBPF environment issues

      ldflagsArray = [
        "-s"
        "-w"
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"

        # Copy all built binaries from $GOPATH/bin
        cp "$GOPATH"/bin/* "$out/bin/" || true

        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
