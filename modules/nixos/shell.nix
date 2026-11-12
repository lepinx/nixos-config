{ pkgs, userName, ... }:

# Interactive comfort for the server hosts, which do not run home-manager.
# Bash stays the default for root so a recovery shell is never a surprise, and
# nothing here changes non-interactive behaviour: fish only matters when a human
# is on the other side of the SSH session.
{
  programs.fish.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      # Hostname matters with three machines, and it already defaults to
      # ssh_only. A server prompt should stay cheap: no scan of every
      # directory for git state.
      format = "$host$directory$git_branch$git_status$character";
    };
  };

  # The pinned starship module only wires bash, so fish gets the canonical
  # init line instead of a module option that does not exist here.
  programs.fish.interactiveShellInit = ''
    starship init fish | source
  '';

  users.users.${userName}.shell = pkgs.fish;
}
