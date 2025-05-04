{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "coredns";
  version = "1.12.1";
  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns";
    rev = "v${version}";
    sha256 = "sha256-XZoRN907PXNKV2iMn51H/lt8yPxhPupNfJ49Pymdm9Y=";
  };
  vendorHash = "sha256-f7ql30gJNzeldJFM0KXfLReAUSQwdyEmf7xW6lgCkpk=";
  subPackages = ["."];
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
  meta = with lib; {
    description = "CoreDNS is a DNS server that chains plugins and serves as the cluster DNS in Kubernetes.";
    homepage = "https://coredns.io";
    license = licenses.asl20;
    maintainers = [];
    platforms = platforms.linux;
  };
}
