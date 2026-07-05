#!/bin/bash
# Pulisce le cartelle lproj con timestamp create dal mount sandbox
# Double-click per eseguire

DIR="/Users/matteo/Desktop/MoneyTracker/MoneyTracker"
cd "$DIR" || exit 1

echo "=== Pulizia cartelle .lproj con timestamp ==="
echo ""

FOUND=0
while IFS= read -r -d '' folder; do
    name=$(basename "$folder")
    echo "Rimozione: $name"
    rm -rf "$folder"
    FOUND=$((FOUND + 1))
done < <(find "$DIR" -maxdepth 1 -type d -name "*.lproj *.lproj" -print0)

if [ "$FOUND" -eq 0 ]; then
    echo "Nessuna cartella con timestamp trovata."
else
    echo ""
    echo "$FOUND cartelle rimosse."
fi

echo ""
echo "Fatto! Ora in Xcode: Product → Clean Build Folder (shift+cmd+K) e poi Build."
echo ""
read -p "Premi Invio per chiudere..."
