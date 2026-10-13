function toggle-cpuid --description 'Switch between kvm/kvm_amd and cpuid_fault_emulation'
    set -l cpuid cpuid_fault_emulation
    set -l kvm kvm
    set -l kvm_amd kvm_amd

    if test (uname) != Linux
        echo "Error: This tool only works on Linux." >&2
        return 1
    end

    # Die Funktion braucht Root. Da sudo fish-Funktionen nicht kennt,
    # definiert sich die Funktion in einer Root-Fish-Shell neu und führt sich dort aus.
    if test (id -u) -ne 0
        set -l tmp (mktemp)
        functions toggle-cpuid >$tmp
        sudo fish --no-config -c "source $tmp; toggle-cpuid"
        set -l code $status
        rm -f $tmp
        return $code
    end

    if not command -q modprobe
        echo "Error: modprobe was not found. Install kmod and make sure modprobe is in PATH." >&2
        return 1
    end

    if test -d /sys/module/$cpuid
        # ---- Zurück zu KVM ----
        echo "Switching from $cpuid back to KVM..."

        modprobe -r $cpuid; or return 1

        if not test -d /sys/module/$kvm
            if not modprobe $kvm
                echo "Failed to load $kvm. Attempting to restore $cpuid..." >&2
                modprobe $cpuid 2>/dev/null
                return 1
            end
        end

        if not test -d /sys/module/$kvm_amd
            if not modprobe $kvm_amd
                echo "Failed to load $kvm_amd. Attempting to restore the previous state..." >&2
                modprobe -r $kvm 2>/dev/null
                modprobe $cpuid 2>/dev/null
                return 1
            end
        end

        if not test -d /sys/module/$kvm; or not test -d /sys/module/$kvm_amd
            echo "Error: $kvm and/or $kvm_amd are not present under /sys/module after loading." >&2
            return 1
        end

        echo "Success: $cpuid has been unloaded; $kvm and $kvm_amd have been loaded."
    else
        # ---- Zu cpuid_fault_emulation ----
        echo "Switching from KVM to $cpuid..."

        if test -d /sys/module/$kvm_amd
            modprobe -r $kvm_amd; or return 1
        end

        if test -d /sys/module/$kvm
            if not modprobe -r $kvm
                echo "Failed to unload $kvm. Attempting to reload $kvm_amd..." >&2
                modprobe $kvm_amd 2>/dev/null
                return 1
            end
        end

        if not test -d /sys/module/$cpuid
            if not modprobe $cpuid
                echo "Failed to load $cpuid. Attempting to restore KVM..." >&2
                modprobe $kvm 2>/dev/null
                modprobe $kvm_amd 2>/dev/null
                return 1
            end
        end

        if not test -d /sys/module/$cpuid
            echo "Error: $cpuid was loaded without a visible error, but it is not present under /sys/module." >&2
            return 1
        end

        echo "Success: $cpuid has been loaded."
    end
end
