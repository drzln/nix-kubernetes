# pkgs/metrics-server/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "metrics-server";
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "metrics-server";
    rev = "v${version}";
    sha256 = "sha256-UgltnGkzAtUfuXzNfnNWOGIKC7IUi6Yy0YZuOgyNSaA=";
  };
  vendorHash = "sha256-BZa18s4vvp8MDSavCE5l2WuAwPLQS/zzAAzxSSGHcfM=";
  subPackages = ["./cmd/metrics-server"];
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
}
