jq '. | map(if .secondary_geo_name_451 then . else (., {secondary_geo_name_451: "NA"}) end)'
