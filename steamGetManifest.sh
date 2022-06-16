#!/bin/bash

if [ ! -d "$1" ]; then
  echo "please run this command with the path where you copied your games from eg \"./steamGetManifest.sh run/media/deck/external/steamLibrary/steamapps\""
  exit 1;
fi

mkdir -p tmp
find ./common/* -maxdepth 0 -type d | sed 's/.\/common\///g' > tmp/results.txt
#true > tmp/results.txt
if [ ! -s tmp/results.txt ]; then
  echo "no results, are you running this script in \"steamapps\"?"
  exit 1;
fi

find ./common/* -maxdepth 0 -type d | sed 's/.\/common\//^\\s*\\"installdir\\"\\s*\\"/g' | sed 's/$/\\"\$/' > tmp/regex.txt
grep -hof tmp/regex.txt appmanifest_*.acf | sed 's/\s*\"installdir\"\s*\"//g' | sed 's/\"$//g' > tmp/found.txt

echo "The following games are missing Appmanifests:"

grep -vFf tmp/found.txt tmp/results.txt | tee tmp/missing.txt

echo "Open tmp/missing.txt and remove any games you DON'T want to import an Appmanifest. Press ENTER to continue or ctrl+c to exit"
read
echo "lets go!"

sed 's/^/\\"installdir\\"\\s*\\"/g' tmp/missing.txt  | sed 's/$/\\"\$/' > tmp/findreg.txt
grep -lf tmp/findreg.txt $1/appmanifest_*.acf | sed 's/\s*\"installdir\"\s*\"//g' | sed 's/\"$//g' | tee tmp/tocopy.txt

while read -r line; do
  cp "$line" .
done < tmp/tocopy.txt

echo "Done! (feel free to delete \"tmp\")"

exit 0;
