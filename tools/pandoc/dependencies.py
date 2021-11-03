#!/usr/bin/env python3

import argparse
import os.path as path
import re


def parseArgs():
    parser = argparse.ArgumentParser(description='Markdown snippets dependency finder')

    parser.add_argument('-d', dest='dependent', required=False, action='store', metavar='dependent',
                        help='Real file we should put as the dependent. Equals to the INPUT file by default.')
    parser.add_argument('-i', dest='input', required=True, action='store', metavar='INPUT',
                        help='Input markdown to look for dependencies.')
    parser.add_argument('-o', dest='output', required=True, action='store', metavar='OUTPUT',
                        help='Output dependency file.')

    return parser.parse_args()


def find(text):
    # search_re = re.compile(r"```{[^ ]+ include=([^ ]+) [^}]+}")
    search_re = re.compile(r"```{\s*[^ ]+\s+include=([^ ]+)\s+[^}]+}")  # More flexible with whitespace.
    return search_re.findall(text)


def write(file, dependent, dependencies):
    file.write(dependent)
    file.write(": ")
    for x in dependencies:
        file.write(x)
        file.write(" ")
    file.write("\n")


def main(args):
    path_input = path.normpath(args.input)
    path_output = path.normpath(args.output)
    path_dependent = path.normpath(args.dependent) if args.dependent else path_input

    with open(path_input) as f_input:
        dependencies = find(f_input.read())

    input_folder = path.dirname(path_input)
    dependencies = {path.normpath(path.join(input_folder, x)) for x in dependencies}

    if dependencies:
        print(f"Found dependencies for {path_dependent}:")
        for x in dependencies:
            print(f"    {x}")

    with open(path_output, "w") as f_output:
        write(f_output, path_dependent, dependencies)


if __name__ == "__main__":
    main(parseArgs())
