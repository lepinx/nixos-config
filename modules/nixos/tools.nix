{ pkgs, ... }:

# Baseline tools for the server hosts. A minimal NixOS install ships almost
# nothing, and the gap only shows up when you are already inside an SSH session
# trying to work: `git` was missing on the homelab VM, which is exactly the tool
# needed to clone this repository and rebuild locally.
{
  environment.systemPackages = with pkgs; [
    git # clone/pull the flake and rebuild on the host itself
    wget
    rsync
    unzip
    zip
    jq
    ripgrep
    tree
    tmux # long copies and restic runs survive a dropped SSH session
    file
    less
    vim # nano is in the default set; vi is the muscle memory
    btop
    pciutils # lspci
    usbutils # lsusb: identifying a UPS on the Proxmox host starts here
  ];
}
