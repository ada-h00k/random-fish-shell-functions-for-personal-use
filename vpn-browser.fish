function vpn-browser
    if systemctl --user is-active --quiet gluetun.service; or systemctl --user is-active --quiet mullvad-browser.service
        echo "⏹ Stoppe Gluetun und Mullvad Browser..."
        systemctl --user stop mullvad-browser.service gluetun.service
        echo "✓ VPN-Browser-Dienste gestoppt"
    else
        echo "▶ Starte Gluetun..."
        systemctl --user start gluetun.service

        if not systemctl --user is-active --quiet gluetun.service
            echo "✗ Gluetun konnte nicht gestartet werden."
            return 1
        end

        echo "▶ Starte Mullvad Browser..."
        systemctl --user start mullvad-browser.service

        if not systemctl --user is-active --quiet mullvad-browser.service
            echo "✗ Mullvad Browser konnte nicht gestartet werden."
            systemctl --user stop gluetun.service
            return 1
        end

        echo "✓ Gluetun und Mullvad Browser laufen"
        echo "🌐 Öffne Mullvad Browser..."

        xdg-open https://localhost:3001 >/dev/null 2>&1 &
    end
end
