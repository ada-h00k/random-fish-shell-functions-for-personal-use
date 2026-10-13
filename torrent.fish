function torrent
    if systemctl --user is-active --quiet gluetun.service; or systemctl --user is-active --quiet qbittorrent.service
        echo "⏹ Stoppe Gluetun und qBittorrent..."
        systemctl --user stop qbittorrent.service gluetun.service
        echo "✓ Torrent-Dienste gestoppt"
    else
        echo "▶ Starte Gluetun..."
        systemctl --user start gluetun.service

        if not systemctl --user is-active --quiet gluetun.service
            echo "✗ Gluetun konnte nicht gestartet werden."
            return 1
        end

        echo "▶ Starte qBittorrent..."
        systemctl --user start qbittorrent.service

        if not systemctl --user is-active --quiet qbittorrent.service
            echo "✗ qBittorrent konnte nicht gestartet werden."
            return 1
        end

        echo "✓ Gluetun und qBittorrent laufen"
        echo "🌐 Öffne qBittorrent..."

        xdg-open http://localhost:8080 >/dev/null 2>&1 &
    end
end
