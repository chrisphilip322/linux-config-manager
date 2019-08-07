#!/usr/bin/env python3

import itertools
import os
import sys

import crayons

def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args, fillvalue=fillvalue)

def col_width(column):
  return max(len(cell[1]) for cell in column)

COLORS = {
    ' ': lambda _: '',
    'M': crayons.blue,
    'A': crayons.green,
    'R': crayons.red,
    'C': lambda s: crayons.white(s, bold=True),
    '?': lambda s: crayons.red(s, bold=True),
    '!': lambda s: crayons.green(s, bold=True),
    'I': crayons.magenta
}

COLUMNS = int(os.environ['COLUMNS'])
lines = sys.stdin.readlines()

lines = [
    (line[0], line[2:].strip())
    for line in lines
    if line[0] != ' '
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
    print(COLORS[cell[0]](cell[1]), end='')
    print((2 + col_width(col) - len(cell[1])) * ' ', end='')
  print()
