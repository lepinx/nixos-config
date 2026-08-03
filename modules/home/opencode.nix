{ ... }:

{
  xdg.configFile."opencode/tui.json" = {
    force = true;
    text = builtins.toJSON {
      "$schema" = "https://opencode.ai/tui.json";
      theme = "aura";
    };
  };
}
