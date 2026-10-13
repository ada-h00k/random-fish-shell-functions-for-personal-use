function theme-signal --description "Patcht Signal Desktop mit dem Catppuccin-Theme"
    # Flavor optional als Argument, Standard: frappe
    set -l flavor frappe
    if set -q argv[1]
        set flavor $argv[1]
    end

    set -l signal_dir /usr/lib/signal-desktop/resources
    set -l temp (mktemp -d)

    # Eigentliche Logik in einer Hilfsfunktion, damit am Ende immer
    # aufgeräumt werden kann (Ersatz für `trap cleanup EXIT`)
    function __theme_signal_main --argument-names temp flavor signal_dir
        # Prüfen, ob asar installiert ist
        if not command -sq asar
            echo "Fehler: 'asar' wurde nicht gefunden."
            echo "Bitte installiere es mit: sudo npm install -g asar"
            return 1
        end

        echo "Entpacke Signal app.asar nach $temp..."
        asar e "$signal_dir/app.asar" "$temp"; or return $status

        echo "Lade Catppuccin $flavor Theme herunter..."
        curl -sS "https://raw.githubusercontent.com/ada-h00k/signal-desktop/refs/heads/main/themes/catppuccin-$flavor.css" \
            -o "$temp/stylesheets/catppuccin-$flavor.css"; or return $status

        echo "Füge Import-Anweisung in manifest.css ein..."
        sed -i "1i @import \"catppuccin-$flavor.css\";" "$temp/stylesheets/manifest.css"; or return $status

        echo "Verpacke app.asar neu (Root-Rechte erforderlich)..."
        sudo asar p "$temp" "$signal_dir/app.asar"; or return $status

        echo "Fertig! Signal Desktop wurde erfolgreich mit dem Theme gepatched."
    end

    # Logik ausführen, Exit-Code merken
    __theme_signal_main $temp $flavor $signal_dir
    set -l exit_code $status

    # In jedem Fall aufräumen (wie trap EXIT) und Exit-Code weiterreichen
    echo "Bereinige temporäres Verzeichnis..."
    rm -rf "$temp"
    functions -e __theme_signal_main
    return $exit_code
end
