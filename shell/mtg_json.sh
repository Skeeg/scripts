#!/bin/bash
# 

while IFS= read -r line
do
  outputfile="$HOME/Downloads/mtg$line.json"
  jq --compact-output ".data.\"$line\" | .name as \$releasename | .cards[] | select(.availability[] | contains (\"paper\")) |
    { set: \"$line\",number: .number,
      name: .name,
      foilavilable: .hasFoil,
      nonfoilavailable: .hasNonFoil,
      availability: .availability,
      mtgjsonv5id: .uuid,
      gathererid: .identifiers.multiverseId,
      setname: \$releasename
    }" < ~/Downloads/AllPrintings.json > "$outputfile"

    inventoryfile="$HOME/Downloads/mtginventory$line.json"
    jq --compact-output '.gathererid as $gid | select (.foilavilable == true) |
    {number: (.number | tonumber), set: .set, name: .name, foil: true, owned: 0, setname: .setname, gathererid: .gathererid, mtgjsonv5id: .mtgjsonv5id}
    ' < <(sed 's/★"/"/g' < "$outputfile") > "$inventoryfile"
    jq --compact-output '.gathererid as $gid | select (.nonfoilavailable == true) |
    {number: (.number | tonumber), set: .set, name: .name, foil: false, owned: 0, setname: .setname, gathererid: .gathererid, mtgjsonv5id: .mtgjsonv5id}
    ' < <(sed 's/★"/"/g' < "$outputfile") >> "$inventoryfile"
    b=$(cat $inventoryfile | sed $'s/}/},/g')

    jq --compact-output '.gathererid as $gid | if $gid == null then . else 
    . +{
      gathererurl: "https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=\($gid)",
      gathererimg: "https://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=\($gid)&type=card"
    }
    end' < <(echo "[" "${b: : -1}" "]" | jq --compact-output 'sort_by(.number) | .[]') > "$inventoryfile"

    jq --compact-output '.' < "$inventoryfile"

done < <(jq --compact-output --raw-output '.data | keys[]' < "$HOME/Downloads/AllPrintings.json")
