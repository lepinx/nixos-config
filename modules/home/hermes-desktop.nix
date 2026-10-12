# Hermes Desktop (Electron client) — the agent runtime lives on the homelab.
# The app connects to it via Settings → Gateways once the homelab backend
# exists (deferred work, see odd/tasks and Engram `hermes-agent-homelab`).
# No local gateway/backend on purpose: programs.* installs without services.*.
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
