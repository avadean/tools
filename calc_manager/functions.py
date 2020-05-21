#! /usr/bin/python3.7

import sys

import cells
import params
import tools



def check(cell_file, param_file, args):

    if cell_file:
        pass # Do cell check.

    if param_file:
        def get_param(param, param_list):
            for prm in param_list:
                if prm.param == param:
                    return prm

        def is_set(param, param_list):
            return True if param in [prm.param for prm in param_list] else False

        def value(param, param_list):
            return get_param(param, param_list).values[0]

        def unit(param, param_list):
            return get_param(param, param_list).units[0]

        class ParamBasic:
            def __init__(self, param, value, unit, required, allowed_values, is_string, is_bool, is_float, is_int, has_unit, known):
                self.param          = param
                self.values         = [value]
                self.units          = [unit]
                self.required       = required
                self.allowed_values = allowed_values
                self.is_string      = is_string
                self.is_bool        = is_bool
                self.is_float       = is_float
                self.is_int         = is_int
                self.has_unit       = has_unit
                self.known          = known

            def add_value_unit(self, value, unit):
                self.values.append(value)
                self.units.append(unit)

        def get_active_param_summary(params, param_file, args):
            # Get info for active params in param file.
            params_sum = []
            for param in params:
                if param.active:
                    if is_set(param.param, params_sum): # If the param is already set then add its values.
                        get_param(param.param, params_sum).add_value_unit(param.value, param.unit)
                    else: # Otherwise, create a new Basic Param for it.
                        params_sum.append(ParamBasic(param.param, param.value, param.unit, param.required, param.allowed_values,\
                                                     param.is_string, param.is_bool, param.is_float, param.is_int,\
                                                     param.has_unit, param.known))
            if args.verbose:
                print('Found values and units for active params in ' + param_file)

            return params_sum

        def get_other_params(param_list, param_file, args):
            param_names  = [p.param for p in param_list]
            other_params = {}
            for param in params.dict_keywords:
                if param not in param_names:
                    other_params[param] = params.dict_keywords[param]
            if args.verbose:
                print('Got dict of params not active in ' + param_file)

            return other_params

        # Script that checks that the param file will not error in the CASTEP calculation.
        # Could also give hints on how to speed up certain calculations.
        # E.g. if magres_task is set but task is not magres then magres_task is ignored by CASTEP.
        # Give out warning for lines that do not make sense e.g. parameters that don't exist.

        # Get params in param file.
        prms = params.get_params(param_file, args)

        # Get info for active params in param file.
        params_sum = get_active_param_summary(prms, param_file, args)

        # Get info for params that are not in (or not active in) the param file.
        other_prms = get_other_params(params_sum, param_file, args)

        # Check for any unspecified params that probably should be specified.
        for prm in other_prms:
            if other_prms[prm]['required']:
                print('Warning: ' + prm + ' has not been set. Default is ' + other_prms[prm]['default'] + '.')

        for prm in params_sum:
            # Check for any params that are not known.
            if not prm.known:
                print('Warning: ' + prm.param + ' is not a known parameter.')

            # Check if param has multiple entries.
            if len(prm.values) > 1:
                print('Warning: ' + prm.param + ' is set ' + str(len(prm.values)) + ' times. Only the first instance will be used for the subsequent checks.')
                for num, val in enumerate(prm.values):
                    print('         ' + prm.param + ' : ' + val + ((' ' + prm.units[num]) if prm.units[num] else ''))

            # Only do analysis if value is actually set.
            if value(prm.param, params_sum):
                # Check param value is of its allowed values.
                if prm.is_string or prm.is_bool:
                    if value(prm.param, params_sum) not in prm.allowed_values:
                        print('Warning: value of \'' + value(prm.param, params_sum) + '\' is not allowed for ' + prm.param + '. The allowed value/s is/are:')
                        for val in prm.allowed_values:
                            print('  ' + str(val))
                elif prm.is_float:
                    try:
                        if float(value(prm.param, params_sum)) > prm.allowed_values[0] or float(value(prm.param, params_sum)) < prm.allowed_values[1]: # [0] is max value allowed and [1] is min value allowed for floats and ints.
                            print('Value of \'' + value(prm.param, params_sum) + '\'' + ((' ' + unit(prm.param, params_sum)) if unit(prm.param, params_sum) else '') + ' is not allowed for ' + prm.param + '. The max and min values (respectively) are:')
                            print('  ' + str(prm.allowed_values[0]))
                            print('  ' + str(prm.allowed_values[1]))
                    except ValueError:
                        print('Warning: ValueError with ' + value(prm.param, params_sum) + ' for ' + prm.param + '. Value should be a float.')
                elif prm.is_int:
                    try:
                        if int(value(prm.param, params_sum)) > prm.allowed_values[0] or int(value(prm.param, params_sum)) < prm.allowed_values[1]: # [0] is max value allowed and [1] is min value allowed for floats and ints.
                            print('Warning: value of \'' + value(prm.param, params_sum) + '\'' + ((' ' + unit(prm.param, params_sum)) if unit(prm.param, params_sum) else '') + ' is not allowed for ' + prm.param + '. The max and min values (respectively) are:')
                            print('  ' + str(prm.allowed_values[0]))
                            print('  ' + str(prm.allowed_values[1]))
                    except ValueError:
                        print('Warning: ValueError with ' + value(prm.param, params_sum) + ' for ' + prm.param + '. Value should be an int.')

                # Check params that should have units, do.
                if not unit(prm.param, params_sum) and prm.has_unit:
                    print('Warning: ' + prm.param + ' requires a unit. Default will be used by CASTEP.')


                # Unusual and specific checks.

                # TASK.
                if prm.param == 'TASK':
                    if value('TASK', params_sum) == 'MAGRES':
                        if not is_set('MAGRES_TASK', params_sum):
                            print('Warning: TASK is set to MAGRES but MAGRES_TASK is not set. Default is ' + params.dict_keywords['MAGRES_TASK']['default'] + '.')
                    elif value('TASK', params_sum) == 'SPECTRAL':
                        if not is_set('SPECTRAL_TASK', params_sum):
                            print('Warning: TASK is set to SPECTRAL but SPECTRAL_TASK is not set. Default is ' + params.dict_keywords['SPECTRAL_TASK']['default'] + '.')

                # CUT_OFF_ENERGY.
                elif prm.param == 'CUT_OFF_ENERGY': # and unit('CUT_OFF_ENERGY', params_sum):
                    if tools.unit_convert('ENERGY', value('CUT_OFF_ENERGY', params_sum), unit('CUT_OFF_ENERGY', params_sum)) <= 250.0:
                        print('Warning: CUT_OFF_ENERGY is 250 eV or less, this calculation may be very innaccurate.')
                    elif tools.unit_convert('ENERGY', value('CUT_OFF_ENERGY', params_sum), unit('CUT_OFF_ENERGY', params_sum)) >= 1000.0:
                        print('Warning: CUT_OFF_ENERGY is 1000 eV or higher, this calculation may take a long time to run.')

                # SPIN.
                elif prm.param == 'SPIN_ORBIT_COUPLING':
                    if value('SPIN_ORBIT_COUPLING', params_sum) in ['T', 'TRUE']:
                        if not is_set('SPIN_TREATMENT', params_sum) or (is_set('SPIN_TREATMENT', params_sum) and value('SPIN_TREATMENT', params_sum) != 'VECTOR'):
                            print('Warning: SPIN_ORBIT_COUPLING requires SPIN_TREATMENT to be VECTOR.')


            else:
                print('Warning: ' + prm.param + ' value is not set.')

        if not args.quiet:
            print(param_file + ' checked.')


def create(cell_file, param_file, system, args):
    if system == 'molecule':
        if cell_file:
            template_molecule_cell  = "/home/dean/tools/calc_manager/files/molecule.cell"
            if args.verbose:
                print('Found molecule cell template ' + template_molecule_cell)

            lines_template_molecule_cell = tools.get_file_lines(template_molecule_cell, args)
            tools.write_file_lines(cell_file, lines_template_molecule_cell, args)
            if not args.quiet:
                print('Molecule cell file ' + cell_file + ' created.')

        if param_file:
            template_molecule_param = "/home/dean/tools/calc_manager/files/molecule.param"
            if args.verbose:
                print('Found molecule param template ' + template_molecule_param)

            lines_template_molecule_param = tools.get_file_lines(template_molecule_param, args)
            tools.write_file_lines(param_file, lines_template_molecule_param, args)
            if not args.quiet:
                print('Molecule param file ' + param_file + ' created.')

    elif system == 'crystal':
        if cell_file:
            template_crystal_cell   = "/home/dean/tools/calc_manager/files/crystal.cell"
            if args.verbose:
                print('Found crystal cell template ' + template_crystal_cell)

            lines_template_crystal_cell = tools.get_file_lines(template_crystal_cell, args)
            tools.write_file_lines(cell_file, lines_template_crystal_cell, args)
            if not args.quiet:
                print('Crystal cell file ' + cell_file + ' created.')

        if param_file:
            template_crystal_param  = "/home/dean/tools/calc_manager/files/crystal.param"
            if args.verbose:
                print('Found crystal param template ' + template_crystal_param)

            lines_template_crystal_param = tools.get_file_lines(template_crystal_param, args)
            tools.write_file_lines(param_file, lines_template_crystal_param, args)
            if not args.quiet:
                print('Crystal param file ' + param_file + ' created.')

def gen_from_cif(file_cif, file_cell, args):

    class CifAtom:
        def __init__(self, symbol, x, y, z):
            self.symbol = symbol
            self.x      = x
            self.y      = y
            self.z      = z

    class Loop:
        def __init__(self, headings, data):
            self.headings = headings
            self.num_head = len(self.headings)
            self.data     = data
            self.num_data = len(self.data)

            self.sorted_data = self.sort_data()

        def sort_data(self):
            sorted_data = []

            for row in self.data:
                split_row = row.split()
                if len(split_row) == self.num_head:
                    sorted_data.append(split_row)
                else:
                    return False

            return sorted_data

    def get_loop(cif_file_lines, start_line):
        headings = []
        data     = []
        for line in [l for n, l in enumerate(cif_file_lines) if n >= start_line]:
            if line.startswith(' _'):
                headings.append(line[2:])
            elif line.startswith('  '):
                data.append(line[2:])
            else:
                break

        return Loop(headings, data)

    # Get cif file.
    cif_file_lines = tools.get_file_lines(file_cif, args)

    # Separate loops and other.
    loops = []
    other = []

    num = 0
    while num < len(cif_file_lines):
        line = cif_file_lines[num]
        num += 1
        if line.startswith('loop_'):
            loops.append(get_loop(cif_file_lines, num))
            num += loops[-1].num_data
        elif line.startswith('_'):
            other.append(line[1:])

    atoms = False
    for loop in loops:
        if loop.sorted_data:

            # Atom data.
            if all([elem in loop.headings for elem in ['atom_site_type_symbol', 'atom_site_fract_x', 'atom_site_fract_y', 'atom_site_fract_z']]):
                col_sym = loop.headings.index('atom_site_type_symbol')
                col_x   = loop.headings.index('atom_site_fract_x')
                col_y   = loop.headings.index('atom_site_fract_y')
                col_z   = loop.headings.index('atom_site_fract_z')

                atoms = []
                for atom in loop.sorted_data:
                    atoms.append(CifAtom(atom[col_sym], atom[col_x], atom[col_y], atom[col_z]))

    a, b, c, alpha, beta, gamma = False, False, False, False, False, False
    for line in other:
        if line.startswith('cell_length_a'):
            a = line.split()[1]
        elif line.startswith('cell_length_b'):
            b = line.split()[1]
        elif line.startswith('cell_length_c'):
            c = line.split()[1]
        elif line.startswith('cell_angle_alpha'):
            alpha = line.split()[1]
        elif line.startswith('cell_angle_beta'):
            beta  = line.split()[1]
        elif line.startswith('cell_angle_gamma'):
            gamma = line.split()[1]

    if all([atoms, a, b, c, alpha, beta, gamma]):
        a, alpha = tools.get_spaced_column([a, alpha], args.no_extend_float)
        b, beta  = tools.get_spaced_column([b, beta ], args.no_extend_float)
        c, gamma = tools.get_spaced_column([c, gamma], args.no_extend_float)
        symbols  = tools.get_spaced_column([atom.symbol for atom in atoms], args.no_extend_float)
        x_vals   = tools.get_spaced_column([atom.x      for atom in atoms], args.no_extend_float)
        y_vals   = tools.get_spaced_column([atom.y      for atom in atoms], args.no_extend_float)
        z_vals   = tools.get_spaced_column([atom.z      for atom in atoms], args.no_extend_float)

        with open(file_cell, 'w') as f:
            f.write('%BLOCK lattice_abc\n')
            f.write(a     + '  ' + b    + '  ' + c     + '\n')
            f.write(alpha + '  ' + beta + '  ' + gamma + '\n')
            f.write('%ENDBLOCK lattice_abc\n')
            f.write('\n')
            f.write('%BLOCK positions_frac\n')
            for num in range(len(atoms)):
                f.write(symbols[num] + '  ' + x_vals[num] + '  ' + y_vals[num] + '  ' + z_vals[num] + '\n')
            f.write('%ENDBLOCK positions_frac')

    else:
        print('Failed to extract atoms from .cif file... Exiting.')
        exit(1)



def remove_cell(cell_file, args):
    # Remove parameter from cell.
    # args.arg3 is param_to_rem.
    # args.arg4 is value_to_rem.

    if not args.no_sort:
        sort(cell_file, False, args)
        if not args.no_check: # Only has the possibility to check if it has been sorted.
            check(cell_file, False, args)
    else:
        print('Cannot check cell file as it must be sorted beforehand.')


def remove_param(param_file, args):
    # args.arg3 is param_to_rem.
    # args.arg4 is value_to_rem.

    # Get param file.
    param_file_lines = tools.get_file_lines(param_file, args)

    # Remove param.
    prm_removed = False
    for num, line in enumerate(param_file_lines, 0):
        ln = line.strip()
        ln, param, active = tools.get_param(ln)
        if param == args.arg3.strip().upper():
            ln, value, unit = tools.get_value(ln)
            if args.arg4: # Optional argument to remove param with certain value.
                if args.arg4.strip().upper() == value:
                    param_file_lines[num] = ''
                    prm_removed = True
                    break
            else:
                param_file_lines[num] = ''
                prm_removed = True
                break

    # Write new param file.
    tools.write_file_lines(param_file, param_file_lines, args)

    if not args.quiet:
        if prm_removed:
            print(args.arg3.strip().upper() + ' with value ' + value + ' removed from param file.')
        else:
            print('Unable to find ' + args.arg3.strip().upper() + (' with value ' + args.arg4.strip().upper() if args.arg4 else '') + ' to remove... Exiting.')
            exit(1)

    if not args.no_sort:
        sort(False, param_file, args)
        if not args.no_check: # Only has the possibility to check if it has been sorted.
            check(False, param_file, args)
    elif not args.no_check and not args.quiet:
        print('Cannot check param file as it must be sorted beforehand.')


def sort(cell_file, param_file, args):

    if cell_file:
        clls, keywords, comments = cells.get_cells(cell_file, args)

        # Write new cell file.
        if args.verbose:
            print('Sorting ' + cell_file)
        with open(cell_file, 'w') as f:
            priority_level = 1.0
            added_line = False
            for cell in clls:
                if cell.check_for_error(): # If we have an error in the cell then re-write the block unchanged.
                    f.write('%BLOCK ' + cell.cell.lower() + '\n')
                    for line in cell.lines:
                        f.write(line + '\n')
                    f.write('%ENDBLOCK ' + cell.cell.lower() + '\n')
                else: # Otherwise write a neat version of the block.
                    cell.get_block()
                    for line in cell.block:
                        f.write(line + '\n')
                f.write('\n')

        if not args.quiet:
            print(cell_file + ' sorted.')

    if param_file:
        prms = params.get_params(param_file, args)

        # Write new param file.
        if args.verbose:
            print('Sorting ' + param_file)
        with open(param_file, 'w') as f:
            #priority_level = 1.0 + min([prm.priority for prm in prms], default=0.1)
            priority_level = 1.0
            added_line = False
            for num, param in enumerate(prms, 1):
                #while param.priority >= priority_level:
                while priority_level < param.priority:
                    priority_level += 1.0
                    if num != 1 and not added_line:
                        f.write('\n')
                        added_line = True
                f.write(("!" if not param.active else "") + param.param_spaces + " : " + (str(param.value) if param.value else "")\
                        + " " + (param.unit if param.unit else "") + ("  ! " + param.comment if param.comment else "") + '\n')
                added_line = False

        if not args.quiet:
            print(param_file + ' sorted.')


def update_cell(cell_file, args):
    # args.arg3 is cell_to_upd.
    # args.arg4 is new_value.
    # args.arg5 is unit_given.
    # Update cell.

    if not args.no_sort:
        sort(cell_file, False, args)
        if not args.no_check: # Only has the possibility to check if it has been sorted.
            check(cell_file, False, args)
    else:
        print('Cannot check cell file as it must be sorted beforehand.')


def update_param(param_file, args):
    # args.arg3 is param_to_upd.
    # args.arg4 is new_value.
    # args.arg5 is unit_given.

    # Get param file.
    param_file_lines = tools.get_file_lines(param_file, args)

    # Get info of param that needs updating.
    prm_updated = False
    for num, line in enumerate(param_file_lines, 0):
        ln = line.strip()
        ln, param, active = tools.get_param(ln)
        if param == args.arg3.strip().upper():
            ln, value, unit = tools.get_value(ln)
            comment = tools.get_comment(ln)
            param_file_lines[num] = param + " : " + args.arg4.strip().upper() + " " + (args.arg5 if args.arg5 else (unit if unit else "")) + (" ! " + comment if comment else "")
            prm_updated = True
            break

    # Write new param file.
    tools.write_file_lines(param_file, param_file_lines, args)

    # If param was not present (and thus not updated) then add it.
    if not prm_updated:
        with open(param_file, 'a') as f:
            f.write('\n' + args.arg3.strip().upper() + ' : ' + args.arg4.strip().upper() + " " + (args.arg5 if args.arg5 else ""))

    if not args.quiet:
        print(args.arg3.strip().upper() + ' updated to ' + args.arg4.strip().upper() + (' ' + args.arg5 if args.arg5 else '') + '.')

    if not args.no_sort:
        sort(False, param_file, args)
        if not args.no_check: # Only has the possibility to check if it has been sorted.
            check(False, param_file, args)
    elif not args.no_check and not args.quiet:
        print('Cannot check param file as it must be sorted beforehand.')


