#!/usr/bin/env python2
from __future__ import print_function
from __future__ import unicode_literals

import urllib2
import xml.etree.ElementTree as ET
import re

base_url = "http://decor.nictiz.nl/apps/public-repo/public/"
ns = {
    'exist': 'http://exist.sourceforge.net/NS/exist',
}

response = urllib2.urlopen(base_url)
xml_str = response.read()

root = ET.fromstring(xml_str)
collection = root.find('exist:collection', ns)
resources = collection.findall('exist:resource', ns)

xars = []

patterns = [
  "ART-([\d.]+).xar",
  "DECOR-core-([\d.]+).xar",
  "DECOR-services-([\d.]+).xar",
  "ART-DECOR-system-services-([\d.]+).xar",
  "terminology-([\d.]+).xar",
]

for r in resources:
    xar_name = r.get('name')
        
    if xar_name.endswith('.xar'):
        matches = [re.search(p, xar_name) for p in patterns]
        if any(matches):
            xars.append(xar_name)
 
for x in xars:
    print(x)
