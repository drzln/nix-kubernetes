pkgs: {
  cilium = let
    rev = "main"; # HEAD of main
    version = "main";
  in
    pkgs.buildGoModule rec {
      pname = "cilium";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = rev;
        # Force a mismatch => Nix will fail once, and you can copy the correct SRI
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # Force vendorHash mismatch => get correct SRI from logs
      vendorHash = null;

      # The single go.mod at the repo root. We specify each subdir containing main.go.
      #
      # Binaries:
      # - daemon => main agent
      # - operator => cilium-operator
      # - bugtool => cilium-bugtool
      # - cilium-dbg => cilium-dbg
      # - cilium-health => cilium-health
      # - cilium-health/responder => cilium-health-responder
      # - hubble-relay => hubble-relay
      # - clustermesh-apiserver => clustermesh-apiserver
      # - clustermesh-apiserver/dbg => clustermesh-dbg
      # - plugins/cilium-cni => cilium-cni
      # - plugins/cilium-docker => cilium-docker
      subPackages = [
        # main agent
        "./daemon"
        # operator
        "./operator"
        # bugtool
        "./bugtool"
        # cilium-dbg (an in-agent debug CLI)
        "./cilium-dbg"
        # cilium-health (main CLI)
        "./cilium-health"
        # health responder
        "./cilium-health/responder"
        # hubble-relay
        "./hubble-relay"
        # clustermesh-apiserver
        "./clustermesh-apiserver"
        "./clustermesh-apiserver/dbg"
        # cni plugin
        "./plugins/cilium-cni"
        # docker plugin
        "./plugins/cilium-docker"
      ];

      doCheck = false; # tests require eBPF + special environment

      # If you want BPF compiled at build time, we need clang/llvm:
      nativeBuildInputs = [
        pkgs.clang
        pkgs.llvm
      ];

      ldflagsArray = [
        "-s"
        "-w"
        "-buildvcs=false"
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"

        # The agent is built as 'daemon' => rename to cilium-agent
        if [ -f "$GOPATH/bin/daemon" ]; then
          cp "$GOPATH/bin/daemon" "$out/bin/cilium-agent"
        fi

        # cilium-operator => built as 'operator'
        [ -f "$GOPATH/bin/operator" ] && cp "$GOPATH/bin/operator" "$out/bin/cilium-operator"

        # cilium-bugtool => built as 'bugtool'
        [ -f "$GOPATH/bin/bugtool" ] && cp "$GOPATH/bin/bugtool" "$out/bin/cilium-bugtool"

        # cilium-dbg => built as 'cilium-dbg'
        [ -f "$GOPATH/bin/cilium-dbg" ] && cp "$GOPATH/bin/cilium-dbg" "$out/bin/"

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

        # clustermesh-dbg => built as 'dbg'
        if [ -f "$GOPATH/bin/dbg" ]; then
          cp "$GOPATH/bin/dbg" "$out/bin/clustermesh-dbg"
        fi

        # cilium-cni => built as 'cilium-cni'
        [ -f "$GOPATH/bin/cilium-cni" ] && cp "$GOPATH/bin/cilium-cni" "$out/bin/"

        # cilium-docker => built as 'cilium-docker'
        [ -f "$GOPATH/bin/cilium-docker" ] && cp "$GOPATH/bin/cilium-docker" "$out/bin/"

        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
