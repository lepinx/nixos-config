# Electron client only: the agent runtime lives on the homelab and no local
# gateway/backend is configured on purpose.
{
  inputs,
  ...
}:

{
  imports = [
    inputs.hermes-agent.homeManagerModules.default
  ];

  programs.hermes-agent.desktop.enable = true;
}
