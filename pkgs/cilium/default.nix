pkgs: {
  cilium = let
    rev = "main";
    version = "main";
  in
    pkgs.buildGoModule rec {
      pname = "cilium";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = rev;
        # Intentional mismatch => Nix will fail once, printing the correct SRI
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # Force mismatch => we'll see the correct vendorHash from Nix
      vendorHash = null;

      # Cilium’s top-level go.mod covers these sub-packages:
      # - cmd/cilium => main agent (binary named 'cilium')
      # - cmd/operator => cilium-operator
      # - cmd/bugtool => cilium-bugtool
      # - cmd/health => cilium-health
      # - cmd/health-responder => cilium-health-responder
      # - cmd/hubble-relay => hubble-relay
      # - cmd/clustermesh-apiserver => clustermesh-apiserver
      # - cmd/clustermesh-dbg => clustermesh-dbg
      # - plugins/cilium-cni => cilium-cni
      # - plugins/cilium-docker => cilium-docker
      # (No 'cilium-agent' folder. The 'cilium' binary is used for the agent.)
      subPackages = [
        "./cmd/cilium"
        "./cmd/operator"
        "./cmd/bugtool"
        "./cmd/health"
        "./cmd/health-responder"
        "./cmd/hubble-relay"
        "./cmd/clustermesh-apiserver"
        "./cmd/clustermesh-dbg"
        "./plugins/cilium-cni"
        "./plugins/cilium-docker"
      ];

      doCheck = false; # tests require specialized eBPF environment

      # If you want to compile BPF programs ahead of time, clang & llvm needed:
      nativeBuildInputs = [
        pkgs.clang
        pkgs.llvm
      ];

      # Minimal LDFLAGS => strip + disable VCS stamping
      ldflagsArray = [
        "-s"
        "-w"
        "-buildvcs=false"
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"

        # The main agent is built as "cilium" => rename to "cilium-agent" for clarity
        if [ -f "$GOPATH/bin/cilium" ]; then
          cp "$GOPATH/bin/cilium" "$out/bin/cilium-agent"
        fi

        # operator => built as "operator"
        [ -f "$GOPATH/bin/operator" ] && cp "$GOPATH/bin/operator" "$out/bin/cilium-operator"

        # bugtool => "bugtool"
        [ -f "$GOPATH/bin/bugtool" ] && cp "$GOPATH/bin/bugtool" "$out/bin/cilium-bugtool"

        # health => "health"
        [ -f "$GOPATH/bin/health" ] && cp "$GOPATH/bin/health" "$out/bin/cilium-health"

        # health-responder => "health-responder"
        [ -f "$GOPATH/bin/health-responder" ] && cp "$GOPATH/bin/health-responder" "$out/bin/cilium-health-responder"

        # hubble-relay => "hubble-relay"
        [ -f "$GOPATH/bin/hubble-relay" ] && cp "$GOPATH/bin/hubble-relay" "$out/bin/hubble-relay"

        # clustermesh-apiserver => "clustermesh-apiserver"
        [ -f "$GOPATH/bin/clustermesh-apiserver" ] && cp "$GOPATH/bin/clustermesh-apiserver" "$out/bin/"

        # clustermesh-dbg => "clustermesh-dbg"
        [ -f "$GOPATH/bin/clustermesh-dbg" ] && cp "$GOPATH/bin/clustermesh-dbg" "$out/bin/"

        # cilium-cni => "cilium-cni"
        [ -f "$GOPATH/bin/cilium-cni" ] && cp "$GOPATH/bin/cilium-cni" "$out/bin/"

        # cilium-docker => "cilium-docker"
        [ -f "$GOPATH/bin/cilium-docker" ] && cp "$GOPATH/bin/cilium-docker" "$out/bin/"

        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
