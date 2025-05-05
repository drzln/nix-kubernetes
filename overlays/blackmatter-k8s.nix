# overlays/blackmatter-k8s.nix
##############################################################################
#  overlays/blackmatter-k8s.nix
#
#  * Adds a namespace `pkgs.blackmatter.k8s` that contains every package
#    returned by ./pkgs/default.nix
#  * Leaves anything else in nixpkgs untouched
##############################################################################
self: prev: let
  k8sPkgs = import ../pkgs {inherit (prev) lib callPackage;};
  existingBlackmatter = prev.blackmatter or {};
in {blackmatter = existingBlackmatter // {k8s = k8sPkgs;};}
