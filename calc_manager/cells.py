#! /usr/bin/python3.7

import re
import operator

import classes
import tools
import cell_blocks
block_module = 'cell_blocks'

dict_keywords = {
    # Lattice.
    'LATTICE_ABC'             : { 'priority' : 0.1 },
    'LATTICE_CART'            : { 'priority' : 0.1 },

    # Positions.
    'POSITIONS_ABS'           : { 'priority' : 1.1 },
    'POSITIONS_FRAC'          : { 'priority' : 1.1 },

    'CELL_CONSTRAINTS'        : { 'priority' : 2.1 },

    'SPECIES_POT'             : { 'priority' : 3.1 },

    'SYMMETRY_OPS'            : { 'priority' : 4.1 },

    'EXTERNAL_BFIELD'         : { 'priority' : 5.1 },

    # Kpoints.
    'KPOINT_LIST'             : { 'priority' : 6.111 },
    'KPOINTS_LIST'            : { 'priority' : 6.112 },
    'BS_KPOINT_LIST'          : { 'priority' : 6.121 },
    'BS_KPOINTS_LIST'         : { 'priority' : 6.122 },
    'PHONON_KPOINT_LIST'      : { 'priority' : 6.131 },
    'PHONON_KPOINTS_LIST'     : { 'priority' : 6.132 },
    'PHONON_FINE_KPOINT_LIST' : { 'priority' : 6.133 },
    'OPTICS_KPOINT_LIST'      : { 'priority' : 6.141 },
    'OPTICS_KPOINTS_LIST'     : { 'priority' : 6.142 },
    'MAGRES_KPOINT_LIST'      : { 'priority' : 6.151 },
    'SUPERCELL_KPOINT_LIST'   : { 'priority' : 6.161 },
    'SUPERCELL_KPOINTS_LIST'  : { 'priority' : 6.162 },
    'SPECTRAL_KPOINT_LIST'    : { 'priority' : 6.171 },
    'SPECTRAL_KPOINTS_LIST'   : { 'priority' : 6.172 },

    # Keywords
    'KPOINT_MP_SPACING'       : { 'priority' : 7.1 , 'required' : False, 'default' : '0.1 1/Ang'                         , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'is_vector' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]},
    'KPOINTS_MP_SPACING'      : { 'priority' : 7.1 , 'required' : False, 'default' : '0.1 1/Ang'                         , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'is_vector' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]},
    'KPOINT_MP_GRID'          : { 'priority' : 7.2 , 'required' : False, 'default' : 'determined from KPOINTS_MP_SPACING', 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'is_vector' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), 0]},
    'KPOINTS_MP_GRID'         : { 'priority' : 7.2 , 'required' : False, 'default' : 'determined from KPOINTS_MP_SPACING', 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'is_vector' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), 0]},
    'KPOINT_MP_OFFSET'        : { 'priority' : 7.3 , 'required' : False, 'default' : '0.0, 0.0, 0.0'                     , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'is_vector' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), float("-inf")]},
    'KPOINTS_MP_OFFSET'       : { 'priority' : 7.3 , 'required' : False, 'default' : '0.0, 0.0, 0.0'                     , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'is_vector' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), float("-inf")]},
    'FIX_ALL_CELL'            : { 'priority' : 7.4 , 'required' : False, 'default' : 'FALSE'                             , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'is_vector' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'FIX_COM'                 : { 'priority' : 7.5 , 'required' : False, 'default' : 'FALSE'                             , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'is_vector' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'SYMMETRY_TOL'            : { 'priority' : 7.6 , 'required' : False, 'default' : '0.01 Ang'                          , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'is_vector' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]        },
    'SYMMETRY_GENERATE'       : { 'priority' : 7.7 , 'required' : False, 'default' : 'FALSE'                             , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'is_vector' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']}
}






class Keyword:
    def __init__(self, keyword, value, active, unit, comment):
        self.keyword         = keyword
        self.keyword_str_len = len(self.keyword)
        self.value           = value
        self.active          = active
        self.unit            = unit
        self.comment         = comment

        self.get_info()

    def get_spaces(self, max_len_string):
        self.keyword_spaces = self.keyword + ( (max_len_string - self.keyword_str_len) * " " )

    def get_info(self):
        if self.keyword in dict_keywords:
            self.known = True
            self.priority, self.required, self.allowed_values,\
                self.is_string, self.is_bool, self.is_float, self.is_int,\
                self.is_vector, self.has_unit = operator.itemgetter('priority', 'required', 'allowed_values',\
                                                                    'is_string', 'is_bool', 'is_float', 'is_int',\
                                                                    'is_vector', 'has_unit')(dict_keywords[self.keyword])
        else:
            self.known          = False

            # Default values.
            self.priority       = 99.0
            self.required       = False
            self.allowed_values = []
            self.is_string      = False
            self.is_bool        = False
            self.is_float       = False
            self.is_int         = False
            self.is_vector      = False
            self.has_unit       = False


def get_cells(file_cell, args):

    # Get cell file.
    file_cell_lines = tools.get_file_lines(file_cell, args)

    # Get parameters.
    cells    = []
    keywords = []
    comments = []

    num = 0
    while num < len(file_cell_lines):
        ln_orig = file_cell_lines[num].strip()

        # Cell is whether it is a %BLOCK or KEYWORD, and active is if there is "!" or not.
        ln, cell, active = tools.get_param(ln_orig)

        # Only passes if NOT a blank line.
        if cell:

            # Value is LATTICE_CART etc., unit is redundant here and comment is any comments.
            ln, value, unit = tools.get_value(ln)
            comment         = tools.get_comment(ln)

            # If we have a block.
            if cell.upper() == '%BLOCK':
                cell_lines = []

                # If active then get block as normal.
                if active:
                    while True:
                        num += 1
                        ln_orig = file_cell_lines[num].strip()

                        # Cell will contain %ENDBLOCK or gibberish, and active is if there is "!" or not.
                        ln, cell, active          = tools.get_param(ln_orig)
                        ln, end_block_value, unit = tools.get_value(ln)

                        # If it is active then it could potentially be the end of the block.
                        if active:
                            # If we have reached the end of the block.
                            if cell.upper() == '%ENDBLOCK':
                                if end_block_value.upper() == value.upper():
                                    cells.append(eval(block_module + '.' + value.upper())(value.upper(), cell_lines, True, args))
                                elif not args.quiet:
                                    print('Problem with %BLOCK ' + value + ' and %ENDBLOCK ' + end_block_value + '. Ignoring both blocks.')
                                break
                            # If we have found a new block.
                            elif cell.upper() == '%BLOCK':
                                if not args.quiet:
                                    print('Did not find the endblock of ' + value + '. Will assume the end of block before ' + end_block_value + '.')
                                cells.append(eval(block_module + '.' + value.upper())(value.upper(), cell_lines, True, args))
                                num -= 1 # To offset the later num += 1, so we start back at this block again as normal.
                                break
                            # If not then it's just another line of this block.
                            else:
                                cell_lines.append(ln_orig)

                        # If it is not active then it is simply a comment and is added the this block's lines.
                        else:
                            cell_lines.append(ln_orig)

                # If not active then get block but stop when things become active again or !%ENDBLOCK.
                # If we do not find a full commented-out block (i.e we don't find an !%ENDBLOCK) then all the !%ENDBLOCK will be assumed.
                else:
                    while True:
                        num += 1
                        ln_orig = file_cell_lines[num].strip()

                        # Cell will contain %ENDBLOCK and active is if there is "!" or not.
                        ln, cell, active          = tools.get_param(ln_orig)
                        ln, end_block_value, unit = tools.get_value(ln)

                        # If it is active then we count this as the end of the commented-out block.
                        if active:
                            if not args.quiet:
                                print('Did not find the end of !%BLOCK ' + value + '. Will assume the end of block is at the end of commenting-out.')
                            cells.append(eval(block_module + '.' + value.upper())(value.upper(), [line[1:].strip() for line in cell_lines], False, args))
                            num -= 1 # To offset the later num += 1, so we start back at this block again as normal.
                            break

                        # If it is not active then it is processed as a block as normal, just knowing that this is a commented-out block.
                        else:
                            # If we have reached the end of the block.
                            if cell.upper() == '%ENDBLOCK':
                                if end_block_value.upper() == value.upper():
                                    cells.append(eval(block_module + '.' + value.upper())(value.upper(), [line[1:].strip() for line in cell_lines], False, args))
                                elif not args.quiet:
                                    print('Problem with !%BLOCK ' + value + ' and !%ENDBLOCK ' + end_block_value + '. Ignoring both commented-out blocks.')
                                break
                            # If we have found a new block.
                            elif cell.upper() == '%BLOCK':
                                if not args.quiet:
                                    print('Did not find the end of ' + value + '. Will assume the end of block before ' + end_block_value + '.')
                                cells.append(eval(block_module + '.' + value.upper())(value.upper(), [line[1:].strip() for line in cell_lines], False, args))
                                num -= 1 # To offset the later num += 1, so we start back at this block again as normal.
                                break
                            # If not then it's just another line of this block.
                            else:
                                cell_lines.append(ln_orig)

            # If there is an %ENDBLOCK where it shouldn't be.
            elif cell.upper() == '%ENDBLOCK' and not args.quiet:
                print('Found %ENDBLOCK ' + value + ' before %BLOCK ' + value + '. Ignoring this. Any previous lines (up till the last block) will be considered as keywords.')

            # If not we have a comment or keyword.
            else:
                if cell.upper() in dict_keywords:
                    if type(value) is classes.ThreeVector:
                        keywords.append(Keyword(cell.upper(), value, active, unit, comment))
                    else:
                        keywords.append(Keyword(cell.upper(), value.upper() if value else value, active, unit, comment))
                else:
                    comments.append(ln_orig[1:].strip() if ln_orig[0] in ["!", "#"] else ln_orig)

        num += 1

    if args.verbose:
        print('Got cells for cell file ' + file_cell)

    # Update keywords with extra spaces for formatted alignment.
    max_keyword_str_len = max([keyword.keyword_str_len for keyword in keywords], default=0)
    for keyword in keywords:
        keyword.get_spaces(max_keyword_str_len)
    if args.verbose:
        print('Found keyword spaces for ' + file_cell)

    cells.sort(key=lambda cell: cell.priority)
    keywords.sort(key=lambda keyword: keyword.priority)

    return cells, keywords, comments




