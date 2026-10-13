function wetter -d "Zeigt aktuelles Wetter und UV-Index für Stadt-Stadtteil"
    set -l WEATHER_URL "https://www.wetter.com/deutschland/stadt/stadtteil/ort.html"
    set -l UV_URL "https://www.wetter.com/uv-index/deutschland/stadt/stadtteil/ort/"

    set -l debug 0

    argparse 'd/debug' 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        echo "Verwendung: wetter [-d|--debug]"
        return 0
    end

    if set -q _flag_debug
        set debug 1
    end

    set -l tmpdir (mktemp -d)
    or begin
        echo "Fehler: Temporäres Verzeichnis konnte nicht erstellt werden." >&2
        return 1
    end

    set -l weather_file "$tmpdir/weather.html"
    set -l uv_file "$tmpdir/uv.html"
    set -l cookies "$tmpdir/cookies.txt"

    function __wetter_cleanup --no-scope-shadowing
        rm -rf "$tmpdir"
        functions -e __wetter_cleanup
    end

    echo "Lade Wetterdaten für Stadt-Stadtteil ..."

    # ---------------------------------------------------------------
    # Wetterseite
    # ---------------------------------------------------------------

    curl \
        --silent \
        --show-error \
        --fail \
        --location \
        --compressed \
        --max-time 30 \
        --cookie-jar "$cookies" \
        --cookie "$cookies" \
        --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
        --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        --header "Accept-Language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7" \
        "$WEATHER_URL" > "$weather_file" &

    set -l weather_pid $last_pid

    # ---------------------------------------------------------------
    # UV-Seite
    # ---------------------------------------------------------------

    curl \
        --silent \
        --show-error \
        --fail \
        --location \
        --compressed \
        --max-time 30 \
        --cookie-jar "$cookies" \
        --cookie "$cookies" \
        --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" \
        --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        --header "Accept-Language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7" \
        "$UV_URL" > "$uv_file" &

    set -l uv_pid $last_pid

    wait $weather_pid
    set -l weather_status $status

    wait $uv_pid
    set -l uv_status $status

    if test $weather_status -ne 0
        echo "Fehler: Wetterseite konnte nicht geladen werden." >&2
        __wetter_cleanup
        return 1
    end

    if test $uv_status -ne 0
        echo "Fehler: UV-Index-Seite konnte nicht geladen werden." >&2
        __wetter_cleanup
        return 1
    end

    # ===============================================================
    # TEMPERATUR
    # ===============================================================
    #
    # Aktuelle wetter.com-Struktur:
    #
    # <div class="delta rtw_temp">18°C</div>
    #
    # Wir suchen ausschließlich diese Klasse.
    #

    set -l temperature (
        grep -oE 'class="[^"]*rtw_temp[^"]*"[^>]*>[[:space:]]*-?[0-9]{1,3}[[:space:]]*°C' \
            "$weather_file" |
        head -n 1 |
        grep -oE -- '-?[0-9]{1,3}[[:space:]]*°C' |
        grep -oE -- '-?[0-9]{1,3}'
    )

    if test -z "$temperature"
        if test $debug -eq 1
            cp "$weather_file" debug_weather.html
            echo "Warnung: rtw_temp nicht gefunden." >&2
            echo "HTML gespeichert: debug_weather.html" >&2
        end

        echo "Fehler: Aktuelle Temperatur konnte nicht extrahiert werden." >&2
        __wetter_cleanup
        return 1
    end

    # ===============================================================
    # UV-INDEX
    # ===============================================================
    #
    # title="Jetzt" und level-N.svg stehen auf unterschiedlichen
    # Zeilen. Deshalb betrachten wir das HTML als einen String.
    #
    # Wir suchen:
    #
    #   title="Jetzt" ... level-3.svg
    #
    # bzw. umgekehrt:
    #
    #   level-3.svg ... title="Jetzt"
    #
    # und nehmen nur einen kleinen Bereich um "Jetzt".
    #

    set -l uv_index

    # HTML in eine einzige Zeile bringen
    set -l uv_html (
        tr '\n' ' ' < "$uv_file"
    )

    # Bereich um title="Jetzt" extrahieren.
    #
    # 500 Zeichen reichen für das img-Element, ohne dass wir
    # irgendwelche späteren UV-Werte erwischen.
    set -l now_block (
        string match -r -i -- '.{0,500}title="Jetzt".{0,500}' "$uv_html"
    )

    if test -n "$now_block"
        set uv_index (
            string match -r -- 'level-[0-9]{1,2}\.svg' "$now_block" |
            head -n 1 |
            string match -r -- '[0-9]{1,2}'
        )
    end

    # Falls title="Jetzt" vor dem src steht und der erste Regex
    # nicht greift, nochmals in umgekehrter Richtung suchen.
    if test -z "$uv_index"
        set -l now_block (
            string match -r -i -- '.{0,500}level-[0-9]{1,2}\.svg.{0,500}title="Jetzt"' "$uv_html"
        )

        if test -n "$now_block"
            set uv_index (
                string match -r -- 'level-[0-9]{1,2}\.svg' "$now_block" |
                head -n 1 |
                string match -r -- '[0-9]{1,2}'
            )
        end
    end

    if test -z "$uv_index"
        if test $debug -eq 1
            cp "$uv_file" debug_uv.html
            echo "Warnung: UV-Index für 'Jetzt' nicht gefunden." >&2
            echo "HTML gespeichert: debug_uv.html" >&2
        end

        echo "Fehler: Aktueller UV-Index konnte nicht extrahiert werden." >&2
        __wetter_cleanup
        return 1
    end

    # ===============================================================
    # UV-BESCHREIBUNG
    # ===============================================================

    set -l description

    if test "$uv_index" -le 2
        set description "Niedrig - kein Schutz erforderlich"
    else if test "$uv_index" -le 5
        set description "Mäßig - Sonnenschutz empfohlen"
    else if test "$uv_index" -le 7
        set description "Hoch - Schutz notwendig"
    else if test "$uv_index" -le 10
        set description "Sehr hoch - Aufenthalt im Freien einschränken"
    else if test "$uv_index" -le 15
        set description "Extrem - direkte Sonne meiden"
    else
        set description "Unbekannt"
    end

    # ===============================================================
    # AUSGABE
    # ===============================================================

    echo
    echo "╔══════════════════════════════════════════════╗"
    echo "║  Wetter für Stadt-Stadtteil                 ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║                                              ║"
    printf "║  Aktuelle Temperatur : %-22s║\n" "$temperature°"
    printf "║  UV-Index            : %-22s║\n" "$uv_index"
    echo "║  Bewertung           :                      ║"
    printf "║    %-46s║\n" "$description"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"

    __wetter_cleanup
end
