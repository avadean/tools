#! /usr/bin/python3.7

import re
import classes


def get_cell(string):
    in_cell = False

    try:
        active = False if string[0] in ["!", "#"] else True
    except IndexError:
        return string, in_cell, False, False

    string = string if active else string[1:].strip()

    if string[:6] == "%BLOCK":
        string  = string[6:].strip()
        in_cell = True

    try:
        match = re.findall(r"%?\w+", string)[0]
        #return string, in_cell, match, active
    except IndexError:
        return string, in_cell, False, active

    try:
        return string[len(match):].strip()[1:].strip() if string[len(match):].strip()[0] in [":", "="] else string[len(match):].strip(), in_cell, match, active
    except IndexError:
        return string[len(match):].strip(), in_cell, match, active


#def get_line(string):
#    try:
#        active = False if string[0] in ["!", "#"] else True
#    except IndexError:
#        return False, False
#
#    return string, active


def get_param(string):
    try:
        active = False if string[0] in ["!", "#"] else True
    except IndexError:
        return string, False, False

    string = string if active else string[1:].strip()

    try:
        match = re.findall(r"%?\w+", string)[0].upper()
    except IndexError:
        return string, False, active

    try:
        return string[len(match):].strip()[1:].strip() if string[len(match):].strip()[0] in [":", "="] else string[len(match):].strip(), match, active
    except IndexError:
        return string[len(match):].strip(), match, active


def get_unit(string):
    try:
        return re.findall(r"\w+", string)[0]
    except IndexError:
        return False


def get_active(string):
    try:
        active = False if string[0] in ["!", "#"] else True
    except IndexError:
        return False, False

    return string if active else string[1:].strip(), active

def get_string(string):
    # Check for a float first to make sure we don't have one.
    try:
        match = re.findall(r"^-?\d+\.?\d*[e,E]?[+-]?\d*", string)[0]
        if match:
            return string, False
    except IndexError:
        try:
            match = re.findall(r"^\w+", string)[0]
        except IndexError:
            return string, False
    return string[len(match):].strip(), match

def get_float(string):
    try:
        match = re.findall(r"^-?\d+\.?\d*[e,E]?[+-]?\d*", string)[0]
    except IndexError:
        return string, False

    return string[len(match):].strip(), match

def get_int(string):
    # Try to get a float first.
    try:
        match = re.findall(r"^-?\d+\.?\d*[e,E]?[+-]?\d*", string)[0]
    except IndexError:
        return string, False

    # If found then make sure it's actually an int and NOT a float.
    if not match.isdigit():
        return string, False
    else:
        return string[len(match):].strip(), match

# Can only have a single comment (i.e single "!") on any one line.
# Lines that are pure comments do not work.
def get_comment(string):
    try:
        return re.findall(r".*", string[1:])[0].strip() if string[0] in ["!", "#"] else False
    except IndexError:
        return False


# Does not kick up a fuss if there is no value.
def get_value(string):
    try:
        match1 = re.findall(r"^-?\d+\.?\d*[e,E]?[+-]?\d*", string)[0] # Try for a float.
        string = string[len(match1):].strip()
    except IndexError:
        try:
            match1 = re.findall(r"^[\w+-]+", string)[0].upper() # If not then try for a string.
            string = string[len(match1):].strip()
            return string, match1, False
        except IndexError:
            return string, False, False # If not then bad.

    try:
        match2 = re.findall(r"^-?\d+\.?\d*[e,E]?[+-]?\d*", string)[0] # Try for another float in case it's a vector.
        string = string[len(match2):].strip()
        match3 = re.findall(r"^-?\d+\.?\d*[e,E]?[+-]?\d*", string)[0] # Final part of vector.
        string = string[len(match3):].strip()
        unit   = get_unit(string)
        string = string[len(unit):].strip() if unit else string
        return string, classes.ThreeVector(match1.upper(), match2.upper(), match3.upper(), False), unit

    except IndexError:
        unit   = get_unit(string) # If we couldn't find a vector then it must just be a float, so try for a unit.
        string = string[len(unit):].strip() if unit else string
        return string, match1.upper(), unit


def get_file(string):
    try:
        match = re.findall(r"^[\w.]+", string)[0]
        string = string[len(match):].strip()
        return string, match
    except IndexError:
        return string, False


def get_species_pot_parts(string):
    try:
        line_no_comment = re.findall(r"^.*!", string)[0]
        line_no_comment = line_no_comment[:-1].strip()
    except IndexError:
        line_no_comment = string

    return line_no_comment.split()  #line_no_comment.split(' ')
    #list(filter(('').__ne__, parts))


def unit_convert(typ, value, unit):
    if unit:
        factor = {
            'ENERGY' : { # cut_off_energy, smearing_width
                # Converting from...
                'EV' : 1.0             * (10 **   0),  # Electronvolts (default).
                'HA' : 2.7211386245988 * (10 **   1),  # Hartrees.
                'J'  : 6.241509074     * (10 **  18),  # Joules.
                'RY' : 1.36056980659   * (10 **   1),  # Rydbergs.
                # ... into electronvolts.
            }
        }.get(typ).get(unit.upper())

        return float(value) * factor
    else:
        return float(value) * 1.0 # Use 1.0 as factor i.e assumes value is default.


def get_file_lines(fil, args):
    with open(fil) as f:
        lines = f.read().splitlines()

    if args.verbose:
        print('Read lines of file ' + fil)

    return lines


def write_file_lines(fil, lines, args):
    with open(fil, 'w') as f:
        for line in lines:
            f.write(line + '\n')

    if args.verbose:
        print('Written to file ' + fil)

    return


def get_atomic_num(symbol):
    from mendeleev import element
    return element(symbol).atomic_number

def get_atomic_sym(number):
    from mendeleev import element
    return element(number).symbol


def get_spaced_column(column, no_extend_floats, no_floats=False):
    class SpacedString:
        def __init__(self, string, no_floats):
            self.string        = string
            self.split_string  = self.string.split('.') if not no_floats else [self.string]
            self.spaced_string = False

            if len(self.split_string) == 2:
                self.pref, self.suff = self.split_string[0], self.split_string[1]
                self.dot = True
            else:
                self.pref, self.suff = self.split_string[0], ''
                self.dot = False

            self.len_pref, self.len_suff = len(self.pref), len(self.suff)
            self.is_digit                = self.pref.isdigit()

        def get_spaced_string(self, max_pref, max_suff, need_extra_digit, no_extend_floats, no_floats):
            if no_floats:
                self.spaced_string = self.pref + (' ' * (max_pref - self.len_pref)) +\
                    ('.' if self.dot else ('.' if self.is_digit and not no_extend_floats else ' ') if need_extra_digit else '') +\
                    (' ' * (max_suff - self.len_suff)) + self.suff
            else:
                self.spaced_string = (' ' * (max_pref - self.len_pref)) + self.pref +\
                    ('.' if self.dot else ('.' if self.is_digit and not no_extend_floats else ' ') if need_extra_digit else '') +\
                    self.suff + (('0' if self.is_digit and not no_extend_floats else ' ') * (max_suff - self.len_suff))

    if not no_floats:
        no_extend_floats = True

    spaced_strings = [SpacedString(string, no_floats) for string in column]

    max_pref         = max([st.len_pref for st in spaced_strings], default=0)
    max_suff         = max([st.len_suff for st in spaced_strings], default=0)
    need_extra_digit = any([st.dot for st in spaced_strings]) # Digit could be extra '.' or extra ' '

    for string in spaced_strings:
        string.get_spaced_string(max_pref, max_suff, need_extra_digit, no_extend_floats, no_floats)

    return [string.spaced_string for string in spaced_strings]



