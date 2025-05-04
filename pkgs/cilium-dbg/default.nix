# pkgs/cilium-dbg/default.nix
{ lib, buildGoModule, fetchFromGitHub, ... }: let
  version = "1.17.3";                                   # same tag as the agent
in
buildGoModule {
  pname   = "cilium-dbg";
  inherit version;

  src = fetchFromGitHub {
    owner  = "cilium";
    repo   = "cilium";
    rev    = "v${version}";
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";           # tar-ball hash
  };

  vendorHash  = null;                                   # first build prints it
  subPackages = [ "cilium-dbg/cmd" ];                   # ← correct path

  env.CGO_ENABLED = "0";
  ldflags = [
    "-s" "-w"
    "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "On-node Cilium debug CLI (replaces the old `cilium` command)";
    homepage    = "https://github.com/cilium/cilium";
    license     = licenses.asl20;
    maintainers = [ maintainers.yourGithubHandle ];
    platforms   = platforms.linux;
  };
}

