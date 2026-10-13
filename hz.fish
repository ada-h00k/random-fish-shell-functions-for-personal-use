function hz
    if not set -q __hz_mode
        set -g __hz_mode 100
    end

    if test $__hz_mode -eq 100
        echo "DP-1: 100 Hz -> 60 Hz"
        kscreen-doctor output.DP-1.mode.24
        set -g __hz_mode 60
    else
        echo "DP-1: 60 Hz -> 100 Hz"
        kscreen-doctor output.DP-1.mode.23
        set -g __hz_mode 100
    end
end
