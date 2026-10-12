function pi --description="Run Pi outside the home directory (maintenance commands pass through)"
    # Commands that manage global state under ~/.pi/agent never bind a
    # project directory, so they always pass through. Everything else
    # (i.e. starting a session) is guarded below.
    set -l passthrough update install uninstall --version --help -h help
    if set -q argv[1]; and contains -- $argv[1] $passthrough
        command pi $argv
        return
    end

    set -l cwd (pwd -P)

    if test "$cwd" = "$HOME"; and test "$PI_ALLOW_HOME" != 1
        echo "pi: refusing to start a session in \$HOME to avoid creating project files there." >&2
        echo "pi: cd into a project directory, or run 'env PI_ALLOW_HOME=1 pi' to override once." >&2
        return 64
    end

    command pi $argv
end
