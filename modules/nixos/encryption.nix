{ pkgs, ... }:

{
  boot.initrd.luks.devices.cryptroot = {
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  environment.systemPackages = with pkgs; [
    cryptsetup
  ];
}
