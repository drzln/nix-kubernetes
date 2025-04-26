pkgs: {
  # 1) cilium-bugtool
  cilium-bugtool = let
    version = "1.9.9";
    rev = "v${version}";
  in
    pkgs.buildGoModule rec {
      pname = "cilium-bugtool";
      inherit version;

      # We'll reference cilium/cilium at v1.9.9
      src = pkgs.fetchFromGitHub {
        inherit rev;
        owner = "cilium";
        repo = "cilium";
        sha256 = pkgs.lib.fakeSha256; # mismatch => copy correct SRI
      };

      vendorHash = pkgs.lib.fakeSha256; # also mismatch => fix after logs

      # Just the bugtool subdir
      subPackages = ["./bugtool"];

      doCheck = false;

      # No clang/llvm needed for bugtool (no BPF)
      nativeBuildInputs = [];

      # We rename the built binary (default is "bugtool") to "cilium-bugtool"
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        [ -f "$GOPATH/bin/bugtool" ] && cp "$GOPATH/bin/bugtool" "$out/bin/cilium-bugtool"
        runHook postInstall
      '';

      name = "${pname}-${version}";
    };

  # 2) cilium-docker
  # cilium-docker = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "cilium-docker";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     subPackages = ["./plugins/cilium-docker"];
  #
  #     doCheck = false;
  #
  #     # Also no BPF compile here
  #     nativeBuildInputs = [];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       [ -f "$GOPATH/bin/cilium-docker" ] && cp "$GOPATH/bin/cilium-docker" "$out/bin/cilium-docker"
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };

  # 3) cilium-cni
  # cilium-cni = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "cilium-cni";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     subPackages = ["./plugins/cilium-cni"];
  #
  #     doCheck = false;
  #
  #     # No BPF needed, just the CNI plugin
  #     nativeBuildInputs = [];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       [ -f "$GOPATH/bin/cilium-cni" ] && cp "$GOPATH/bin/cilium-cni" "$out/bin/cilium-cni"
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };

  # 4) cilium-health (main + responder)
  # cilium-health = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "cilium-health";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     # Two sub-packages: cilium-health and the responder
  #     subPackages = [
  #       "./cilium-health"
  #       "./cilium-health/responder"
  #     ];
  #
  #     doCheck = false;
  #
  #     nativeBuildInputs = [];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       # cilium-health => "cilium-health"
  #       [ -f "$GOPATH/bin/cilium-health" ] && cp "$GOPATH/bin/cilium-health" "$out/bin/"
  #
  #       # The responder => built as "responder"
  #       if [ -f "$GOPATH/bin/responder" ]; then
  #         cp "$GOPATH/bin/responder" "$out/bin/cilium-health-responder"
  #       fi
  #
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };

  # 5) cilium-operator
  # cilium-operator = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "cilium-operator";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     subPackages = ["./operator"];
  #
  #     doCheck = false;
  #
  #     nativeBuildInputs = [
  #       # No BPF compile, but might want clang if operator does something special
  #     ];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       [ -f "$GOPATH/bin/operator" ] && cp "$GOPATH/bin/operator" "$out/bin/cilium-operator"
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };
  #
  # # 6) cilium-agent (main daemon)
  # cilium-agent = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "cilium-agent";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     # The big code is in daemon/
  #     subPackages = ["./daemon"];
  #
  #     doCheck = false;
  #
  #     # The agent might compile eBPF => clang/llvm recommended
  #     nativeBuildInputs = [
  #       pkgs.clang
  #       pkgs.llvm
  #     ];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       # built as "daemon", rename to cilium-agent
  #       [ -f "$GOPATH/bin/daemon" ] && cp "$GOPATH/bin/daemon" "$out/bin/cilium-agent"
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };

  # 7) hubble-relay
  # hubble-relay = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "hubble-relay";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     subPackages = ["./hubble-relay"];
  #
  #     doCheck = false;
  #
  #     nativeBuildInputs = [];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       [ -f "$GOPATH/bin/hubble-relay" ] && cp "$GOPATH/bin/hubble-relay" "$out/bin/hubble-relay"
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };

  # 8) clustermesh-apiserver (and debug)
  # clustermesh-apiserver = let
  #   version = "1.9.9";
  #   rev = "v${version}";
  # in
  #   pkgs.buildGoModule rec {
  #     pname = "clustermesh-apiserver";
  #     inherit version;
  #
  #     src = pkgs.fetchFromGitHub {
  #       owner = "cilium";
  #       repo = "cilium";
  #       rev = rev;
  #       sha256 = pkgs.lib.fakeSha256;
  #     };
  #
  #     vendorHash = pkgs.lib.fakeSha256;
  #
  #     # We build both the main server & its debug subdir if present in 1.9.9
  #     subPackages = [
  #       "./clustermesh-apiserver"
  #       "./clustermesh-apiserver/debug"
  #     ];
  #
  #     doCheck = false;
  #
  #     nativeBuildInputs = [];
  #
  #     installPhase = ''
  #       runHook preInstall
  #       mkdir -p "$out/bin"
  #       [ -f "$GOPATH/bin/clustermesh-apiserver" ] && cp "$GOPATH/bin/clustermesh-apiserver" "$out/bin/clustermesh-apiserver"
  #
  #       # The debug subpackage might produce "debug"
  #       if [ -f "$GOPATH/bin/debug" ]; then
  #         cp "$GOPATH/bin/debug" "$out/bin/clustermesh-apiserver-debug"
  #       fi
  #
  #       runHook postInstall
  #     '';
  #
  #     name = "${pname}-${version}";
  #   };
}
