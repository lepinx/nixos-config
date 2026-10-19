# Native CLI only: no desktop app, no local gateway service. The always-on
# runtime lives on the homelab (podman); this is the local interactive CLI.
{
  inputs,
  ...
}:

{
  imports = [
    inputs.hermes-agent.homeManagerModules.default
  ];

  programs.hermes-agent.enable = true;

  # Gateway URL: ~/.config/hermes/gateway-url, read in workstation.nix.
}
