{ pkgs, userName, ... }:

{
  services.displayManager.noctalia-greeter = {
    enable = true;
    greeter-args = "--session umbriel --user ${userName}";
    settings.cursor = {
      theme = "Adwaita";
      size = 24;
      package = pkgs.adwaita-icon-theme;
    };
  };

  security.pam.services.greetd.enableGnomeKeyring = true;
}
