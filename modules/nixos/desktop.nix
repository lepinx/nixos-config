{
  pkgs,
  ...
}:

{
  security.rtkit.enable = true;

  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
  };

  # powertop --auto-tune at boot and resume (USB autosuspend, BT/PCIe/SATA/HDA
  # power saving). Remove it if a peripheral wakes too slowly.
  powerManagement.powertop.enable = true;

  # Workaround for NixOS/nixpkgs#577729: kernel 6.18.57 builds ACPI_TINY_POWER_BUTTON
  # as a module alongside ACPI_BUTTON, and on s2idle wake it treats the firmware's
  # power-button ACPI notify as a real press, sending SIGRTMIN+4 to PID 1 which
  # powers the machine off mid-resume. The real power key keeps working via logind
  # and the `button` driver. Remove once nixpkgs sets ACPI_TINY_POWER_BUTTON = no
  # in common-config.nix (or ships the upstream kernel fix ab06eb920401).
  boot.blacklistedKernelModules = [ "tiny_power_button" ];

  systemd.services.power-profile-auto = {
    description = "Set the power profile according to AC power";
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    wantedBy = [ "power-profiles-daemon.service" ];

    serviceConfig.Type = "oneshot";
    script = ''
      profile=balanced

      for supply in /sys/class/power_supply/*; do
        if [ -r "$supply/type" ] && [ "$(cat "$supply/type")" = "Mains" ]; then
          if [ -r "$supply/online" ] && [ "$(cat "$supply/online")" = "1" ]; then
            profile=performance
          fi
        fi
      done

      ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$profile"
    '';
  };

  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-auto.service"
  '';

  programs.umbriel.enable = true;

  xdg.portal.enable = true;
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.Policy.AutoEnable = true;
  };

  systemd.services.bluetooth.preStart = ''
    ${pkgs.util-linux}/bin/rfkill unblock bluetooth
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig."10-bluez-a2dp" = {
        "monitor.bluez.properties" = {
          "bluez5.roles" = [
            "a2dp_sink"
            "a2dp_source"
          ];
          "bluez5.codecs" = [
            "sbc"
            "sbc_xq"
            "aac"
            "ldac"
            "aptx"
            "aptx_hd"
          ];
          "bluez5.enable-sbc-xq" = true;
        };
      };
    };
  };
  services.pulseaudio.enable = false;

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    libnotify
    powertop
    wl-clipboard
  ];
}
