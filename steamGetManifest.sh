#!/bin/bash

steamapps_dir="/home/deck/.local/share/Steam/steamapps" #TODO assuming you are running on a Steam Deck
tmp_dir="$(dirname $(realpath "$0"))/tmp"
manifest_dir="$(dirname $(realpath "$0"))/appmanifests"
template="$(dirname $(realpath "$0"))/template/appmanifest_TEMPLATE.acf"

#echo "$steamapps_dir/common/"
mkdir -p "$tmp_dir"
mkdir -p "$manifest_dir"
find $steamapps_dir/common/* -maxdepth 0 -type d | sed 's/^.*\/common\///g' > "$tmp_dir/results.txt"

if [ ! -s "$tmp_dir/results.txt" ]; then
  echo "no results, Quitting. Are you running this script in \"steamapps\"?"
  exit 1;
fi

find $steamapps_dir/common/* -maxdepth 0 -type d | sed 's/^.*\/common\//^\\s*\\"installdir\\"\\s*\\"/g' | sed 's/$/\\"\$/' > "$tmp_dir/regex.txt"
grep -hof $tmp_dir/regex.txt $steamapps_dir/appmanifest_*.acf | sed 's/\s*\"installdir\"\s*\"//g' | sed 's/\"$//g' > "$tmp_dir/found.txt"

echo "The following games are missing Appmanifests:"

grep -vFf $tmp_dir/found.txt $tmp_dir/results.txt | tee $tmp_dir/missing.txt

if [ ! -d "$1" ]; then
  echo ""
  echo "Source dir not provided, manually add the AppId to $tmp_dir/missing.txt tab seperated. ENTER to continue manually or ctrl+c to QUIT"
  read

  while read -r line; do
    IFS=$'\t'; column=($line); unset IFS; #0=INSTALLDIR,1=APPID
    echo "${column[1]} --- ${column[0]}"
    sed -e "s/\[APPID\]/${column[1]}/g" -e "s/\[INSTALLDIR\]/${column[0]}/g"  $template > $manifest_dir/appmanifest_${column[1]}.acf
  done < "$tmp_dir/missing.txt"
  
else
  echo "Open $tmp_dir/missing.txt and remove any games you DON'T want to import an Appmanifest. Press ENTER to continue or ctrl+c to exit"
  read

  sed 's/^/\\"installdir\\"\\s*\\"/g' $tmp_dir/missing.txt  | sed 's/$/\\"\$/' > $tmp_dir/findreg.txt
  grep -lf $tmp_dir/findreg.txt $1/appmanifest_*.acf | sed 's/\s*\"installdir\"\s*\"//g' | sed 's/\"$//g' | tee $tmp_dir/tocopy.txt

  while read -r line; do
    #cp "$line" "$steamapps_dir" #this would copy the manifests directly to your steam folder but lets play it safe
    cp "$line" "$manifest_dir"
  done < "$tmp_dir/tocopy.txt"
fi
echo "Done!"

exit 0;
