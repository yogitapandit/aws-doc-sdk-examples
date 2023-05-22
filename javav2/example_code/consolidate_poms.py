import os
import xml.etree.ElementTree as ET


def parse_dependency(element):
    breakpoint()
    dependency = {}
    fields = ['groupId', 'artifactId', 'version', 'scope', 'type']
    for field in fields:
        tag_element = element.find(field)
        if tag_element is not None:
            dependency[field] = tag_element.text
        else:
            dependency[field] = None
    return dependency


def parse_pom_xml(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()

    pom = {}

    for child in root:
        breakpoint()
        if 'dependencies' in child.tag:
            dependencies = []
            breakpoint()
            for dependency_element in child.findall('dependency'):
                dependency = parse_dependency(dependency_element)
                dependencies.append(dependency)
            pom[child.tag] = dependencies
        else:
            pom[child.tag] = child.text

    breakpoint()
    return pom


def search_pom_files(directory):
    pom_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file == 'pom.xml':
                pom_files.append(os.path.join(root, file))
    return pom_files


current_directory = '.'  # Set the current directory here
pom_files = search_pom_files(current_directory)

for pom_file in pom_files:
    pom_data = parse_pom_xml(pom_file)

    breakpoint()
    # Access the properties
    group_id = pom_data['groupId']
    artifact_id = pom_data['artifactId']
    version = pom_data['version']

    # Access the dependencies
    dependencies = pom_data['dependencies']
    for dependency in dependencies:
        group_id = dependency['groupId']
        artifact_id = dependency['artifactId']
        version = dependency['version']
        # Process each dependency as needed

    # Example: Print the parsed data for each pom.xml file
    print(f"POM File: {pom_file}")
    print(pom_data)
    print('-' * 20)