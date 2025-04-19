# Combined overlays for nix-kubernetes
# -------------------------------------------------------------
# ▸ Custom etcd 3.5.9 (built from source)
# ▸ Kubernetes 1.31.4 binaries (kube‑apiserver, scheduler, etc.)
# ▸ (Optional) Cilium agent/operator overlay stub – uncomment later
#
# Put this file at overlays/default.nix and list it in `activeOverlays`
# inside your flake.nix:
#   activeOverlays = [ overlays/default.nix ];
#
# Edit the “REPLACEME” hashes once you run the first build.
# -------------------------------------------------------------
[
  # ────────────────────────────────────────────────────────────
  # Custom etcd build
  (self: super: let
    version = "3.5.9";
    src = super.fetchFromGitHub {
      owner = "etcd-io";
      repo = "etcd";
      rev = "v${version}";
      hash = "sha256-Vp8U49fp0FowIuSSvbrMWjAKG2oDO1o0qO4izSnTR3U=";
    };

    common = pname: modRoot: vendorHash:
      super.buildGoModule {
        inherit version src;
        pname = pname;
        modRoot = modRoot;
        vendorHash = vendorHash; # fake first → real after 1st build
        env = {CGO_ENABLED = "0";};
        doCheck = false;
      };

    etcdserver = common "etcdserver" "./server" "sha256-vu5VKHnDbvxSd8qpIFy0bA88IIXLaQ5S8dVUJEwnKJA=";
    etcdctl = common "etcdctl" "./etcdctl" "sha256-awl/4kuOjspMVEwfANWK0oi3RId6ERsFkdluiRaaXlA=";
    etcdutl = common "etcdutl" "./etcdutl" "sha256-i60rKCmbEXkdFOZk2dTbG5EtYKb5eCBSyMcsTtnvATs=";

    etcd = super.symlinkJoin {
      name = "etcd-${version}";
      paths = [etcdserver etcdctl etcdutl];
    };
  in {
    inherit etcd;
  })

  # ────────────────────────────────────────────────────────────
  # Kubernetes binaries overlay
  (self: super: let
    version = "1.31.4"; # matches nixpkgs‑unstable today
    src = super.fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      hash = "sha256-XEilva/K2xGZHhrifaK/f4a3PGPb5dClOqv1dlJOTCM=";
    };
    vendorHash = null;

    build = pname: path:
      super.buildGoModule {
        inherit version src vendorHash pname;
        subPackages = [path];
        ldflags = [
          "-s"
          "-w"
          "-X"
          "k8s.io/component-base/version.gitVersion=v${version}"
        ];
        doCheck = false;
      };
  in {
    kubelet = build "kubelet" "./cmd/kubelet";
    # kube-apiserver = build "kube-apiserver" "./cmd/kube-apiserver";
    # kube-controller-manager = build "kube-controller-manager" "./cmd/kube-controller-manager";
    # kube-scheduler = build "kube-scheduler" "./cmd/kube-scheduler";
    # kubectl = build "kubectl" "./cmd/kubectl";
  })

  # ────────────────────────────────────────────────────────────
  # Optional future overlay: build Cilium agent/operator images
  # Uncomment & complete the hashes if you need fully hermetic images.
  # (self: super: {
  #   cilium-agent = /* buildGoModule … */;
  #   cilium-operator = /* buildGoModule … */;
  #   cilium-image = super.dockerTools.buildImage {
  #     name = "cilium";
  #     tag  = "1.17.3";
  #     copyToRoot = super.buildEnv {
  #       name = "cilium-root";
  #       paths = [ self.cilium-agent self.cilium-operator ];
  #     };
  #     config.Cmd = [ "/cilium/bin/cilium-agent" ];
  #   };
  # })
]
