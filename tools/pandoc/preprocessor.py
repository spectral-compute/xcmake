#!/usr/bin/env python3

import argparse
import collections
import os.path
import re
import xml.etree.ElementTree

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
  A directive must exist on a line on its own to be recognised.

Tag file processing:
  Doxygen tag files can be used to resolve references much like in Doxygen comment blocks. References inside backticks
  and non-alphabetic references are linked.''')

    parser.add_argument('-i', dest='input', required=True, action='store', metavar='INPUT',
                        help='Unpreprocessed input markdown.')
    parser.add_argument('-o', dest='output', required=True, action='store', metavar='OUTPUT',
                        help='Preprocessed output markdown.')
    parser.add_argument('-t', dest='target', action='store', metavar='TARGET',
                        help='Install location of the output. Used to make relative links to locally installed '
                             'documentation.')
    parser.add_argument('-d', dest='local_doxygen', action='append', nargs=2, metavar=('TAGFILE', 'INSTALL_PATH'),
                        default=[],
                        help='Add a tag file with corresponding locally installed documentation.')
    parser.add_argument('-D', dest='url_doxygen', action='append', nargs=2, metavar=('TAGFILE', 'URL'), default=[],
                        help='Add a tag file with corresponding documentation at a given URL.')
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

def parseTagFile(tagFilePath, location, relative, url):
    Tag = collections.namedtuple('Tag', ['name', 'link', 'ref', 'group', 'filename', 'anchor', 'kind'])

    def formLink(filename, anchor):
        path = ('%s/%s' % (location.rstrip('/'), filename)) if url else os.path.join(location, filename)
        if relative:
            path = os.path.relpath(path, relative)
        return path if anchor is None else ('%s#%s' % (path, anchor))

    # Extract the tags from the tag file.
    def parseTag(element, prefix, viaGroup):
        # Return empty for unknown tags.
        if element.tag not in {'compound', 'member', 'tagfile'}:
            return []

        # Return empty for unknown kinds.
        if (element.tag == 'compound' or element.tag == 'member') and \
           element.attrib['kind'] not in {'class', 'define', 'function', 'enumeration', 'enumvalue', 'group',
                                          'namespace', 'struct', 'typedef', 'variable'}:
            return []

        # Look through things that don't add a name.
        isGroup = element.tag == 'compound' and element.attrib['kind'] == 'group'
        if element.tag == 'tagfile' or isGroup:
            return sum((parseTag(c, prefix, viaGroup or isGroup) for c in element), start=[])

        # Extract information about this element.
        name = element.find('name')
        if name is None:
            return []
        name = prefix + name.text

        filename = element.find('filename')
        anchorfile = element.find('anchorfile')
        if filename is not None:
            filename = filename.text
        elif anchorfile is not None:
            filename = anchorfile.text

        anchor = element.find('anchor')
        if anchor is not None:
            anchor = anchor.text

        # Build the tag object.
        tag = None if filename is None else \
              Tag(name, formLink(filename, anchor), filename + (('#%s' % anchor) if anchor else ''), viaGroup, filename,
                  anchor, element.attrib['kind'])

        # Return all this element's children followed by this element.
        return sum((parseTag(c, name + '::', viaGroup) for c in element), start=[]) + ([] if tag is None else [tag])

    tags = parseTag(xml.etree.ElementTree.parse(tagFilePath).getroot(), '', False)

    # Strip out the tags from groups that also exist elsewhere. We need this because unqualified names appear in groups
    # and in namespaces, but if things in the global namespace only appear in groups.
    nonGroupTags = {tag.ref for tag in tags if not tag.group}
    tags = [tag for tag in tags if not tag.group or not tag.ref in nonGroupTags]

    # Done :)
    return tags

def processTextWithTag(text, tag, withBackTick):
    # Optimization: if the tag name is not a substring of the text, then neither will be the full regex.
    if text.find(tag.name) < 0:
        return text

    # Escape the name.
    name = tag.name
    name = name.replace('\\', '\\\\')
    for c in '()[]{}*+?|.':
        name = name.replace(c, '\\' + c)

    # Capture the name.
    pattern = f'({name})'

    # For functions, add the optional ().
    if tag.kind == 'function':
        pattern += '(?:\\(\\))?'

    # The match must be on a word boundary at each side or backtick each side.
    pattern = ('`%s`' % pattern) if withBackTick else ('\\b(?:^|(?<=[^`:]))%s(?:$|(?=[^`:]))\\b' % pattern)

    # Do the replacement.
    return re.sub(pattern, f'[`\\1`]({tag.link})', text)

def processTextWithTags(text, tags):
    for tag in tags:
        text = processTextWithTag(text, tag, True)
        text = processTextWithTag(text, tag, False)
    return text

def processInputWithTagFile(input, tagFilePath, location, relative, url):
    tags = parseTagFile(tagFilePath, location, relative, url)
    sections = input.split('```')

    # Process the input, but skip over ```...```s.
    out = ''
    for i,section in enumerate(sections):
        if i != 0:
            out += '```'
        out += processTextWithTags(section, tags) if i % 2 == 0 else section
    return out

# Main script!
args = parseArgs()
markdown = open(args.input, 'rb').read().decode('utf-8')
markdown = processDirectives(markdown, args.flags)
for tag,loc in args.local_doxygen:
    markdown = processInputWithTagFile(markdown, tag, loc, args.target, False)
for tag,loc in args.url_doxygen:
    markdown = processInputWithTagFile(markdown, tag, loc, None, True)
open(args.output, 'wb').write(markdown.encode('utf-8'))
