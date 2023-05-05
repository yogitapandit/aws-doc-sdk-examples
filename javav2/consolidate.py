import os
import xml.etree.ElementTree as ET

def consolidate_pom_files(dir_path):
    # Find all pom.xml files in the directory and its subdirectories
    pom_files = []
    for root, dirs, files in os.walk(dir_path):
        for file in files:
            if file.endswith('.xml') and file.startswith('pom'):
                pom_files.append(os.path.join(root, file))

    if not pom_files:
        print('No pom.xml files found in the directory')
        return

    # Create an ElementTree to hold the combined XML
    combined_tree = ET.ElementTree(ET.fromstring('<project xmlns="">'+'</project>'))

    # Iterate over each pom.xml file and add its sub-elements to the combined ElementTree
    for pom_file in pom_files:
        tree = ET.parse(pom_file)
        root = tree.getroot()

        for child in root:
            if child.tag not in ['dependencies', 'repositories']:
                # Add top-level elements to the combined tree
                combined_tree.getroot().append(child)
            else:
                # Merge dependencies and repositories
                existing = combined_tree.find(child.tag)
                if existing is None:
                    # Add new element if it doesn't exist
                    combined_tree.getroot().append(child)
                else:
                    # Merge existing element with new element
                    for dep in child.findall('*'):
                        if dep not in existing.findall(dep.tag):
                            existing.append(dep)

    # Write the combined ElementTree to a new file
    combined_tree.write(os.path.join(dir_path, 'consolidated_pom.xml'), encoding='UTF-8', xml_declaration=True)

    print('Consolidated pom.xml file created successfully')

# Example usage
consolidate_pom_files('.')
