#!/usr/bin/bash

# Move the contents of folder to WoW Addons location for testing

addon_path="/home/jg/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"
addon_name="WoWDB"
addon="$addon_path/$addon_name"
files="Core.lua WoWBnB.toc Options.lua"

if [ ! -d "$addon" ]; then
	mkdir -p "$addon"
fi

echo "Moving $files -> $addon"
if cp $files "$addon"; then
	ls -larth "$addon"
	printf "\n\nDone! /rl to see changes in game." 
	exit 0;
else
	echo "error copying files to addon folder.. check paths are correct"
fi

