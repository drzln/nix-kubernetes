{
  name = "kubernetes-options-basic";

  nodes.machine = {...}: {
    imports = [
      ../modules
    ];
    kubernetes.enable = true;
  };

  testScript = ''
    # basic asserts on defaults
    assert machine.config.blackmatter.components.kubernetes.enable
    assert "single" == machine.config.blackmatter.components.kubernetes.role
    assert "30000-32767" == machine.config.blackmatter.components.kubernetes.nodePortRange
  '';
}
