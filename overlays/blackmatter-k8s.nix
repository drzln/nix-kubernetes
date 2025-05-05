# overlays/blackmatter-k8s.nix
##############################################################################
#  overlays/blackmatter-k8s.nix
#
#  * Adds a namespace `pkgs.blackmatter.k8s` that contains every package
#    returned by ./pkgs/default.nix
#  * Leaves anything else in nixpkgs untouched
##############################################################################
self: prev: let
  # Import the full Kubernetes package set; `callPackage` + `lib`
  # are taken from *prev* so other overlays can still override them.
  k8sPkgs = import ../pkgs {
    inherit (prev) lib callPackage;
  };

  # Preserve anything an earlier overlay might have put in `blackmatter`
  existingBlackmatter = prev.blackmatter or {};
in {
  # Merge (or create) the `blackmatter` namespace, then attach `k8s`
  blackmatter =
    existingBlackmatter
    // {
      k8s = k8sPkgs;
    };
}
