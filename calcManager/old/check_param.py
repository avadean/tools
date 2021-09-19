#! /usr/bin/python3.7

import sys
import tools
import params

# Script that checks that the param file will not error in the CASTEP calculation.
# Could also give hints on how to speed up certain calculations.

# E.g. if magres_task is set but task is not magres then magres_task is ignored by CASTEP.

# Give out warning for lines that do not make sense e.g. parameters that don't exist.

file_param = sys.argv[1]

prms = params.get_params(file_param)

set_task, value_task = False, ""
set_task_magres, value_task_magres = False, ""
set_task_spectral, value_task_spectral = False, ""

set_xcfunctional, value_xcfunctional = False, ""
set_opt_strategy, value_opt_strategy = False, ""
set_cut_off_energy, value_cut_off_energy, unit_cut_off_energy = False, "", ""
set_fix_occupancy, value_fix_occupancy = False, ""
set_basis_precision, value_basis_precision = False, ""

set_smearing_width, value_smearing_width, unit_smearing_width = False, "", ""
set_metals_method, value_metals_method = False, ""
set_nextra_bands, value_nextra_bands = False, ""

set_spin, value_spin = False, ""
set_spin_polarised = False
set_spin_polarized = False
set_spin_treatment, value_spin_treatment = False, ""
set_spin_orbit_coupling = False

set_bs_nbands, value_bs_nbands = False, ""

set_phonon_method, value_phonon_method = False, ""
set_phonon_sum_rule, value_phonon_sum_rule = False, ""
set_fine_cutoff_method, value_fine_cutoff_method = False, ""

set_charge, value_charge = False, ""

set_calc_molecular_dipole = False
set_popn_calculate = False
set_calculate_raman = False
set_calculate_densdiff = False

set_write_cell_structure = False
set_write_formatted_density = False
set_popn_write = False

set_dipole_unit, value_dipole_unit = False, ""

set_max_scf_cycles, value_max_scf_cycles = False, ""
set_num_dump_cycles, value_num_dump_cycles = False, ""
set_elec_energy_tol, value_elec_energy_tol = False, ""

set_continuation, value_continuation = False, ""
set_iprint, value_iprint = False, ""
set_comment, value_comment = False, ""

for prm in prms:
    if prm.active:
        if prm.param == 'TASK':
            set_task = True
            value_task = prm.value
        elif prm.param == 'MAGRES_TASK':
            set_task_magres = True
        elif prm.param == 'SPECTRAL_TASK':
            set_task_spectral = True
        elif prm.param == 'XCFUNCTIONAL':
            set_xcfunctional = True
        elif prm.param == 'CUT_OFF_ENERGY':
            set_cut_off_energy = True
            value_cut_off_energy = prm.value
            unit_cut_off_energy = prm.unit if prm.unit else 'eV'

if not set_task:
    print('Warning: TASK has not been set. Default is SINGLEPOINT.')
elif set_task:
    if value_task == 'MAGRES':
        if not set_task_magres:
            print('Warning: TASK is set to MAGRES but MAGRES_TASK is not set.')
    elif value_task == 'SPECTRAL':
        if not set_task_spectral:
            print('Warning: TASK is set to SPECTRAL but SPECTRAL_TASK is not set.')

if not set_xcfunctional:
    print('Warning: XCFUNCTIONAL has not been set. Default is LDA.')

if not set_cut_off_energy:
    print('Warning: CUT_OFF_ENERGY has not been set. Default is determined by BASIS_PRECISION=FINE.')
elif set_cut_off_energy:
    if tools.unit_convert('ENERGY', value_cut_off_energy, unit_cut_off_energy.upper()) <= 250.0:
        print('Warning: CUT_OFF_ENERGY is 250 eV or less, this calculation may be very innaccurate.')
    elif tools.unit_convert('ENERGY', value_cut_off_energy, unit_cut_off_energy.upper()) >= 1000.0:
        print('Warning: CUT_OFF_ENERGY is 1000 eV or higher, this calculation may take a long time to run.')


