#!/usr/bin/env python3

import argparse
import re
import subprocess

# Argument parser.
def parseArgs():
    parser = argparse.ArgumentParser(description='Markdown preprocessor')

    # Mandatory options.
    parser.add_argument(dest='input', metavar='INPUT',
                        help='Unpreprocessed source file.')
    parser.add_argument('-c', dest='compiler', required=True, metavar='COMPILER',
                        help='Compiler to use for C++ preprocessing.')

    # C partial preprocessing.
    parser.add_argument('-P', dest='preprocess', action='store_true',
                        help='Run the C preprocessor unconditionally.')
    parser.add_argument('-p', dest='preprocessFiles', action='append', default=[],
                        help='Run the C preprocessor for the files listed.')
    parser.add_argument('-I', dest='includePath', action='append', metavar='INCLUDE_DIR', default=[],
                        help='Include directory.')
    parser.add_argument('-i', dest='includes', action='append', metavar='INCLUDE', default=[],
                        help='Include directives to keep.')

    # Parse :)
    return parser.parse_args()

# Function to remove all includes except those listed.
def removeIncludes(input, includesToKeep):
    out = ''
    includeRe = re.compile('^#include [<"]?([^>"]*)[>"]?')
    for line in input.split('\n'):
        if (match := includeRe.match(line)) is not None:
            if match[1] in includesToKeep:
                out += line + '\n'
            else:
                out += '\n'
        else:
            out += line + '\n'
    return out

# Function to run the C preprocessor.
def runPreprocessor(input, compiler, includePath):
    preprocessed = subprocess.run([compiler, '-', '-E', '-CC', '-Werror', '-Wno-pragma-once-outside-header'] +
                                  [f'-I{i}' for i in includePath],
                                  check=True, encoding='utf-8', input=input, stdout=subprocess.PIPE).stdout


    return preprocessed

# Function to line up the output with the line numbers inserted by the preprocessor. This also filters out the contents
# of the included files.
def filterPreprocessedOutput(input, lineCount):
    lineRe = re.compile('^# ([0-9]+) "([^"]*)"')

    # Output state.
    out = ''
    lineNumber = 1
    enabled = True

    # Process one line at a time :)
    for line in input.split('\n'):
        if (match := lineRe.match(line)):
            enabled = match[2] == '<stdin>' # This is the input we want.
            if enabled:
                # Get the output to match the line number given.
                newlines = int(match[1]) - lineNumber
                out += '\n' * newlines
                lineNumber += newlines
        elif enabled:
            # Only include <stdin> lines.
            out += line + '\n'
            lineNumber += 1

    # Doxygen says it likes the number of lines to remain unchanged.
    return out + '\n' * (lineCount - lineNumber)

# Main script :)
args = parseArgs()
with open(args.input) as f:
    source = f.read()
if args.preprocess or args.input in args.preprocessFiles:
    includeFiltered = removeIncludes(source, args.includes)
    preprocessed = runPreprocessor(includeFiltered, args.compiler, args.includePath)
    source = filterPreprocessedOutput(preprocessed, source.count('\n') + 1)
print(source)

