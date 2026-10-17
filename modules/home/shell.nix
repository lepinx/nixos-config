{
  config,
  inputs,
  pkgs,
  repoPath,
  ...
}:

let
  shellShortcuts = {
    # Editors and helpers
    vim = "nvim";
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
    curl
    eza
    fastfetch
    fd
    jq
    unimatrix # replaces cmatrix: real Unicode charset, renders without missing-glyph blocks
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    pinentry-gnome3
    pipes
    procps
    ripgrep
    tree
    unzip
    wget
    wl-clipboard
    wtype
    zoxide
    starship
    pkgs.fzf
    pkgs.terminal-rain-lightning
  ];

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        # Noctalia owns ~/.config/starship.toml (palette injection via its
        # starship template); the integration line is added here because
        # programs.starship is no longer used.
        starship init fish | source
        set -gx PATH \
          "/etc/profiles/per-user/$USER/bin" \
          (string match -v -- \
            "/etc/profiles/per-user/$USER/bin" \
            (string match -v -- \
              "$HOME/.local/share/agent-runtime/npm/bin" \
              (string match -v -- "$HOME/.local/bin" $PATH))) \
          "$HOME/.local/share/agent-runtime/npm/bin" \
          "$HOME/.local/bin"
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
        saver = {
          description = "Terminal screensaver: run a random decorative TUI (unimatrix, pipes.sh, clock-rs, terminal-rain)";
          body = ''
            # Binary names differ from package names: pipes -> pipes.sh,
            # terminal-rain-lightning -> terminal-rain. cmatrix was replaced by
            # unimatrix: its random charset includes non-printable bytes that
            # render as gray blocks in ghostty.
            set -l savers unimatrix pipes.sh clock-rs terminal-rain
            set -l pick $savers[(random 1 (count $savers))]
            command $pick
          '';
        };

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

        pi = {
          description = "Run Pi outside the home directory (maintenance commands pass through)";
          body = ''
            # Commands that manage global state under ~/.pi/agent never bind a
            # project directory, so they always pass through. Everything else
            # (i.e. starting a session) is guarded below.
            set -l passthrough update install uninstall --version --help -h help
            if set -q argv[1]; and contains -- $argv[1] $passthrough
              command pi $argv
              return
            end

            set -l cwd (pwd -P)

            if test "$cwd" = "$HOME"; and test "$PI_ALLOW_HOME" != "1"
              echo "pi: refusing to start a session in \$HOME to avoid creating project files there." >&2
              echo "pi: cd into a project directory, or run 'env PI_ALLOW_HOME=1 pi' to override once." >&2
              return 64
            end

            command pi $argv
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

    nushell = {
      enable = true;
      package = pkgs.nushell;
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
        # FZF theme from Noctalia: the user template "fzf_nu" renders the opts
        # file on every wallpaper/theme change; load it when present.
        let fzf_theme = ($nu.home-path | path join ".config" "fzf" "themes" "noctalia.opts")
        if ($fzf_theme | path exists) {
          $env.FZF_DEFAULT_OPTS = (open --raw $fzf_theme | str trim)
        }

        source ${pkgs.fzf}/share/fzf/completion.nu

        def --env mkcd [directory: path] {
          mkdir $directory
          cd $directory
        }

        def pi [...args: string] {
          # Commands that manage global state under ~/.pi/agent never bind a
          # project directory, so they always pass through. Everything else
          # (i.e. starting a session) is guarded below.
          let passthrough = [update install uninstall "--version" "--help" "-h" help]
          if (not ($args | is-empty)) and ($args.0 in $passthrough) {
            ^pi ...$args
            return
          }

          let cwd = (pwd)

          if ($cwd == $env.HOME) and (($env.PI_ALLOW_HOME? | default "") != "1") {
            error make {
              msg: $"pi: refusing to start a session in ($env.HOME) to avoid creating project files there.\ncd into a project directory, or run 'env PI_ALLOW_HOME=1 pi' to override once."
            }
          }

          ^pi ...$args
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

    atuin = {
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

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    git = {
      enable = true;
      settings = {
        core = {
          editor = "nvim";
          excludesfile = "~/.config/git/ignore";
        };
        # Subtle palette-driven styles for terminal git (syntax note in the
        # delta options above):
        # grammar is "[attributes] [fg] [bg]" — a background color requires an
        # explicit foreground, and 'normal' is a special color, not an attribute.
        delta."noctalia-ansi" = {
          minus-style = "normal";
          minus-emph-style = "bold red";
          minus-non-emph-style = "dim";
          plus-style = "normal";
          plus-emph-style = "bold green";
          line-numbers-minus-style = "red";
          line-numbers-plus-style = "green";
          line-numbers-zero-style = "brightblack";
        };
        fetch.prune = true;
        init.defaultBranch = "main";
        pull.rebase = true;
        rebase.autoStash = true;
        push.autoSetupRemote = true;
        include.path = "~/.gitconfig.local";
      };
    };

    delta = {
      enable = true;
      # delta reads its options from git config; without this the options
      # below are written nowhere and delta silently runs on defaults.
      enableGitIntegration = true;
      options = {
        features = "line-numbers decorations noctalia-ansi";
        # delta only knows its bundled syntax themes (no template can inject
        # palette hexes), so "ansi" is used: syntax colors resolve through the
        # terminal's 16-color palette, which ghostty derives from the Noctalia
        # wallpaper palette. Inside lazygit this looked heavy (solid 16-color
        # blocks), so lazygit uses its native renderer and this subtle variant
        # only styles terminal git: dimmed removed lines, changed tokens in
        # bold red/green, no backgrounds. Verified: zero 24-bit escape codes.
        syntax-theme = "ansi";
      };
    };

  };

  home.file."${config.xdg.configHome}/nushell/config.nu".force = true;

  xdg.configFile = {
    "herdr/config.toml" = {
      # Out-of-store symlink: the file is versioned in the repo AND Noctalia's
      # herdr template hook needs to rewrite [theme.custom] on theme changes,
      # which a read-only store symlink cannot do.
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/herdr/config.toml";
    };
    "gh/config.yml".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/gh/config.yml";
    "lazydocker/config.yml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/lazydocker/config.yml";
    # Noctalia's starship template injects its palette block into this file on
    # every theme change (out-of-store so the hook can write through the link).
    "starship.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/starship/starship.toml";
    "git/ignore".source = ../../configs/git/ignore;
    "lazygit/config.yml" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/configs/lazygit/config.yml";
    };
  };
}
