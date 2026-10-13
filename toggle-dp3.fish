function toggle-dp3
    set dp3_status (kscreen-doctor -o | awk '
        /DP-3/ { found=1; next }
        found && /enabled/ { print "enabled"; exit }
        found && /disabled/ { print "disabled"; exit }
    ')

    if test "$dp3_status" = "enabled"
        kscreen-doctor output.DP-3.disable
    else if test "$dp3_status" = "disabled"
        kscreen-doctor output.DP-3.enable
    else
        echo "Konnte Status von DP-3 nicht ermitteln: $dp3_status"
    end
end
