#!/bin/bash
while IFS= read -r line
do
  string=$(echo $line | awk 'BEGIN { FS = "=" } ;{print $1, $2}'); echo "git config --global $string"
done < <(git config --list --global)

while IFS= read -r line
do
  string=$(echo $line | awk 'BEGIN { FS = "=" } ;{print $1, $2}'); echo "git config --local $string"
done < <(git config --list --local)

while IFS= read -r line
do
  string=$(echo $line | awk 'BEGIN { FS = "=" } ;{print $1, $2}'); echo "git config --system $string"
done < <(git config --list --system)
