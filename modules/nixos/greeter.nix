{ pkgs, userName, ... }:

{
  services.displayManager.noctalia-greeter = {
    enable = true;
    greeter-args = "--session umbriel --user ${userName}";
    settings.cursor = {
      theme = "Bibata-Modern-Classic";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };

  security.pam.services.greetd.enableGnomeKeyring = true;
}
