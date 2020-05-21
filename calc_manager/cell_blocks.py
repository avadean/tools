#! /usr/bin/python3.7

import operator

import cells
import tools


class Cell:
    def __init__(self, cell, cell_lines, active, args):
        self.cell        = cell
        self.lines       = cell_lines
        self.active      = active
        self.args        = args

        self.block       = False
        self.block_lines = []
        self.comments    = []
        self.get_block_lines_comments()

        # Default values.
        self.known       = False
        self.priority    = 99.0
        self.get_info_basic()

    def get_block_lines_comments(self):
        for line in self.lines:
            ln, active = tools.get_active(line.strip())

            if ln:
                if active:
                    self.block_lines.append(ln)
                else:
                    self.comments.append(ln)

    def get_info_basic(self):
        if self.cell in cells.dict_keywords:
            self.known    = True
            self.priority = operator.itemgetter('priority')(cells.dict_keywords[self.cell])

    def get_info_all(self):
        if self.cell in cells.dict_keywords:
            self.known    = True
            self.priority = operator.itemgetter('priority')(cells.dict_keywords[self.cell])
            # Currently only have priority in there (so basic=all), but this will be expanded.

    def block_initialise(self):
        self.block = ['%BLOCK ' + self.cell.lower()]

        for comment in self.comments:
            self.block.append('! ' + comment)

    def block_finalise(self):
        self.block.append('%ENDBLOCK ' + self.cell.lower())





class Kpoint:
    def __init__(self, x, y, z, weight, comment):
        self.x       = x
        self.y       = y
        self.z       = z
        self.weight  = weight
        self.comment = comment

class Vector:
    def __init__(self, x, y, z, comment):
        self.x       = x
        self.y       = y
        self.z       = z
        self.comment = comment





class LATTICE_ABC(Cell):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

        self.get_lattice()

    def get_a_b_c(self, ln):
        ln, a    = tools.get_float(ln)
        ln, b    = tools.get_float(ln)
        ln, c    = tools.get_float(ln)
        comment1 = tools.get_comment(ln)
        return a, b, c, comment1

    def get_lattice(self):
        class Lattice:
            def __init__(self, a, b, c, alpha, beta, gamma, comment1, comment2):
                self.a        = a
                self.b        = b
                self.c        = c
                self.alpha    = alpha
                self.beta     = beta
                self.gamma    = gamma
                self.comment1 = comment1
                self.comment2 = comment2

        self.lattice  = False
        self.unit     = False
        checked_unit  = False
        a             = False
        b             = False
        c             = False

        for ln in self.block_lines:
            if not checked_unit:
                ln, self.unit = tools.get_string(ln)
                checked_unit  = True
                if not self.unit:
                    a, b, c, comment1 = self.get_a_b_c(ln)
            else:
                if not a or not b or not c:
                    a, b, c, comment1 = self.get_a_b_c(ln)
                else:
                    ln, alpha = tools.get_float(ln)
                    ln, beta  = tools.get_float(ln)
                    ln, gamma = tools.get_float(ln)
                    comment2  = tools.get_comment(ln)
                    if a and b and c and alpha and beta and gamma:
                        self.lattice = Lattice(a, b, c, alpha, beta, gamma, comment1, comment2)
                    else:
                        return

    def check_for_error(self):
        if self.lattice:
            return False
        else:
            return True


    def get_block(self):
        super().block_initialise()

        self.lattice.a, self.lattice.alpha = tools.get_spaced_column([self.lattice.a, self.lattice.alpha], self.args.no_extend_float)
        self.lattice.b, self.lattice.beta  = tools.get_spaced_column([self.lattice.b, self.lattice.beta ], self.args.no_extend_float)
        self.lattice.c, self.lattice.gamma = tools.get_spaced_column([self.lattice.c, self.lattice.gamma], self.args.no_extend_float)

        if self.unit:
            self.block.append(self.unit)

        self.block.append(self.lattice.a     + '  ' + self.lattice.b    + '  ' + self.lattice.c     + ('  ! ' + self.lattice.comment1 if self.lattice.comment1 else ''))
        self.block.append(self.lattice.alpha + '  ' + self.lattice.beta + '  ' + self.lattice.gamma + ('  ! ' + self.lattice.comment2 if self.lattice.comment2 else ''))

        super().block_finalise()


class LATTICE_CART(Cell):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

        self.get_latt_vect()

    def get_vector(self, ln):
        ln, x    = tools.get_float(ln)
        ln, y    = tools.get_float(ln)
        ln, z    = tools.get_float(ln)
        comment  = tools.get_comment(ln)
        if x and y and z:
            self.vectors.append(Vector(x, y, z, comment))
            return False
        else:
            return True

    def get_latt_vect(self):
        self.vectors  = []
        self.unit     = False
        checked_unit  = False
        error         = False

        for ln in self.block_lines:
            if not checked_unit:
                ln, self.unit = tools.get_string(ln)
                checked_unit  = True
                if not self.unit:
                    error = self.get_vector(ln)
            else:
                error = self.get_vector(ln)

            if error:
                return

        if len(self.vectors) != 3:
            self.unit    = False
            self.vectors = False

    def check_for_error(self):
        if self.vectors:
            return False
        else:
            return True

    def get_block(self):
        super().block_initialise()

        x_vals = tools.get_spaced_column([vect.x for vect in self.vectors], self.args.no_extend_float)
        y_vals = tools.get_spaced_column([vect.y for vect in self.vectors], self.args.no_extend_float)
        z_vals = tools.get_spaced_column([vect.z for vect in self.vectors], self.args.no_extend_float)

        if self.unit:
            self.block.append(self.unit)

        for num, vect in enumerate(self.vectors):
            self.block.append(x_vals[num] + '  ' + y_vals[num] + '  ' + z_vals[num] +\
                              ('  ! ' + vect.comment if vect.comment else ''))

        super().block_finalise()


class CELL_CONSTRAINTS(Cell):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

        self.get_constraints()

    def get_constraints(self):
        class Constraint:
            def __init__(self, a, b, c, alpha, beta, gamma, comment1, comment2):
                self.a        = a
                self.b        = b
                self.c        = c
                self.alpha    = alpha
                self.beta     = beta
                self.gamma    = gamma
                self.comment1 = comment1
                self.comment2 = comment2

        self.constraint = False
        a               = False
        b               = False
        c               = False

        for ln in self.block_lines:
            if not a or not b or not c:
                ln, a    = tools.get_int(ln)
                ln, b    = tools.get_int(ln)
                ln, c    = tools.get_int(ln)
                comment1 = tools.get_comment(ln)
            else:
                ln, alpha = tools.get_int(ln)
                ln, beta  = tools.get_int(ln)
                ln, gamma = tools.get_int(ln)
                comment2  = tools.get_comment(ln)
                if a and b and c and alpha and beta and gamma:
                    self.constraint = Constraint(a, b, c, alpha, beta, gamma, comment1, comment2)
                else:
                    return

    def check_for_error(self):
        if self.constraint:
            return False
        else:
            return True

    def get_block(self):
        super().block_initialise()

        self.constraint.a, self.constraint.alpha = tools.get_spaced_column([self.constraint.a, self.constraint.alpha], self.args.no_extend_float)
        self.constraint.b, self.constraint.beta  = tools.get_spaced_column([self.constraint.b, self.constraint.beta ], self.args.no_extend_float)
        self.constraint.c, self.constraint.gamma = tools.get_spaced_column([self.constraint.c, self.constraint.gamma], self.args.no_extend_float)

        self.block.append(self.constraint.a     + '  ' + self.constraint.b    + '  ' + self.constraint.c + ('  ! ' + self.constraint.comment1 if self.constraint.comment1 else ''))
        self.block.append(self.constraint.alpha + '  ' + self.constraint.beta + '  ' + self.constraint.c + ('  ! ' + self.constraint.comment2 if self.constraint.comment2 else ''))

        super().block_finalise()


class POSITIONS(Cell):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

        self.get_atom_pos()

    def get_atom_pos(self):
        class Atom_Pos:
            def __init__(self, atom, x, y, z, comment):
                try:
                    self.atom_num = int(atom)
                    self.atom_sym = tools.get_atomic_sym(self.atom_num)
                except ValueError:
                    self.atom_sym = atom
                    self.atom_num = tools.get_atomic_num(self.atom_sym)

                self.x        = x
                self.y        = y
                self.z        = z
                self.comment  = comment

        self.atoms    = []
        for ln in self.block_lines:
            # Try atomic symbol.
            ln, atom = tools.get_string(ln)
            # If not then try atomic number. Note: ln is unmodified if tools.get_string() does not find a string.
            if not atom:
                ln, atom = tools.get_int(ln)
            ln, x    = tools.get_float(ln)
            ln, y    = tools.get_float(ln)
            ln, z    = tools.get_float(ln)
            comment  = tools.get_comment(ln)
            if atom and x and y and z:
                self.atoms.append(Atom_Pos(atom, x, y, z, comment))
            else:
                return

        if len(self.atoms) == 0:
            self.atoms = False

    def check_for_error(self):
        if self.atoms:
            return False
        else:
            return True

    def get_block(self):
        super().block_initialise()

        symbols = tools.get_spaced_column([atom.atom_sym for atom in self.atoms], self.args.no_extend_float)
        x_vals  = tools.get_spaced_column([atom.x        for atom in self.atoms], self.args.no_extend_float)
        y_vals  = tools.get_spaced_column([atom.y        for atom in self.atoms], self.args.no_extend_float)
        z_vals  = tools.get_spaced_column([atom.z        for atom in self.atoms], self.args.no_extend_float)

        for num, atom in enumerate(self.atoms):
            self.block.append(symbols[num] + '  ' + x_vals[num] + '  ' + y_vals[num] + '  ' + z_vals[num] + ('  ! ' + atom.comment if atom.comment else ''))

        super().block_finalise()

class POSITIONS_ABS(POSITIONS):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

class POSITIONS_FRAC(POSITIONS):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)


class EXTERNAL_BFIELD(Cell):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

        self.get_bfield()

    def get_bvector(self, ln):
        ln, x    = tools.get_float(ln)
        ln, y    = tools.get_float(ln)
        ln, z    = tools.get_float(ln)
        comment  = tools.get_comment(ln)
        if x and y and z:
            self.bfield = Vector(x, y, z, comment)
            return False
        else:
            return True

    def get_bfield(self):
        self.bfield   = False
        self.unit     = False
        checked_unit  = False
        error         = False

        for ln in self.block_lines:
            if not checked_unit:
                ln, self.unit = tools.get_string(ln)
                checked_unit  = True
                if not self.unit:
                    error = self.get_bvector(ln)
            else:
                error = self.get_bvector(ln)

            if error:
                return

        if not self.bfield:
            self.unit = False

    def check_for_error(self):
        if self.bfield:
            return False
        else:
            return True

    def get_block(self):
        super().block_initialise()

        if self.unit:
            self.block.append(self.unit)

        self.block.append(self.bfield.x + '  ' + self.bfield.y + '  ' + self.bfield.z + ('  ! ' + self.bfield.comment if self.bfield.comment else ''))

        super().block_finalise()


class K_LIST(Cell):
    def __init__(self, cell, cell_lines, active, args, weight):
        super().__init__(cell, cell_lines, active, args)

        self.weight = weight

        self.get_kpoints()

    def get_kpoints(self):
        self.kpoints  = []
        for ln in self.block_lines:
            ln, x      = tools.get_float(ln)
            ln, y      = tools.get_float(ln)
            ln, z      = tools.get_float(ln)

            if self.weight:
                ln, weight = tools.get_float(ln)
            else:
                weight     = True

            comment = tools.get_comment(ln)
            if x and y and z and weight:
                self.kpoints.append(Kpoint(x, y, z, weight if self.weight else False, comment))
            else:
                return

        if len(self.kpoints) == 0:
            self.kpoints = False

    def check_for_error(self):
        if self.kpoints:
            return False
        else:
            return True

    def get_block(self):
        super().block_initialise()

        x_vals = tools.get_spaced_column([kpnt.x for kpnt in self.kpoints], self.args.no_extend_float)
        y_vals = tools.get_spaced_column([kpnt.y for kpnt in self.kpoints], self.args.no_extend_float)
        z_vals = tools.get_spaced_column([kpnt.z for kpnt in self.kpoints], self.args.no_extend_float)

        if self.weight:
            weights = tools.get_spaced_column([kpnt.weight for kpnt in self.kpoints], self.args.no_extend_float)

        for num, kpnt in enumerate(self.kpoints):
            self.block.append(x_vals[num] + '  ' + y_vals[num] + '  ' + z_vals[num] + ('  ' + weights[num] if self.weight else '') + ('  ! ' + kpnt.comment if kpnt.comment else ''))

        super().block_finalise()


class KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class KPOINTS_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class BS_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=False)

class BS_KPOINTS_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=False)

class PHONON_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=False)

class PHONON_KPOINTS_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=False)

class PHONON_FINE_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=False)

class OPTICS_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class OPTICS_KPOINTS_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class MAGRES_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class SUPERCELL_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class SUPERCELL_KPOINTS_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class SPECTRAL_KPOINT_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)

class SPECTRAL_KPOINTS_LIST(K_LIST):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args, weight=True)


class SPECIES_POT(Cell):
    def __init__(self, cell, cell_lines, active, args):
        super().__init__(cell, cell_lines, active, args)

        self.get_spec_pot()

    def get_spec_pot(self):
        class Pot:
            def __init__(self, element, fil, comment):
                self.element = element
                self.fil     = fil
                self.comment = comment

        self.pots = []
        self.num  = False

        for ln in self.block_lines:
            ln, element = tools.get_string(ln)
            ln, fil     = tools.get_file(ln)
            comment     = tools.get_comment(ln)

            if element and fil:
                self.pots.append(Pot(element, fil, comment))
            else:
                return

        self.num = len(self.pots)

    def check_for_error(self):
        if self.num == 0:
            return False
        elif self.num:
            return False
        else:
            return True

    def get_block(self):
        super().block_initialise()

        elements = tools.get_spaced_column([p.element for p in self.pots], self.args.no_extend_float)
        fils     = tools.get_spaced_column([p.fil     for p in self.pots], self.args.no_extend_float)

        for num, pot in enumerate(self.pots):
            self.block.append(elements[num] + '  ' + fils[num] + ('  ! ' + pot.comment if pot.comment else ''))
            #self.block.append(pot.element + (' ' * ( 4-len(pot.element) )) +\
            #                  pot.fil + (' ' * (2+max_fil_len-len(pot.fil))) +\
            #                  ('! ' + pot.comment if pot.comment else ''))

        super().block_finalise()



