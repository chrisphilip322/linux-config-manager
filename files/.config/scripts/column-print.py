#!/usr/bin/env python3

import itertools
import os
import re
import sys

import crayons


def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args, fillvalue=fillvalue)


def col_width(column):
  return max(len(remove_codes(cell)) for cell in column)


code = '\x1b' + r'\[\d{,3}(;\d{,3}){,2}m'
CODE_RE = re.compile(code)
def remove_codes(s):
  return CODE_RE.sub('', s)


COLUMNS = int(os.environ['COLUMNS'])
lines = sys.stdin.readlines()

lines = [
    line.strip()
    for line in lines
    if line.strip()
]

for row_count in itertools.count(1):
  columns = list(list(g) for g in grouper(lines, row_count, (' ', '')))
  width = sum(
      col_width(col)
      for col in columns
  ) + 2 * (len(columns) - 1)
  if width <= COLUMNS:
      break

rows = zip(*columns)
for row in rows:
  for col, cell in zip(columns, row):
    print(cell, end='')
    print((2 + col_width(col) - len(cell[1])) * ' ', end='')
  print()
