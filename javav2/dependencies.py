#!/usr/bin/env python3.9

# Purpose:
# This standalone script recursively fetches all pom.xml files,
# pulls out their sub-dependencies as XML elements,
# and consolidates them in a "base pom.xml file"

from pathlib import Path
import os
from xml.etree import ElementTree as ET

# get base XML file
base_root = ET.parse('base_pom.xml').getroot()

# get all pom.xml's
posix_file_paths = list(Path(".").rglob("pom.xml"))
file_paths = []
for path in posix_file_paths:
    file_paths.append(str(path))

# extract dependencies and insert into base pom.xml
for filename in file_paths:
    root = ET.parse(filename).getroot()
    for element in root.iter():
        if 'dependencies' in element.tag:
            for item in element:
                keep = True
                for dependency in base_root[7]:
                  if item[1].text == dependency[1].text:
                    keep = False
                  if 'software.amazon.awssdk' in item[1].text or 'software.amazon.awssdk' in item[0].text:
                    keep = False
                if keep:
                    base_root[7].append(item)

tree = ET.ElementTree(base_root)
ET.register_namespace("",'http://maven.apache.org/POM/4.0.0')
tree.write("pom.xml", encoding="utf-8")