function corvus-update --description 'Laedt das neueste Corvus Arch-Paket von GitHub herunter und installiert es'
    argparse f/force -- $argv
    or return 2

    if not command -q curl
        echo "corvus-update: 'curl' wird benoetigt, ist aber nicht installiert." >&2
        return 1
    end

    set -l repo ada-h00k/Corvus
    set -l pkgname corvus

    set -l tmpdir (mktemp -d)
    if test -z "$tmpdir"
        echo "corvus-update: Konnte kein temporaeres Verzeichnis erstellen." >&2
        return 1
    end

    # 1) Neuesten Release-Tag ermitteln - ueber den Redirect von /releases/latest,
    #    damit das GitHub-API-Rate-Limit nicht zuschlaegt
    echo "==> Ermittle neuesten Release ..."
    set -l redirect (curl -fsSI -o /dev/null -w '%{redirect_url}' "https://github.com/$repo/releases/latest")
    if test -z "$redirect"
        echo "corvus-update: Neuester Release konnte nicht ermittelt werden." >&2
        rm -rf -- "$tmpdir"
        return 1
    end
    set -l tag (string replace -r '.*/tag/' '' -- "$redirect")
    echo "    Release: $tag"

    # 2) Dateinamen des Arch-Pakets (.pkg.tar.zst) aus der Asset-Liste lesen,
    #    da der Name die Versionsnummer enthaelt und nicht statisch angebbar ist
    set -l asset (curl -fsS "https://github.com/$repo/releases/expanded_assets/$tag" \
            | string match -r '[A-Za-z0-9._+-]+\.pkg\.tar\.zst' \
            | head -n1)
    if test -z "$asset"
        echo "corvus-update: Kein .pkg.tar.zst-Paket im Release $tag gefunden." >&2
        rm -rf -- "$tmpdir"
        return 1
    end
    echo "    Paket:   $asset"

    # Version aus dem Dateinamen: corvus-<version>-<arch>.pkg.tar.zst
    set -l pkgver (string replace -r '^corvus-(.+)-[^-]+\.pkg\.tar\.zst$' '$1' -- "$asset")

    # 3) Abbrechen, wenn bereits die neueste Version installiert ist (ausser mit -f)
    set -l installed (pacman -Q $pkgname 2>/dev/null | string match -r '[^ ]+$')
    if not set -q _flag_force; and test -n "$pkgver"; and test "$installed" = "$pkgver"
        echo "==> Corvus ist bereits aktuell ($pkgver). Neuinstallation erzwingen: corvus-update -f"
        rm -rf -- "$tmpdir"
        return 0
    end

    # 4) Paket herunterladen
    echo "==> Lade $asset herunter ..."
    if not curl -fL --progress-bar -o "$tmpdir/$asset" \
            "https://github.com/$repo/releases/download/$tag/$asset"
        echo "corvus-update: Download fehlgeschlagen." >&2
        rm -rf -- "$tmpdir"
        return 1
    end

    # 5) Paket installieren
    echo "==> Installiere ueber pacman ..."
    sudo pacman -U "$tmpdir/$asset"
    set -l pacman_status $status

    rm -rf -- "$tmpdir"

    if test $pacman_status -eq 0
        echo "==> Corvus erfolgreich aktualisiert ($pkgver)."
    else
        echo "corvus-update: Installation fehlgeschlagen (Exit-Code $pacman_status)." >&2
    end
    return $pacman_status
end
