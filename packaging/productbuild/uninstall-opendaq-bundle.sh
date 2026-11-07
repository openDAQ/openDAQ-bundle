#!/bin/sh
# Removes what the openDAQ bundle's macOS package installed, and the package's receipts: macOS has no uninstall
# of its own. Only the bundle's files go, by the receipts, so a core installed beside it stays.
#
#   sudo /opt/opendaq/bin/uninstall-opendaq-bundle.sh

if [ "$(id -u)" -ne 0 ]; then
    echo "run it as root: sudo $0" >&2
    exit 1
fi

ids=$(pkgutil --pkgs='io\.opendaq\.bundle\..*')
if [ -z "$ids" ]; then
    echo "the openDAQ bundle is not installed"
    exit 0
fi

for id in $ids; do
    pkgutil --only-files --files "$id" | while IFS= read -r f; do
        rm -f "/$f"
    done
    pkgutil --forget "$id" >/dev/null
    echo "removed $id"
done

# the directories the files leave empty
find /opt/opendaq -depth -type d -empty -delete 2>/dev/null
exit 0
