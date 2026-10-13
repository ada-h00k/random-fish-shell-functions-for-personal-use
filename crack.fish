function crack
    # ============================================================
    # KONFIGURATION
    # ============================================================

    set -l DEFAULT_SOURCE_DIR "/home/user/Programme/Goldberg Emulator"
    set -l TARGET_FILES steam_api64.dll steam_api.dll

    # ============================================================
    # ARGUMENTE
    # ============================================================

    set -l source_dir "$DEFAULT_SOURCE_DIR"
    set -l dry_run false
    set -l revert false

    set -l i 1

    while test $i -le (count $argv)
        switch $argv[$i]

            case -s --source
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    echo "❌ Fehler: --source benötigt einen Pfad." >&2
                    return 1
                end

                set source_dir "$argv[$i]"

            case --source=*
                set source_dir (string replace -- '--source=' '' "$argv[$i]")

            case --dry-run
                set dry_run true

            case --revert
                set revert true

            case -h --help
                echo
                echo "steam DLL Replacer"
                echo
                echo "Verwendung:"
                echo "  crack [OPTIONEN]"
                echo
                echo "Optionen:"
                echo "  -s, --source <PFAD>   Quellordner mit den neuen DLL-Dateien"
                echo "      --dry-run        Nur anzeigen, keine Änderungen vornehmen"
                echo "      --revert         .bak Backups wiederherstellen"
                echo "  -h, --help           Diese Hilfe anzeigen"
                echo
                echo "Standard-Quellordner:"
                echo "  $DEFAULT_SOURCE_DIR"
                echo
                return 0

            case '*'
                echo "❌ Unbekannte Option: $argv[$i]" >&2
                echo "   Nutze 'crack --help' für Hilfe." >&2
                return 1

        end

        set i (math $i + 1)
    end

    # ============================================================
    # BACKUPS WIEDERHERSTELLEN
    # ============================================================

    if $revert

        set -l current_dir (pwd)

        echo
        echo "↩️  Stelle Backups wieder her in: $current_dir"

        if $dry_run
            echo "🧪 DRY-RUN Modus - Es werden keine Änderungen vorgenommen!"
        end

        echo
        echo "─────────────────────────────────────────────────"
        echo

        set -l found 0
        set -l restored 0
        set -l errors 0

        for path in (
            find "$current_dir" -type f \
                \( -iname 'steam_api.dll.bak' -o -iname 'steam_api64.dll.bak' \) \
                -print
        )

            set found (math $found + 1)

            # .dll.bak -> .dll
            set -l original_path (string replace -r '\.bak$' '' -- "$path")

            echo "📦 Backup gefunden: $path"

            if $dry_run
                echo "   → Würde wiederherstellen: $original_path"
                set restored (math $restored + 1)
                echo
                continue
            end

            # Aktuelle Datei löschen, falls vorhanden
            if test -e "$original_path"

                if not rm -f -- "$original_path"
                    echo "   ❌ Fehler beim Löschen der aktuellen Datei" >&2
                    set errors (math $errors + 1)
                    echo
                    continue
                end

            end

            # Backup zurückbenennen
            if mv -- "$path" "$original_path"

                echo "   ✅ Wiederhergestellt: $original_path"
                set restored (math $restored + 1)

            else

                echo "   ❌ Fehler beim Wiederherstellen: $original_path" >&2
                set errors (math $errors + 1)

            end

            echo
        end

        echo "─────────────────────────────────────────────────"
        echo
        echo "📊 Zusammenfassung:"
        echo "   Backups gefunden:   $found"
        echo "   Wiederhergestellt:  $restored"
        echo "   Fehler:             $errors"

        if test $found -eq 0
            echo
            echo "ℹ️  Keine .bak Backups von steam_api(64).dll gefunden."
        end

        return 0
    end

    # ============================================================
    # QUELLORDNER PRÜFEN
    # ============================================================

    if not test -d "$source_dir"

        echo "❌ Fehler: Quellordner existiert nicht: $source_dir" >&2
        echo "   Nutze --source <PFAD> oder passe DEFAULT_SOURCE_DIR an." >&2

        return 1
    end

    echo
    echo "📦 Quellordner: $source_dir"

    # ============================================================
    # QUELLDATEIEN PRÜFEN
    # ============================================================

    set -l available_sources 0

    for file in $TARGET_FILES

        set -l source_file "$source_dir/$file"

        if test -f "$source_file"

            echo "   ✅ $file gefunden"
            set available_sources (math $available_sources + 1)

        else

            echo "   ⚠️  $file im Quellordner nicht gefunden"

        end
    end

    if test $available_sources -eq 0

        echo "❌ Fehler: Keine der Quelldateien im Quellordner gefunden!" >&2
        return 1

    end

    # ============================================================
    # AKTUELLES VERZEICHNIS
    # ============================================================

    set -l current_dir (pwd)

    echo
    echo "🔍 Durchsuche ab: $current_dir"

    if $dry_run
        echo "🧪 DRY-RUN Modus - Es werden keine Änderungen vorgenommen!"
    end

    echo
    echo "─────────────────────────────────────────────────"
    echo

    # ============================================================
    # ZÄHLER
    # ============================================================

    set -l found_count 0
    set -l success_count 0
    set -l error_count 0
    set -l skipped_count 0

    # ============================================================
    # DLLS SUCHEN
    # ============================================================

    for path in (
        find "$current_dir" -type f \
            \( -iname 'steam_api.dll' -o -iname 'steam_api64.dll' \) \
            -print
    )

        set -l file_name (basename -- "$path")
        set -l file_name_lower (string lower -- "$file_name")

        # Sicherheitscheck
        switch "$file_name_lower"

            case steam_api.dll steam_api64.dll
                # Ziel gefunden

            case '*'
                continue

        end

        set found_count (math $found_count + 1)

        echo "📄 Gefunden: $path"

        # ========================================================
        # PASSENDE QUELLDATEI
        # ========================================================

        set -l source_file "$source_dir/$file_name"

        if not test -f "$source_file"

            echo "   ⚠️  Keine passende Quelldatei für $file_name"
            set skipped_count (math $skipped_count + 1)

            echo
            continue
        end

        # ========================================================
        # BACKUPPFAD
        #
        # steam_api.dll
        #       ↓
        # steam_api.dll.bak
        #
        # steam_api64.dll
        #       ↓
        # steam_api64.dll.bak
        # ========================================================

        set -l bak_path "$path.bak"

        # ========================================================
        # DRY RUN
        # ========================================================

        if $dry_run

            echo "   → Würde umbenennen:"
            echo "      $path"
            echo "      ↓"
            echo "      $bak_path"

            echo "   → Würde kopieren:"
            echo "      $source_file"
            echo "      ↓"
            echo "      $path"

            set success_count (math $success_count + 1)

            echo
            continue
        end

        # ========================================================
        # ALTES BACKUP LÖSCHEN
        # ========================================================

        if test -e "$bak_path"

            echo "   ⚠️  Altes Backup vorhanden - wird ersetzt"

            if not rm -f -- "$bak_path"

                echo "   ❌ Fehler beim Entfernen des alten Backups" >&2
                set error_count (math $error_count + 1)

                echo
                continue
            end
        end

        # ========================================================
        # ORIGINAL -> BACKUP
        # ========================================================

        if not mv -- "$path" "$bak_path"

            echo "   ❌ Fehler beim Erstellen des Backups" >&2
            set error_count (math $error_count + 1)

            echo
            continue
        end

        echo "   🔄 Backup erstellt: $bak_path"

        # ========================================================
        # NEUE DLL KOPIEREN
        # ========================================================

        if cp -- "$source_file" "$path"

            echo "   ✅ Ersetzt durch:    $source_file"
            set success_count (math $success_count + 1)

        else

            echo "   ❌ Fehler beim Kopieren: $source_file" >&2

            # ====================================================
            # BACKUP AUTOMATISCH WIEDERHERSTELLEN
            # ====================================================

            echo "   ↩️  Versuche Backup wiederherzustellen..."

            if mv -- "$bak_path" "$path"

                echo "   ✅ Backup wurde wiederhergestellt"

            else

                echo "   🚨 KRITISCH: Backup konnte NICHT zurückgespielt werden!" >&2
                echo "      Backup verbleibt unter: $bak_path" >&2

            end

            set error_count (math $error_count + 1)

        end

        echo
    end

    # ============================================================
    # ZUSAMMENFASSUNG
    # ============================================================

    echo "─────────────────────────────────────────────────"
    echo
    echo "📊 Zusammenfassung:"
    echo "   Gefunden:     $found_count"
    echo "   Erfolgreich:  $success_count"
    echo "   Übersprungen: $skipped_count"
    echo "   Fehler:       $error_count"

    if test $found_count -eq 0

        echo
        echo "ℹ️  Keine steam_api.dll oder steam_api64.dll Dateien gefunden."

    end
end
