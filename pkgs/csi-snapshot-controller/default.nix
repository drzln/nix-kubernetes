{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "csi-snapshot-controller";
  version = "v6.3.3"; # latest stable at time of writing

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-snapshotter";
    rev = version;
    sha256 = "sha256-pk9600PSp3smMqOqm8cnB8ITFheiLEWonB5dfht/5Tw=";
  };

  vendorHash = null;

  subPackages = ["cmd/snapshot-controller"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = with lib; {
    description = "CSI external snapshot controller for managing PVC snapshots";
    homepage = "https://github.com/kubernetes-csi/external-snapshotter";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
