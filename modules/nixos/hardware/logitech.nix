_:

{
  services.udev.extraRules = ''
    # Logitech USB Receiver 046d:c548 can trigger immediate resume from s2idle.
    # This matches the receiver model, not one physical mouse, so it is safe to
    # reuse on another host with the same device.
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';
}
