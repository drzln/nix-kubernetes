pkgs: {
  cilium = let
    rev = "v1.9.9"; # pinned release tag
    version = "1.9.9";
  in
    pkgs.buildGoModule rec {
      pname = "cilium";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = rev;
        # Force mismatch => On first build, Nix prints the correct SRI
        sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
      };

      # We'll also let Nix fail for vendored deps, so we can fix them
      vendorHash = null;

      # v1.9.9 sub-packages that exist:
      # - daemon => agent
      # - operator => cilium-operator
      # - bugtool => cilium-bugtool
      # - cilium-health => cilium-health
      # - cilium-health/responder => cilium-health-responder
      # - hubble-relay => hubble-relay
      # - clustermesh-apiserver => clustermesh-apiserver
      # - clustermesh-apiserver/debug => clustermesh-apiserver-debug
      # - plugins/cilium-cni => cilium-cni
      # - plugins/cilium-docker => cilium-docker
      # (No cilium-dbg subdir in 1.9.9, so skip that.)
      subPackages = [
        "./daemon"
        "./operator"
        "./bugtool"
        "./cilium-health"
        "./cilium-health/responder"
        "./hubble-relay"
        "./clustermesh-apiserver"
        "./clustermesh-apiserver/debug"
        "./plugins/cilium-cni"
        "./plugins/cilium-docker"
      ];

      doCheck = false;

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

        # main agent => compiled as "daemon"
        [ -f "$GOPATH/bin/daemon" ] && cp "$GOPATH/bin/daemon" "$out/bin/cilium-agent"

        # operator => "operator"
        [ -f "$GOPATH/bin/operator" ] && cp "$GOPATH/bin/operator" "$out/bin/cilium-operator"

        # bugtool => "bugtool"
        [ -f "$GOPATH/bin/bugtool" ] && cp "$GOPATH/bin/bugtool" "$out/bin/cilium-bugtool"

        # cilium-health => "cilium-health"
        [ -f "$GOPATH/bin/cilium-health" ] && cp "$GOPATH/bin/cilium-health" "$out/bin/"

        # cilium-health-responder => "responder"
        if [ -f "$GOPATH/bin/responder" ]; then
          cp "$GOPATH/bin/responder" "$out/bin/cilium-health-responder"
        fi

        # hubble-relay => "hubble-relay"
        [ -f "$GOPATH/bin/hubble-relay" ] && cp "$GOPATH/bin/hubble-relay" "$out/bin/"

        # clustermesh-apiserver => "clustermesh-apiserver"
        [ -f "$GOPATH/bin/clustermesh-apiserver" ] && cp "$GOPATH/bin/clustermesh-apiserver" "$out/bin/"

        # clustermesh-apiserver/debug => "debug"
        if [ -f "$GOPATH/bin/debug" ]; then
          cp "$GOPATH/bin/debug" "$out/bin/clustermesh-apiserver-debug"
        fi

        # cilium-cni => "cilium-cni"
        [ -f "$GOPATH/bin/cilium-cni" ] && cp "$GOPATH/bin/cilium-cni" "$out/bin/"

        # cilium-docker => "cilium-docker"
        [ -f "$GOPATH/bin/cilium-docker" ] && cp "$GOPATH/bin/cilium-docker" "$out/bin/"

        runHook postInstall
      '';

      name = "${pname}-${version}";
    };
}
