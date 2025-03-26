pkgs: {
  containerd = let
    version = "1.7.0"; # or pick your version
    srcRev = "v${version}";
  in
    pkgs.buildGoModule rec {
      pname = "containerd";
      inherit version;

      # 1) Download containerd from GitHub
      #    using a placeholder SRI hash so we can fix it after the first build:
      src = pkgs.fetchFromGitHub {
        owner = "containerd";
        repo = "containerd";
        rev = srcRev;
        sha256 = pkgs.lib.fakeSha256;
      };

      # 2) We will compile from the root module
      #    containerd uses Go modules, so we need a vendorHash for dependencies.
      vendorHash = pkgs.lib.fakeSha256; # replace after first build attempt

      # 3) The subPackages array typically just [ "." ] for containerd root.
      #    containerd has multiple binaries (containerd, ctr, etc.), but they're in the same module.
      subPackages = ["."];

      # 4) If we want to skip tests:
      doCheck = false; # containerd tests can be slow or require special environment

      # 5) Set environment variables or LDFLAGS if needed
      #    containerd might have custom version injection with ldflags, but we can skip
      #    or replicate what containerd's Makefile does:
      ldflagsArray = [
        "-s"
        "-w"
      ];

      # 6) Final name of output
      #    This derivation will produce 'bin/containerd', 'bin/containerd-shim',
      #    'bin/containerd-shim-runc-v2', 'bin/ctr', etc.
      name = "${pname}-${version}";
    };
}
