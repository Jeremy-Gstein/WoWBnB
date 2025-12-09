#!/usr/bin/bash

# Move the contents of folder to WoW Addons location for testing

addon_path="/home/jg/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"
addon_name="WoWBnB"
addon="$addon_path/$addon_name"
files="WoWBnBCopy.lua WoWBnB.toc" 

# check if addon dir exists in WoW path.
if [ ! -d "$addon" ]; then
	mkdir -p "$addon"
fi

lazy_sync() {
    echo "Moving $files -> $addon"
    if cp $files "$addon"; then
	    ls -larth "$addon"
	    printf "\n\nDone! /rl to see changes in game." 
	    exit 0;
    else
	    echo "error copying $files to $addon.. check paths are correct"
    fi
}

lazy_rm() {
    read -p "Delete $addon?? [y/N]: " choice
    case "$choice" in
	    y|Y) rm -rf "$addon" ;;
	    *) exit 0 ;;
    esac
}


# Loop through all args and allow combinations 
# of multiple args when passed.
for arg in "$@"; do
  case "$arg" in
    s|-s|sync|--sync) lazy_sync;;
    rm|remove|--rm|--remove) lazy_rm ;;
    *) echo "No arg passed default to sync" ;; 
  esac
done

if [[ $# -eq 0 ]]; then
  lazy_sync
fi
