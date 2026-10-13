function podman --wraps='podman' --description 'Podman wrapper with enter command'
    if test "$argv[1]" = "enter"; and test -n "$argv[2]"
        set -l container $argv[2]

        if not command podman inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q "true"
            echo "Container '$container' is not running. Starting it..."
            command podman start $container
        end

        command podman exec -it $container /bin/bash 2>/dev/null
        or command podman exec -it $container /bin/sh
    else
        command podman $argv
    end
end
