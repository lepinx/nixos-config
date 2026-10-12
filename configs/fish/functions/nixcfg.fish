function nixcfg --description="Run this NixOS config justfile from any directory"
    set -l repo /home/lucho/nixos-config

    if not test -f "$repo/justfile"
        echo "nixcfg: $repo/justfile not found" >&2
        return 1
    end

    command just --justfile "$repo/justfile" --working-directory "$repo" $argv
end
