#! /usr/bin/python3.7

import sys
import tools
import params

file_param = sys.argv[1]

prms = params.get_params(file_param)

# Write new param file.
with open(file_param, 'w') as f:
    priority_level = 1.0 + min([par.priority for par in prms])
    added_line = False
    for num, param in enumerate(prms):
        while param.priority >= priority_level:
            priority_level += 1.0
            if num != 1 and not added_line:
                f.write('\n')
                added_line = True
        f.write(("!" if not param.active else "") + param.param_spaces + " : " + (str(param.value) if param.value else "")\
                + " " + (param.unit if param.unit else "") + ("  ! " + param.comment if param.comment else "") + '\n')
        added_line = False

