function steamstarter
    set -l steam_root "$HOME/.local/share/Steam"
    set -l login_users "$steam_root/config/loginusers.vdf"
    set -l registry "$HOME/.steam/registry.vdf"

    if not test -f "$login_users"
        echo "steamstarter: $login_users nicht gefunden." >&2
        return 1
    end

    if not test -f "$registry"
        echo "steamstarter: $registry nicht gefunden." >&2
        return 1
    end

    # ─────────────────────────────────────────────
    # Hilfe
    # ─────────────────────────────────────────────

    if test (count $argv) -eq 0
        echo "Usage:"
        echo "  steamstarter <account>"
        echo "  steamstarter --list"
        echo "  steamstarter --help"
        return 1
    end

    switch $argv[1]
        case --help -h
            echo "Usage:"
            echo "  steamstarter <account>"
            echo "  steamstarter --list"
            echo
            echo "Beispiel:"
            echo "  steamstarter account1"
            return 0

        case --list -l
            echo "Gespeicherte Steam-Accounts:"
            grep -E '"AccountName"' "$login_users" \
                | sed -E 's/.*"AccountName"[[:space:]]*"([^"]+)".*/\1/'
            return 0
    end

    set -l account $argv[1]

    # ─────────────────────────────────────────────
    # Prüfen, ob Account existiert
    # ─────────────────────────────────────────────

    set -l accounts (
        grep -E '"AccountName"' "$login_users" \
        | sed -E 's/.*"AccountName"[[:space:]]*"([^"]+)".*/\1/'
    )

    if not contains -- "$account" $accounts
        echo "steamstarter: Account '$account' wurde nicht gefunden." >&2
        echo
        echo "Verfügbare Accounts:"
        printf '  %s\n' $accounts
        return 1
    end

    # ─────────────────────────────────────────────
    # Steam beenden
    # ─────────────────────────────────────────────

    if pgrep -x steam >/dev/null 2>&1
        echo "Steam wird beendet..."

        steam -shutdown >/dev/null 2>&1

        for i in (seq 1 30)
            if not pgrep -x steam >/dev/null 2>&1
                break
            end

            sleep 0.5
        end

        if pgrep -x steam >/dev/null 2>&1
            echo "steamstarter: Steam konnte nicht beendet werden." >&2
            return 1
        end
    end

    # ─────────────────────────────────────────────
    # Backups
    # ─────────────────────────────────────────────

    cp -a "$login_users" "$login_users.bak"
    cp -a "$registry" "$registry.bak"

    # ─────────────────────────────────────────────
    # loginusers.vdf bearbeiten
    # ─────────────────────────────────────────────

    set -l tmp_login (mktemp)

    awk -v target="$account" '
        BEGIN {
            in_account = 0
            is_target = 0
        }

        /"AccountName"/ {
            account = $0
            sub(/^.*"AccountName"[[:space:]]+"/, "", account)
            sub(/".*$/, "", account)

            in_account = 1
            is_target = (account == target)
        }

        /"MostRecent"/ && in_account {
            if (is_target)
                sub(/"MostRecent"[[:space:]]+"[01]"/,
                    "\"MostRecent\" \"1\"")
            else
                sub(/"MostRecent"[[:space:]]+"[01]"/,
                    "\"MostRecent\" \"0\"")
        }

        /"AllowAutoLogin"/ && in_account {
            if (is_target)
                sub(/"AllowAutoLogin"[[:space:]]+"[01]"/,
                    "\"AllowAutoLogin\" \"1\"")
            else
                sub(/"AllowAutoLogin"[[:space:]]+"[01]"/,
                    "\"AllowAutoLogin\" \"0\"")
        }

        { print }
    ' "$login_users" > "$tmp_login"

    mv "$tmp_login" "$login_users"

    # ─────────────────────────────────────────────
    # registry.vdf bearbeiten
    # ─────────────────────────────────────────────

    set -l tmp_registry (mktemp)

    awk -v target="$account" '
        /"AutoLoginUser"/ {
            sub(/"AutoLoginUser"[[:space:]]+"[^"]*"/,
                "\"AutoLoginUser\" \"" target "\"")
        }

        { print }
    ' "$registry" > "$tmp_registry"

    mv "$tmp_registry" "$registry"

    # ─────────────────────────────────────────────
    # Steam starten
    # ─────────────────────────────────────────────

    echo "Starte Steam mit Account: $account"

    setsid "$HOME/.local/share/Steam/steam.sh" >/dev/null 2>&1 < /dev/null &

    echo "Steam wurde gestartet."
end
