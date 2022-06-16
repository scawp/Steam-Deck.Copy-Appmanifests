#!/bin/bash

steamapps_dir="/home/deck/.local/share/Steam/steamapps" #TODO assuming you are running on a Steam Deck
tmp_dir="$(dirname $(realpath "$0"))/tmp"
template="$(dirname $(realpath "$0"))/template/appmanifest_TEMPLATE.acf"

echo "$steamapps_dir/common/"
mkdir -p "$tmp_dir"
find $steamapps_dir/common/* -maxdepth 0 -type d | sed 's/^.*\/common\///g' > "$tmp_dir/results.txt"

if [ ! -s "$tmp_dir/results.txt" ]; then
  echo "no results, Quitting. Are you running this script in \"steamapps\"?"
  exit 1;
fi

find $steamapps_dir/common/* -maxdepth 0 -type d | sed 's/^.*\/common\//^\\s*\\"installdir\\"\\s*\\"/g' | sed 's/$/\\"\$/' > "$tmp_dir/regex.txt"
grep -hof $tmp_dir/regex.txt $steamapps_dir/appmanifest_*.acf | sed 's/\s*\"installdir\"\s*\"//g' | sed 's/\"$//g' > "$tmp_dir/found.txt"

echo "The following games are missing Appmanifests:"

grep -vFf $tmp_dir/found.txt $tmp_dir/results.txt | tee $tmp_dir/missing.txt

echo "Open $tmp_dir/missing.txt and remove any games you DON'T want to import an Appmanifest. Press ENTER to continue or ctrl+c to exit"
read
echo "lets go!"

if [ ! -d "$1" ]; then
  echo "Source dir not provided, manually add the AppId to missing tab seperated. ENTER to continue manually or ctrl+c to QUIT"

  while read -r line; do
    IFS=$'\t'; column=($line); unset IFS; #0=INSTALLDIR,1=APPID
    echo "${column[1]} --- ${column[0]}"
    sed -e "s/\[APPID\]/${column[1]}/g" -e "s/\[INSTALLDIR\]/${column[0]}/g"  $template > $tmp_dir/appmanifest_${column[1]}.acf
    #sed "s/\[INSTALLDIR\]/${column[0]}/g" $tmp_dir/appmanifest_${column[1]}.acf > $tmp_dir/a3ppmanifest_${column[1]}.acf
  done < "$tmp_dir/missing.txt"
  
else
  sed 's/^/\\"installdir\\"\\s*\\"/g' $tmp_dir/missing.txt  | sed 's/$/\\"\$/' > $tmp_dir/findreg.txt
  grep -lf $tmp_dir/findreg.txt $1/appmanifest_*.acf | sed 's/\s*\"installdir\"\s*\"//g' | sed 's/\"$//g' | tee $tmp_dir/tocopy.txt

  while read -r line; do
    cp "$line" "$steamapps_dir"
  done < "$tmp_dir/tocopy.txt"
fi
echo "Done!"

exit 0;
