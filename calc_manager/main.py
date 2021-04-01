###########################################
###               MODULES               ###
###########################################

import sys
import os
import re
import argparse

import cells
import functions
import params
import tools




###########################################
###              VARIABLES              ###
###########################################

# General.
alias_script        = "calc"
alias_notification  = "noti"

# Scripts.
file_cascheck       = "/home/dean/tools/cascheck.sh"

# Files.
file_bash_aliases   = "/home/dean/.bash_aliases"
file_mol_cell_temp  = "/home/dean/tools/files/cell_template_molecule.txt"
file_mol_param_temp = "/home/dean/tools/files/param_template_molecule.txt"
file_cry_cell_temp  = "/home/dean/tools/files/cell_template_crystal.txt"
file_cry_param_temp = "/home/dean/tools/files/param_template_crystal.txt"
file_queue          = "/home/dean/tools/files/castep_queue.txt"

# Directories.
dir_backup_cell     = "/home/dean/tools/calc_manager/backups/cell/"
dir_backup_param    = "/home/dean/tools/calc_manager/backups/param/"

# Error descriptions.
err_param_exist     = "Param file already exists... Exiting."
err_cell_exist      = "Cell file already exists... Exiting."
err_input_exist     = "Cell and/or param file(s) already exist... Exiting."
err_param_excess    = "Two or more param files found... Exiting."
err_cell_excess     = "Two or more cell files found... Exiting."
err_input_excess    = "Two or more cell and/or param files found... Exiting."
err_param_zero      = "No param file found... Exiting."
err_cell_zero       = "No cell file found... Exiting."
err_input_zero      = "No cell or param file(s) found... Exiting."




###########################################
###              FUNCTIONS              ###
###########################################

def check_param_exist(param_prefix=False):
    if param_prefix:
        return True if (param_prefix + '.param') in os.listdir() else False
    else:
        return True if any([True for f in os.listdir() if re.search(r'\.param$', f)]) else False

def check_cell_exist(cell_prefix=False):
    lst = os.listdir()
    if cell_prefix:
        return True if (cell_prefix + '.cell') in lst else False
    else:
        return True if len([True for f in lst if re.search(r'\.cell$', f)]) - \
            len([True for f in lst if re.search(r'-out\.cell$', f)]) >= 1 else False

def check_input_exist(input_prefix=False):
    return True if check_param_exist(input_prefix) or check_cell_exist(input_prefix) else False

def check_param_excess():
    return True if len([f for f in os.listdir() if re.search(r'\.param$', f)]) > 1 else False

def check_cell_excess():
    lst = os.listdir()
    return True if len([f for f in lst if re.search(r'\.cell$', f)]) - \
        len([f for f in lst if re.search(r'-out\.cell$', f)]) > 1 else False

def check_input_excess():
    return True if check_param_excess() or check_cell_exist() else False

def check_param_zero():
    return True if not any([True for f in os.listdir() if re.search(r'\.param$', f)]) else False

def check_cell_zero():
    lst = os.listdir()
    return True if len([f for f in lst if re.search(r'\.cell$', f)]) - \
        len([f for f in lst if re.search(r'-out\.cell$', f)]) == 0 else False


def get_param_file(args, input_prefix=False):
    if input_prefix:
        param_file = input_prefix + '.param'
        if param_file in os.listdir():
            if args.verbose:
                print('Found param file: ' + param_file)
            return param_file
        elif args.strict:
            print(err_param_zero)
            sys.exit(1)
        else:
            return False
    else:
        if check_param_excess():
            print(err_param_excess)
            sys.exit(1)
        elif check_param_zero():
            if args.strict:
                print(err_param_zero)
                sys.exit(1)
            else:
                return False
        else:
            for f in os.listdir():
                if re.search(r'\.param$', f):
                    if args.verbose:
                        print('Found param file: ' + f)
                    return f

def get_cell_file(args, input_prefix=False):
    if input_prefix:
        cell_file = input_prefix + '.cell'
        if cell_file in os.listdir():
            if args.verbose:
                print('Found cell file: ' + cell_file + '.')
            return cell_file
        elif args.strict:
            print(err_param_zero)
            sys.exit(1)
        else:
            return False
    else:
        if check_cell_excess():
            print(err_cell_excess)
            sys.exit(1)
        elif check_cell_zero():
            if args.strict:
                print(err_cell_zero)
                sys.exit(1)
            else:
                return False
        else:
            for f in os.listdir():
                if re.search(r'\.cell$', f) and not re.search(r'-out\.cell$', f):
                    if args.verbose:
                        print('Found cell file: ' + f)
                    return f




###########################################
###              MAIN CODE              ###
###########################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='Calculation Manager', description='Manages input and output of calculations with CASTEP')

    parser.add_argument('arg1', action='store', choices=['check', 'create', 'gen', 'generate', 'query', 'remove', 'run', 'setqueue', 'sort', 'sub', 'test', 'update'])
    parser.add_argument('arg2', action='store', default=False, nargs='?')
    parser.add_argument('arg3', action='store', default=False, nargs='?')
    parser.add_argument('arg4', action='store', default=False, nargs='?')
    parser.add_argument('arg5', action='store', default=False, nargs='?')

    parser.add_argument('-S', '--no-sort', action='store_true', help='no auto-sort of param and cell files')
    parser.add_argument('-C', '--no-check', action='store_true', help='no auto-check of param and cell files')

    parser.add_argument('-s', '--strict', action='store_true', help='demand one cell and one param')

    parser.add_argument('-p', '--prompt', action='store_true', help='will prompt to update file on check if warning shows')

    parser.add_argument('-E', '--no-extend-float', action='store_true', help='no extending floats with 0s')

    group_comms = parser.add_mutually_exclusive_group()
    group_comms.add_argument(      '--serial', action='store_true', help='runs serial CASTEP on run')
    group_comms.add_argument('-m', '--mpi', action='store_true', help='runs MPI CASTEP on run')

    group_verbosity = parser.add_mutually_exclusive_group()
    group_verbosity.add_argument('-q', '--quiet', action='store_true', help='decreased verbosity')
    group_verbosity.add_argument('-v', '--verbose', action='store_true', help='increased verbosity')

    args = parser.parse_args()

    if not args.serial and not args.mpi:
        #args.serial = True # <- *** Change here for default of comms arch ***
        args.mpi   = True

    if args.verbose:
        print('Using arguments:')
        a = tools.get_spaced_column([a for a in vars(args)], args.no_extend_float)
        for num, arg in enumerate(vars(args)):
            print('  ' + a[num] + ' : ' + str(getattr(args, arg)))
        print('')


    if args.arg1 == 'check':
        if args.arg2 and args.arg2 not in ['cell', 'param']:
            print('Not a valid check option. Please use cell, param or leave blank to check both... Exiting.')
            sys.exit(1)

        if args.no_sort:
            print('File(s) must be sorted before being checked... Exiting.')
            sys.exit(1)

        if not args.arg2 or args.arg2 == 'cell':
            file_cell  = get_cell_file(args)
            functions.sort(file_cell, False, args)
            functions.check(file_cell, False, args)

        if not args.arg2 or args.arg2 == 'param':
            file_param = get_param_file(args)
            functions.sort(False, file_param, args)
            functions.check(False, file_param, args)

    elif args.arg1 == 'create':
        if args.arg2 in ['molecule', 'm']:
            if args.arg3 == 'cell':
                if check_cell_exist():
                    print(err_cell_exist)
                    sys.exit(1)
                else:
                    sys_prefix = input('Please enter a system prefix:\n').strip()
                    if args.verbose:
                        print('Got system prefix ' + sys_prefix)
                    functions.create(sys_prefix + ".cell", False, 'molecule', args)
            elif args.arg3 == 'param':
                if check_param_exist():
                    print(err_param_exist)
                    sys.exit(1)
                else:
                    sys_prefix = input('Please enter a system prefix:\n').strip()
                    if args.verbose:
                        print('Got system prefix ' + sys_prefix)
                    functions.create(False, sys_prefix + ".param", 'molecule', args)
            elif not args.arg3:
                if check_input_exist():
                    print(err_input_exist)
                    sys.exit(1)
                else:
                    sys_prefix = input('Please enter a system prefix:\n').strip()
                    if args.verbose:
                        print('Got system prefix ' + sys_prefix)
                    functions.create(sys_prefix + ".cell", sys_prefix + ".param", 'molecule', args)
            else:
                print('Not a valid molecule option. Use cell or param or leave blank... Exiting.')
                sys.exit(1)
        elif args.arg2 in ['crystal', 'c']:
            if args.arg3 == 'cell':
                if check_cell_exist():
                    print(err_cell_exist)
                    sys.exit(1)
                else:
                    sys_prefix = input('Please enter a system prefix:\n').strip()
                    if args.verbose:
                        print('Got system prefix ' + sys_prefix)
                    functions.create(sys_prefix + ".cell", False, 'crystal', args)
            elif args.arg3 == 'param':
                if check_param_exist():
                    print(err_param_exist)
                    sys.exit(1)
                else:
                    sys_prefix = input('Please enter a system prefix:\n').strip()
                    if args.verbose:
                        print('Got system prefix ' + sys_prefix)
                    functions.create(False, sys_prefix + ".param", 'crystal', args)
            elif not args.arg3:
                if check_input_exist():
                    print(err_input_exist)
                    sys.exit(1)
                else:
                    sys_prefix = input('Please enter a system prefix:\n').strip()
                    if args.verbose:
                        print('Got system prefix ' + sys_prefix)
                    functions.create(sys_prefix + ".cell", sys_prefix + ".param", 'crystal', args)
            else:
                print('Not a valid crystal option. Use cell or param or leave blank... Exiting.')
                sys.exit(1)
        else:
            print('Not a valid create option. Use molecule (m) or crystal (c)... Exiting.')
            sys.exit(1)

    elif args.arg1 in ['generate', 'gen']:
        if args.arg2 == 'cell':
            file_gen = input('Please enter the file to generate a cell file from:\n').strip()
            sys_prefix = input('Please enter a system prefix:\n').strip()
            if args.verbose:
                print('Got system prefix ' + sys_prefix)
            if check_cell_exist(sys_prefix):
                print(err_cell_exist)
                sys.exit(1)
            else:
                if file_gen in [f for f in os.listdir() if os.path.isfile(f)]:
                    if file_gen.endswith('.cif'):
                        functions.gen_from_cif(file_gen, sys_prefix + ".cell", args)
                    else:
                        print(file_gen + ' is not a valid input. Ensure input is a .cif file... Exiting.')
                        sys.exit(1)
                else:
                    print(file_gen + ' is not a file in this directory... Exiting.')
                    sys.exit(1)

        else:
            print('Not a valid generate option. Please use cell... Exiting.')
            sys.exit(1)

    elif args.arg1 == 'query':
        if args.arg2 == 'cell':
            pass
        elif args.arg2 == 'param':
            if args.arg3.upper() in params.dict_keywords:
                file_param = get_param_file(args)
                functions.query_param(file_param, args)
            else:
                print('Not an acceptable parameter to query... Exiting.')
                sys.exit(1)
        else:
            print('Not a valid query option. Please use cell or param... Exiting.')
            sys.exit(1)

    elif args.arg1 == 'remove':
        if args.arg2 == 'cell':
            if args.arg3:
                if args.arg3.upper() in cells.dict_keywords: # Need to code this.
                    file_cell = get_cell_file(args)
                    functions.remove_cell(file_cell, args)
                else:
                    print('Not an acceptable parameter to remove... Exiting.')
                    sys.exit(1)
            else:
                print('Please enter a parameter to remove... Exiting.')
                sys.exit(1)
        elif args.arg2 == 'param':
            if args.arg3:
                if args.arg3.upper() in params.dict_keywords:
                    file_param = get_param_file(args)
                    functions.remove_param(file_param, args)
                else:
                    print('Not an acceptable parameter to remove... Exiting.')
                    sys.exit(1)
            else:
                print('Please enter a parameter to remove... Exiting.')
                sys.exit(1)

        else:
            print('Not a valid remove option. Please use cell or param... Exiting.')
            sys.exit(1)

    elif args.arg1 == 'run':
        file_cell  = get_cell_file(args, args.arg2)
        file_param = get_param_file(args, args.arg2)
        functions.run(file_cell, file_param, file_bash_aliases, alias_notification, args)

    elif args.arg1 == 'setqueue':
        if args.arg2:
            try:
                hrs = float(args.arg2)
            except:
                print('Queue duration must be a float in hours... Exiting.')
                sys.exit(1)

            functions.set_queue(file_cascheck, hrs, args)
        else:
            print('Please enter a duration to set queue for... Exiting.')
            sys.exit(1)

    elif args.arg1 == 'sort':
        if args.arg2 and args.arg2 not in ['cell', 'param']:
            print('Not a valid sort option. Please use cell, param or leave blank to sort both... Exiting.')
            sys.exit(1)

        if not args.arg2 or args.arg2 == 'cell':
            file_cell  = get_cell_file(args)
            functions.sort(file_cell, False, args)

        if not args.arg2 or args.arg2 == 'param':
            file_param = get_param_file(args)
            functions.sort(False, file_param, args)

    elif args.arg1 == 'sub':
        file_cell = get_cell_file(args)
        prefix    = args.arg2 if args.arg2 else file_cell[:-5]
        direc     = os.getcwd()
        functions.sub(prefix, file_queue, direc, args)

    elif args.arg1 == 'update':
        if args.arg2 == 'cell':
            if args.arg3:
                if args.arg3.upper() in cells.dict_keywords:  # Need to code this.
                    if args.arg4:
                        file_cell = get_cell_file(args)
                        if file_cell:
                            functions.update_cell(file_cell, args)
                        else:
                            print('Cannot find cell file to update... Exiting.')
                    else:
                        print('Please enter a value to update ' + args.arg3 + ' to... Exiting.')
                        sys.exit(1)
                else:
                    print('Not an acceptable parameter to update... Exiting.')
                    sys.exit(1)
            else:
                print('Please enter a parameter to update... Exiting.')
                sys.exit(1)
        elif args.arg2 == 'param':
            if args.arg3:
                if args.arg3.upper() in params.dict_keywords:
                    if args.arg4:
                        file_param = get_param_file(args)
                        if file_param:
                            functions.update_param(file_param, args)
                        else:
                            print('Cannot find param file to update... Exiting.')
                    else:
                        print('Please enter a value to update ' + args.arg3 + ' to... Exiting.')
                        sys.exit(1)
                else:
                    print('Not an acceptable parameter to update... Exiting.')
                    sys.exit(1)
            else:
                print('Please enter a parameter to update... Exiting.')
                sys.exit(1)
        else:
            print('Not a valid update option. Use cell or param... Exiting.')
            sys.exit(1)

    elif args.arg1 == 'test':
        file_cell                 = get_cell_file(args)
        cells, keywords, comments = cells.get_cells(file_cell, args)

        file_param                = get_param_file(args)
        prms                      = params.get_params(file_param, args)

        for cell in cells:
            if not cell.check_for_error():
                cell.get_block()
                for line in cell.block:
                    print(line)
            print(' ')

        for keyword in keywords:
            print(('!' if keyword.active else '') + keyword.keyword, keyword.value if keyword.value else '', keyword.unit if keyword.unit else '')
        print('')

        for comment in comments:
            print(comment)

        for prm in prms:
            print(prm.param, prm.value, prm.unit if prm.unit else '')

    sys.exit(0)


