function archiv
    # Pfade
    set -l quelle1 "$HOME/Sync"
    set -l quelle2 "$HOME/Sync/KDB"
    set -l ziel "$HOME/Megabackup"

    # Archivnamen
    set -l archiv1 "$ziel/Sync.7z"
    set -l archiv2 "$ziel/KDB.7z"

    # Zielordner erstellen
    mkdir -p "$ziel"

    # Passwort für Archiv 1 abfragen
    read -s -P "Passwort für Sync.7z: " passwort1
    echo

    echo "Erstelle Sync.7z..."

    7z a -t7z -mhe=on -p"$passwort1" "$archiv1" "$quelle1"

    if test $status -ne 0
        echo "Fehler beim Erstellen von Sync.7z."
        set -e passwort1
        return 1
    end

    # Passwort aus der Variable entfernen
    set -e passwort1

    echo "Sync.7z erfolgreich erstellt."
    echo

    # Passwort für Archiv 2 abfragen
    read -s -P "Passwort für KDB.7z: " passwort2
    echo

    echo "Erstelle KDB.7z..."

    7z a -t7z -mhe=on -p"$passwort2" "$archiv2" "$quelle2"

    if test $status -ne 0
        echo "Fehler beim Erstellen von KDB.7z."
        set -e passwort2
        return 1
    end

    # Passwort aus der Variable entfernen
    set -e passwort2

    echo "KDB.7z erfolgreich erstellt."
    echo
    echo "Beide Archive wurden erfolgreich erstellt:"
    echo "$archiv1"
    echo "$archiv2"
end
