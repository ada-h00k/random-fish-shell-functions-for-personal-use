function toggle-cpuidboot
    set -l file /etc/default/limine
    
    # Nur die sich unterscheidenden Teilstrings
    set -l variant_a "lockdown=integrity "
    set -l variant_b "clearcpuid=514 "

    # Datei einlesen
    set -l contents (cat $file)
    set -l new_contents
    set -l action_msg

    # Prüfen, welcher Zustand aktuell aktiv ist, und den anderen setzen
    if string match -q -- "*$variant_a*" $contents
        set new_contents (string replace -- $variant_a $variant_b -- $contents)
        set action_msg "lockdown=integrity  ->  clearcpuid=514"
        
    else if string match -q -- "*$variant_b*" $contents
        set new_contents (string replace -- $variant_b $variant_a -- $contents)
        set action_msg "clearcpuid=514  ->  lockdown=integrity"
        
    else
        echo "Fehler: Weder 'lockdown=integrity' noch 'clearcpuid=514' in $file gefunden!"
        return 1
    end

    echo "Wechsle Kernel-Parameter: $action_msg"

    # Geänderte Inhalte zurückschreiben
    printf '%s\n' $new_contents | sudo tee $file > /dev/null

    # Inhalt anzeigen
    echo "Aktuelle KERNEL_CMDLINE in $file:"
    echo "---------------------------------------------------"
    grep "KERNEL_CMDLINE" $file
    echo "---------------------------------------------------"

    # Nachfragen
    read -P 'Sieht das okay aus und limine-mkinitcpio ausführen? (j/n): ' confirm

    if string match -qi 'j' $confirm
        echo "Führe sudo limine-mkinitcpio aus..."
        sudo limine-mkinitcpio
        echo "Erfolgreich gewechselt!"
    else
        echo "Abgebrochen. (Hinweis: Die Datei wurde bereits geändert, du musst sie ggf. manuell zurücksetzen)."
    end
end
