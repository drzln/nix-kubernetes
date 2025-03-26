pkgs: {
  cilium = let
    version = "1.13.4"; # or pick your desired version
    rev = "v${version}";
  in
    pkgs.buildGoModule rec {
      pname = "cilium";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = rev;
        # Force a mismatch with an old containerd hash or your own mismatch:
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # We skip or set vendorHash=null to force Nix to print the correct one
      vendorHash = null;

      # Adjust subPackages for the real directory layout:
      #
      # - cilium/cmd/cilium => builds the "cilium" CLI
      # - cilium/cmd/cilium-bugtool => builds cilium-bugtool
      # - daemon/cmd => builds the main agent binary named "daemon"
      # - operator/cmd/cilium-operator => builds cilium-operator
      #
      subPackages = [
        "./cilium/cmd/cilium"
        "./cilium/cmd/cilium-bugtool"
        "./daemon/cmd"
        "./operator/cmd/cilium-operator"
      ];

      doCheck = false; # skip tests to avoid eBPF env issues

      ldflagsArray = [
        "-s"
        "-w"
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"

        # By default, each subPackage builds a binary in $GOPATH/bin
        # Let’s rename them to something more standard:

        # If cilium CLI is built => $GOPATH/bin/cilium
        [ -f "$GOPATH/bin/cilium" ] && cp "$GOPATH/bin/cilium" "$out/bin/"

        # cilium-bugtool => $GOPATH/bin/cilium-bugtool
        [ -f "$GOPATH/bin/cilium-bugtool" ] && cp "$GOPATH/bin/cilium-bugtool" "$out/bin/"

        # cilium-operator => $GOPATH/bin/cilium-operator
        [ -f "$GOPATH/bin/cilium-operator" ] && cp "$GOPATH/bin/cilium-operator" "$out/bin/"

        # The main agent is built as 'daemon' => rename it 'cilium-agent'
        if [ -f "$GOPATH/bin/daemon" ]; then
          cp "$GOPATH/bin/daemon" "$out/bin/cilium-agent"
        fi

        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
