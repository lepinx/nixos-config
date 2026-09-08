{ pkgs, userName, ... }:

{
  users.users.${userName}.extraGroups = [
    "kvm"
    "libvirtd"
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    virt-viewer
  ];
}
