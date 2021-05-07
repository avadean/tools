#! /usr/bin/python3.7

import tools
import operator


# Need to add:
# - %BLOCK DEVEL_CODE
# Do not add any integer priorities e.g 3.0.
dict_keywords = {
    # Tasks.
    'TASK'                      : { 'priority' : 0.1 , 'required' : True , 'default' : 'SINGLEPOINT'                , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['SINGLEPOINT', 'BANDSTRUCTURE', 'GEOMETRYOPTIMISATION', 'GEOMETRYOPTIMIZATION', 'MOLECULARDYNAMICS', 'OPTICS', 'TRANSITIONSTATESEARCH', 'PHONON', 'EFIELD', 'PHONON+EFIELD', 'THERMODYNAMICS', 'WANNIER', 'MAGRES', 'ELNES', 'SPECTRAL', 'EPCOUPLING', 'GENETICALGOR']},
    'MAGRES_TASK'               : { 'priority' : 0.2 , 'required' : False, 'default' : 'SHIELDING'                  , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['SHIELDING', 'EFG', 'NMR', 'GTENSOR', 'HYPERFINE', 'EPR', 'JCOUPLING']},
    'MAGRES_METHOD'             : { 'priority' : 0.3 , 'required' : False, 'default' : 'CRYSTAL'                    , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['CRYSTAL', 'MOLECULAR', 'MOLECULAR3']},
    'SPECTRAL_TASK'             : { 'priority' : 0.4 , 'required' : False, 'default' : 'BANDSTRUCTURE'              , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['BANDSTRUCTURE', 'DOS', 'OPTICS', 'CORELOSS', 'ALL']},

    # General.
    'XCFUNCTIONAL'              : { 'priority' : 1.1 , 'required' : True , 'default' : 'LDA'                        , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['LDA', 'PW91', 'PBE', 'PBESOL', 'RPBE', 'WC', 'BLYP', 'LDA-C', 'LDA-X', 'ZERO', 'HF', 'PBE0', 'B3LYP', 'HSE03', 'HSE06', 'EXX-X', 'HF-LDA', 'EXX', 'EXX-LDA', 'SHF', 'SX', 'SHF-LDA', 'SX-LDA', 'WDA', 'SEX', 'SEX-LDA', 'RSCAN']},
    'OPT_STRATEGY'              : { 'priority' : 1.2 , 'required' : False, 'default' : 'DEFAULT'                    , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['DEFAULT', 'SPEED', 'MEMORY']},
    'CUT_OFF_ENERGY'            : { 'priority' : 1.3 , 'required' : True , 'default' : 'set by BASIS_PRECISION=FINE', 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]},
    'FIX_OCCUPANCY'             : { 'priority' : 1.4 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'BASIS_PRECISION'           : { 'priority' : 1.5 , 'required' : False, 'default' : 'FINE'                       , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['NULL', 'COARSE', 'MEDIUM', 'FINE', 'PRECISE', 'EXTREME']},
    'RELATIVISTIC_TREATMENT'    : { 'priority' : 1.6 , 'required' : False, 'default' : 'KOELLING-HARMON'            , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['KOELLING-HARMON', 'SCHROEDINGER', 'ZORA', 'DIRAC']},

    # Metals.
    'SMEARING_WIDTH'            : { 'priority' : 2.1 , 'required' : False, 'default' : '0.2 eV'                     , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]},
    'METALS_METHOD'             : { 'priority' : 2.2 , 'required' : False, 'default' : 'DM'                         , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['NONE (=ALLBANDS)', 'DM', 'EDFT']},
    'NEXTRA_BANDS'              : { 'priority' : 2.3 , 'required' : False, 'default' : '0 if FIX_OCCUPANCY else 4'  , 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), 0]},

    # Spin.
    'SPIN'                      : { 'priority' : 3.1 , 'required' : False, 'default' : '0.0'                        , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'has_unit' : False, 'allowed_values' : [float("inf"), -float("inf")]},
    'SPIN_POLARISED'            : { 'priority' : 3.2 , 'required' : False, 'default' : 'TRUE if SPIN > 0 else FALSE', 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'SPIN_POLARIZED'            : { 'priority' : 3.2 , 'required' : False, 'default' : 'TRUE if SPIN > 0 else FALSE', 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'SPIN_TREATMENT'            : { 'priority' : 3.3 , 'required' : False, 'default' : 'NONE'                       , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['NONE', 'SCALAR', 'VECTOR']},
    'SPIN_ORBIT_COUPLING'       : { 'priority' : 3.4 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},

    # Bandstructure.
    'BS_NBANDS'                 : { 'priority' : 4.1 , 'required' : False, 'default' : 'see castep --help bs_nbands', 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), 0]},

    # Phonons.
    'PHONON_METHOD'             : { 'priority' : 5.1 , 'required' : False, 'default' : 'set by PHONON_FINE_METHOD'  , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['DFPT', 'LINEARRESPONSE', 'FINITEDISPLACEMENT']},
    'PHONON_SUM_RULE'           : { 'priority' : 5.2 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'PHONON_FINE_CUTOFF_METHOD' : { 'priority' : 5.3 , 'required' : False, 'default' : 'CUMULANT'                   , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['CUMULANT', 'SPHERICAL']},

    # Charge.
    'CHARGE'                    : { 'priority' : 6.1 , 'required' : False, 'default' : '0.0'                        , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'has_unit' : False, 'allowed_values' : [float("inf"), -float("inf")]},

    # Calculate.
    'CALC_MOLECULAR_DIPOLE'     : { 'priority' : 7.1 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'POPN_CALCULATE'            : { 'priority' : 7.2 , 'required' : False, 'default' : 'TRUE'                       , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'CALCULATE_RAMAN'           : { 'priority' : 7.3 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'CALCULATE_DENSDIFF'        : { 'priority' : 7.4 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},

    # Write.
    'WRITE_CELL_STRUCTURE'      : { 'priority' : 8.1 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'WRITE_FORMATTED_DENSITY'   : { 'priority' : 8.2 , 'required' : False, 'default' : 'FALSE'                      , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},
    'POPN_WRITE'                : { 'priority' : 8.3 , 'required' : False, 'default' : 'ENHANCED'                   , 'is_string' : False, 'is_bool' : True , 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['T', 'F', 'TRUE', 'FALSE']},

    # Units.
    'DIPOLE_UNIT'               : { 'priority' : 9.1 , 'required' : False, 'default' : 'DEBYE'                      , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['many']},

    # Miscellaneous.
    'MAX_SCF_CYCLES'            : { 'priority' : 10.1, 'required' : False, 'default' : '30'                         , 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), 0]},
    'NUM_DUMP_CYCLES'           : { 'priority' : 10.2, 'required' : False, 'default' : '0'                          , 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), 0]},
    'ELEC_ENERGY_TOL'           : { 'priority' : 10.3, 'required' : False, 'default' : '10^-5 eV for most tasks'    , 'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]},
    'BS_EIGENVALUE_TOL'         : { 'priority' : 10.4, 'required' : False, 'default' : '10^-6 eV/eig (10^-9 eV/eig if TASK=MAGRES or PHONON)',
                                                                                                                      'is_string' : False, 'is_bool' : False, 'is_float' : True , 'is_int' : False, 'has_unit' : True , 'allowed_values' : [float("inf"), 0.0]},

    # Extra.
    'CONTINUATION'              : { 'priority' : 11.1, 'required' : False, 'default' : 'NULL'                       , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['DEFAULT', 'any file with name up to 255 characters']},
    'IPRINT'                    : { 'priority' : 11.2, 'required' : False, 'default' : '1'                          , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['1', '2', '3']},
    'RAND_SEED'                 : { 'priority' : 11.3, 'required' : False, 'default' : '0'                          , 'is_string' : False, 'is_bool' : False, 'is_float' : False, 'is_int' : True , 'has_unit' : False, 'allowed_values' : [float("inf"), float("-inf")]},
    'COMMENT'                   : { 'priority' : 11.4, 'required' : False, 'default' : '(empty)'                    , 'is_string' : True , 'is_bool' : False, 'is_float' : False, 'is_int' : False, 'has_unit' : False, 'allowed_values' : ['up to 80 characters']}
}


class Param:
    def __init__(self, param, value, active, unit, comment):
        self.param         = param
        self.param_str_len = len(self.param)
        self.value         = value
        self.active        = active
        self.unit          = unit
        self.comment       = comment

        self.get_info()

    def get_spaces(self, max_len_string):
        self.param_spaces = self.param + ( (max_len_string - self.param_str_len) * " " )

    def get_info(self):
        if self.param in dict_keywords:
            self.known = True
            self.priority, self.required, self.allowed_values,\
                self.is_string, self.is_bool, self.is_float, self.is_int,\
                self.has_unit = operator.itemgetter('priority', 'required', 'allowed_values',\
                                                    'is_string', 'is_bool', 'is_float', 'is_int',\
                                                    'has_unit')(dict_keywords[self.param])
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
            self.has_unit       = False


def get_params(file_param, args):

    # Get param file.
    file_param_lines = tools.get_file_lines(file_param, args)

    # Get parameters.
    params = []
    for line in file_param_lines:
        ln                = line.strip()
        ln, param, active = tools.get_param(ln)
        if param: # Ignores blank lines.
            ln, value, unit = tools.get_value(ln)
            comment         = tools.get_comment(ln)
            params.append(Param(param, value, active, unit, comment))
    if args.verbose:
        print('Got params for param file ' + file_param)

    # Update parameters with extra spaces for formatted alignment.
    max_param_str_len = max([par.param_str_len for par in params], default=0)
    for param in params:
        param.get_spaces(max_param_str_len)
    if args.verbose:
        print('Found param spaces for ' + file_param)

    # Sort param list in terms of priority ready for writing.
    params.sort(key=lambda param: param.priority)
    if args.verbose:
        print('Sorted params for ' + file_param)
        print(str(len(params)) + ' params successfully collected for ' + file_param + '\n')

    return params


