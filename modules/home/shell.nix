{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  repoPath,
  ...
}:

let
  colors = config.lib.stylix.colors.withHashtag;
  shellShortcuts = {
    # Editors and helpers
    vim = "nvim";
    zed = "zeditor";
    hd = "herdr";

    # Desktop and file management
    nmc = "nm-connection-editor";
    yd = "yazi-devices";
    yt = "yazi-trash";

    # Git
    g = "git";
    gs = "git status --short --branch";
    ga = "git add";
    gaa = "git add --all";
    gc = "git commit";
    gcm = "git commit -m";
    gp = "git push";
    gpl = "git pull --rebase";
    gf = "git fetch --prune";
    gb = "git branch";
    gsw = "git switch";
    gl = "git log --oneline --graph --decorate";
    gd = "git diff";
    gds = "git diff --staged";
    lg = "lazygit";

    # Nix and this repo workflow
    n = "nix";
    nr = "nix run";
    ns = "nix shell";
    nd = "nix develop";
    nf = "nix flake";
    nfc = "nix flake check";
    nfu = "nix flake update";
    j = "just";
    jc = "just check";
    jb = "just build";
    jt = "just test";
    js = "just switch";
    nj = "nixcfg";
    njc = "nixcfg check";
    njb = "nixcfg build";
    njt = "nixcfg test";
    njs = "nixcfg switch";
    nju = "nixcfg update";

    # Containers: Docker-compatible CLI backed by Podman.
    d = "docker";
    dc = "docker compose";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
    dcl = "docker compose logs -f";
    dps = "docker ps";
    ld = "lazydocker";
  };
  nushellShortcuts = shellShortcuts // {
    fk = "kill -9";
  };
in
{
  home.packages = with pkgs; [
    bat
    btop
    cava
    cmatrix
    curl
    eza
    fastfetch
    fd
    jq
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pinentry-gnome3
    pipes
    procps
    rbw
    ripgrep
    rofi-rbw
    tree
    unzip
    wget
    wl-clipboard
    wofi
    wtype
    zoxide
    pkgsUnstable.fzf
    pkgsUnstable.terminal-rain-lightning
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings
      set fish_greeting

      # Change cursor shapes in different modes
      set -g fish_cursor_default block
      set -g fish_cursor_insert line
      set -g fish_cursor_replace_one underscore
      set -g fish_cursor_visual block

    '';
    shellAliases = {
      cat = "bat";
      ls = "eza --icons";
      ll = "eza -lah --git --icons";
      la = "eza -a --icons";
      lt = "eza --tree --icons";
    };
    shellAbbrs = shellShortcuts;
    functions = {
      mkcd = {
        description = "Create a directory and enter it";
        body = ''
          if test (count $argv) -ne 1
            echo "usage: mkcd <directory>" >&2
            return 2
          end

          mkdir -p -- $argv[1]
          cd -- $argv[1]
        '';
      };

      nixcfg = {
        description = "Run this NixOS config justfile from any directory";
        body = ''
          set -l repo "${repoPath}"

          if not test -f "$repo/justfile"
            echo "nixcfg: $repo/justfile not found" >&2
            return 1
          end

          command just --justfile "$repo/justfile" --working-directory "$repo" $argv
        '';
      };
    };
  };

  programs.nushell = {
    enable = true;
    package = pkgsUnstable.nushell;
    settings = {
      show_banner = false;
      edit_mode = "vi";
      abbreviations = nushellShortcuts;
      completions.external = {
        enable = true;
        max_results = 200;
      };
    };
    shellAliases = {
      kill = "^kill";
      ll = "ls --long --all";
      la = "ls --all";
    };
    extraConfig = ''
      source ${pkgsUnstable.fzf}/share/fzf/completion.nu

      def --env mkcd [directory: path] {
        mkdir $directory
        cd $directory
      }

      def nixcfg [...args: string] {
        let repo = "${repoPath}"

        if not ($repo | path join "justfile" | path exists) {
          print --stderr $"nixcfg: ($repo)/justfile not found"
          return
        }

        just --justfile ($repo | path join "justfile") --working-directory $repo ...$args
      }
    '';
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    forceOverwriteSettings = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      enter_accept = true;
      filter_mode = "global";
      search_mode = "fuzzy";
      style = "compact";
      update_check = false;
    };
  };

  home.file."${config.xdg.configHome}/nushell/config.nu".force = true;

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      aws.symbol = " ";
      buf.symbol = " ";
      bun.symbol = " ";
      c.symbol = " ";
      cmake.symbol = " ";
      conda.symbol = " ";
      cpp.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      deno.symbol = " ";
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fortran.symbol = " ";
      fossil_branch.symbol = " ";
      gcloud.symbol = " ";
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = " ";
      gradle.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      pixi.symbol = "󰏗 ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      status.symbol = " ";
      swift.symbol = " ";
      xmake.symbol = " ";
      zig.symbol = " ";
      os.symbols = {
        Alpine = " ";
        Arch = " ";
        Debian = " ";
        Fedora = " ";
        Linux = " ";
        Macos = " ";
        NixOS = " ";
        Ubuntu = " ";
        Windows = "󰍲 ";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.wofi = {
    enable = true;
    settings = {
      insensitive = true;
      allow_images = true;
      width = "620";
      height = "420";
      prompt = "Bitwarden";
      key_down = "Down,Ctrl-j,Ctrl-n";
      key_up = "Up,Ctrl-k,Ctrl-p";
    };
    style = with colors; ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }

      window {
        margin: 0;
        border: 1px solid ${base03};
        border-radius: 12px;
        background-color: ${base00};
        color: ${base05};
      }

      #outer-box {
        margin: 12px;
        background-color: transparent;
      }

      #input {
        min-height: 42px;
        margin: 0 0 10px 0;
        padding: 0 14px;
        border: 1px solid ${base03};
        border-radius: 8px;
        background-color: ${base01};
        color: ${base05};
      }

      #input:focus {
        border-color: ${base0A};
      }

      #scroll {
        margin: 0;
        border-radius: 8px;
        background-color: transparent;
      }

      #entry {
        min-height: 36px;
        padding: 7px 10px;
        border-radius: 7px;
        background-color: transparent;
      }

      #entry:selected {
        background-color: ${base02};
      }

      #entry:selected #text {
        color: ${base06};
      }

      #text {
        color: ${base05};
      }

      #img {
        margin-right: 10px;
      }
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "zeditor";
        excludesfile = "~/.config/git/ignore";
      };
      fetch.prune = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
      include.path = "~/.gitconfig.local";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = false;
    options = {
      features = "line-numbers decorations";
      syntax-theme = "OneHalfDark";
    };
  };

  xdg.configFile = {
    "herdr/config.toml" = {
      # Adopt the existing file on the first activation. Its contents are
      # declared below, so subsequent rebuilds remain fully reproducible.
      force = true;
      text = ''
        onboarding = false

        [ui]
        agent_panel_scope = "all"

        [ui.toast]
        delivery = "herdr"

        [theme]
        name = "one-dark"

        [terminal]
        default_shell = "${pkgs.fish}/bin/fish"

        [keys]
        # Focus agent rows 1–9 with Ctrl+B, then Ctrl+<number>.
        focus_agent = "prefix+ctrl+1..9"
      '';
    };
    "git/ignore".source = ../../configs/git/ignore;
    "lazygit/config.yml" = {
      force = true;
      text = ''
        git:
          pagers:
            - name: delta
              colorArg: always
              pager: delta --dark --paging=never --features='line-numbers decorations' --syntax-theme='OneHalfDark'
      '';
    };
  };
}
