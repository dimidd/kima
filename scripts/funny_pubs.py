import json

with open('nli_pubs.json', 'rt') as js:
	records = json.load(js)
for rec in records:
	if 'pub' in rec and rec['pub'] and 'a' in rec['pub']:
		a = rec['pub']['a']
		for c in ['(', ')', '[', ']', '{', '}']:
			if c in a:
				print(rec['id'] +': ' + a)
