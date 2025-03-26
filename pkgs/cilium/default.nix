pkgs: {
  cilium = let
    rev = "main"; # Tracking the Cilium main branch
    version = "main";
  in
    pkgs.buildGoModule rec {
      pname = "cilium";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = rev;
        # Force mismatch => on first build, Nix will print the correct SRI for the main branch
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # Force a mismatch so Nix shows the correct vendor hash
      vendorHash = null;

      # The main branch uses a single go.mod for all sub-packages:
      # Here we specify each subdir that has a 'main.go' and build them.
      #
      # For a full eBPF-based deployment, you typically need:
      #   - cilium-agent (daemon/)
      #   - cilium-dbg (cilium-dbg/) [the in-container CLI]
      #   - cilium-bugtool (bugtool/)
      #   - cilium-operator (operator/)
      #   - cilium-health + cilium-health-responder (cilium-health/)
      #   - hubble-relay (hubble-relay/)
      #   - clustermesh-apiserver + clustermesh-dbg (clustermesh-apiserver/)
      #   - cilium-cni (plugins/cilium-cni/)
      #   - cilium-docker (plugins/cilium-docker/) for Docker networks (optional in K8s)
      subPackages = [
        "./daemon"
        "./cilium-dbg"
        "./bugtool"
        "./operator"
        "./cilium-health"
        "./cilium-health/responder"
        "./hubble-relay"
        "./clustermesh-apiserver"
        "./clustermesh-apiserver/clustermesh-dbg"
        "./plugins/cilium-cni"
        "./plugins/cilium-docker"
      ];

      # We skip tests (they can be huge or require eBPF kernel environment).
      doCheck = false;

      # Provide clang/llvm so BPF programs can be compiled if the build triggers that step
      nativeBuildInputs = [
        pkgs.llvm
        pkgs.clang
      ];

      # Minimal LDFLAGS + disable VCS stamping to avoid 'no .git' issues in a Nix build
      ldflagsArray = [
        "-s"
        "-w"
        "-buildvcs=false"
      ];

      # We rename each built binary in installPhase => put them into $out/bin
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"

        # Usually each subPackage produces a binary named after the subdir's last component
        # We'll rename them to the standard final names:

        # Agent => built as 'daemon'
        [ -f "$GOPATH/bin/daemon" ] && cp "$GOPATH/bin/daemon" "$out/bin/cilium-agent"

        # cilium-dbg => built as 'cilium-dbg'
        [ -f "$GOPATH/bin/cilium-dbg" ] && cp "$GOPATH/bin/cilium-dbg" "$out/bin/"

        # bugtool => built as 'bugtool'
        [ -f "$GOPATH/bin/bugtool" ] && cp "$GOPATH/bin/bugtool" "$out/bin/cilium-bugtool"

        # operator => built as 'operator'
        [ -f "$GOPATH/bin/operator" ] && cp "$GOPATH/bin/operator" "$out/bin/cilium-operator"

        # cilium-health => built as 'cilium-health'
        [ -f "$GOPATH/bin/cilium-health" ] && cp "$GOPATH/bin/cilium-health" "$out/bin/"

        # cilium-health-responder => built as 'responder'
        if [ -f "$GOPATH/bin/responder" ]; then
          cp "$GOPATH/bin/responder" "$out/bin/cilium-health-responder"
        fi

        # hubble-relay => built as 'hubble-relay'
        [ -f "$GOPATH/bin/hubble-relay" ] && cp "$GOPATH/bin/hubble-relay" "$out/bin/"

        # clustermesh-apiserver => built as 'clustermesh-apiserver'
        [ -f "$GOPATH/bin/clustermesh-apiserver" ] && cp "$GOPATH/bin/clustermesh-apiserver" "$out/bin/"

        # clustermesh-dbg => built as 'clustermesh-dbg'
        [ -f "$GOPATH/bin/clustermesh-dbg" ] && cp "$GOPATH/bin/clustermesh-dbg" "$out/bin/"

        # cilium-cni => built as 'cilium-cni'
        [ -f "$GOPATH/bin/cilium-cni" ] && cp "$GOPATH/bin/cilium-cni" "$out/bin/"

        # cilium-docker => built as 'cilium-docker'
        [ -f "$GOPATH/bin/cilium-docker" ] && cp "$GOPATH/bin/cilium-docker" "$out/bin/"

        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
