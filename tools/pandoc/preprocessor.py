#!/usr/bin/env python3

import argparse
import re

def parseArgs():
    parser = argparse.ArgumentParser(description='Markdown preprocessor',
                                     formatter_class=argparse.RawDescriptionHelpFormatter,
                                     epilog='''
This program preprocesses a Markdown file. It performs the following operations:
 - Directive processing

Directive processing:
  Each directives has one of the following forms:
    - `[](X)` means "if X is in the flag set".
    - `[](!X)` means "if X is not in the flag set".
    - `[]()` means "end if".
  A directive must exist on a line on its own to be recognised.''')

    parser.add_argument('-i', dest='input', required=True, action='store', metavar='INPUT',
                        help='Unpreprocessed input markdown.')
    parser.add_argument('-o', dest='output', required=True, action='store', metavar='OUTPUT',
                        help='Preprocessed output markdown.')
    parser.add_argument('-f', dest='flags', action='append', metavar='FLAG', default=[],
                        help='Define that the named flag is set.')

    return parser.parse_args()

def processDirectives(input, flags):
    # Compile the regexes we're using.
    startRegex = re.compile(r'^\[]\((!?)([^ ]+)\)$')
    endRegex = re.compile(r'^\[]\(\)$')

    # Parse the input line-by-line.
    out = ''
    stack = [(0, True)] # Tuple of (line number, show contents)
    for n,line in enumerate(input.split('\n'), 1):
        line = line.rstrip('\r\n')
        startMatch = startRegex.match(line)
        endMatch = endRegex.match(line)

        if startMatch:
            # We're entering another block. The condition we append says "show the contents", i.e: "Are we already showing
            # the contents, and if so: is the flag in the flag set (or not if the condition is negated)?".
            stack.append((n, stack[-1][1] and (startMatch.group(2) in flags) == (startMatch.group(1) == '')))
        elif endMatch:
            # Close the most recent conditional block.
            stack = stack[:-1]

            # We should always have the starting stack value.
            if len(stack) == 0:
                raise ValueError('Extraneous conditional end marker on line %i' % n)
        elif stack[-1][1]:
            # We're currently printing lines.
            out += line + '\n'

    # Make sure we ended up in a sane state.
    if len(stack) != 1:
        raise ValueError('Unterminated conditional start markers on lines ' + ', '.join('%i' % n for n,_ in stack[1:]))

    # Done :)
    return out

# Main script!
args = parseArgs()
markdown = open(args.input, 'rb').read().decode('utf-8')
markdown = processDirectives(markdown, args.flags)
open(args.output, 'wb').write(markdown.encode('utf-8'))
