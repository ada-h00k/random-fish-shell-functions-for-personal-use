function lampe
    set -l device_id ""
    set -l ip_adresse ""
    set -l local_key ''

    if test (count $argv) -ne 1
        echo "Verwendung:"
        echo "  lampe an"
        echo "  lampe aus"
        echo "  lampe 25%"
        echo "  lampe 50%"
        echo "  lampe 100%"
        return 1
    end

    set -l befehl (string lower -- $argv[1])

    switch $befehl
        case an
            python3 -c "
import tinytuya
d = tinytuya.BulbDevice(
    '$device_id',
    address='$ip_adresse',
    local_key='$local_key',
    version=3.4
)
d.set_status(True, 20)
print('Lampe eingeschaltet.')
"

        case aus
            python3 -c "
import tinytuya
d = tinytuya.BulbDevice(
    '$device_id',
    address='$ip_adresse',
    local_key='$local_key',
    version=3.4
)
d.set_status(False, 20)
print('Lampe ausgeschaltet.')
"

        case '*%'
            set -l prozent (string replace '%' '' $befehl)

            if not string match -rq '^[0-9]+$' -- $prozent
                echo "Ungültige Helligkeit. Beispiel: lampe 50%"
                return 1
            end

            if test $prozent -lt 10 -o $prozent -gt 100
                echo "Die Helligkeit muss zwischen 10 % und 100 % liegen."
                return 1
            end

            set -l wert (math "$prozent * 10")

            python3 -c "
import tinytuya
d = tinytuya.BulbDevice(
    '$device_id',
    address='$ip_adresse',
    local_key='$local_key',
    version=3.4
)
d.set_value(22, $wert)
print('Helligkeit auf $prozent % gesetzt.')
"

        case '*'
            echo "Unbekannter Befehl: $befehl"
            echo
            echo "Mögliche Befehle:"
            echo "  lampe an"
            echo "  lampe aus"
            echo "  lampe 10% bis lampe 100%"
            return 1
    end
end
