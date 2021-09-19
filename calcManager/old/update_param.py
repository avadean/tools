#! /usr/bin/python3.7

import sys
import tools

file_param   = sys.argv[1]
param_to_upd = sys.argv[2]
new_value    = sys.argv[3]
try:
    unit_given = sys.argv[4]
except IndexError:
    unit_given = False

# Get param file.
with open(file_param) as f:
    file_param_lines = f.read().splitlines()

# Get info of param that needs updating.
for num, line in enumerate(file_param_lines, 0):
    ln = line.strip()
    ln, param, active = tools.get_param(ln)
    if param == param_to_upd.strip().upper():
        ln, value, unit = tools.get_value(ln)
        comment = tools.get_comment(ln)
        file_param_lines[num] = param + " : " + new_value + " " + (unit_given if unit_given else (unit if unit else "")) + " ! " + (comment if comment else "")

# Write new param file.
with open(file_param, 'w') as f:
    for line in file_param_lines:
        f.write(line + '\n')

