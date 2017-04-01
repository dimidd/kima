#!/usr/bin/env python3
import pymarc, sys
#with open('mssbook.heb.xml', 'rt') as xml:
with open('nli_cat.xml', 'rt') as xml:
    n = 0
    for record in pymarc.parse_xml_to_array(xml, strict=True):
        n += 1
        print(record)
        if n > 100:
            sys.exit(0)
