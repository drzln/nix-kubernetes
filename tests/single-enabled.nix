{
  modules = [
    ../../modules/kubernetes.nix
    ({pkgs, ...}: {
      blackmatter.components.kubernetes.enable = true;
    })
  ];

  test = {
    options,
    config,
    ...
  }:
    with builtins; {
      assertion = config.blackmatter.components.kubernetes.role == "single";
    };
}
