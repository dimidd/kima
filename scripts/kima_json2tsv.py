import json
import sys

types = {'primary_geo_name_151': 'pri', 'secondary_geo_name_451': 'sec'}
with open(sys.argv[1], 'rt') as f:
    recs = json.load(f)
SEP = '\t'
print(SEP.join(["id", "val", "lang", "type"]))
for r in recs:
    for t in types:
        if t in r and r[t] != "NA":
            for e in r[t]:
                print(SEP.join([r['id_001'][0], e['a'], e['9'], types[t]]))
