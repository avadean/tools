#! /usr/bin/python3.7

import sys
import numpy as np

class System:
    def __init__(self, outgeomfile, castepfile):
        self.charges = []
        self.list_particles = []
        self.get_lattice_and_particles_and_charges(outgeomfile)
        self.update_charges(castepfile)
        self.CoM = self.get_CoM()
        self.get_rel_coords()
        self.get_weighted_coords()
        self.get_dipole_moment()

    def get_lattice_and_particles_and_charges(self, outgeomfile):
        with open(outgeomfile) as f:
            self.geom = f.readlines()
        self.geom = [i.strip() for i in self.geom]

        for i in range(len(self.geom)):
            if "%BLOCK lattice_cart" in self.geom[i]:
                j=i+1
                exit=False
                while "%ENDBLOCK lattice_cart" not in self.geom[j] and not exit:
                    if "ANG" not in self.geom[j]:
                        list_1 = self.geom[j].split()
                        list_2 = self.geom[j+1].split()
                        list_3 = self.geom[j+2].split()
                        self.np_lattice = np.array(([list_1, list_2, list_3]), dtype=float)
                        exit=True
                    j+=1

            if "%BLOCK positions_frac" in self.geom[i]:
                j=i+1
                while "%ENDBLOCK positions_frac" not in self.geom[j]:
                    particle_info = self.geom[j].split()
                    self.list_particles.append(Particle(particle_info[0], float(particle_info[1]), float(particle_info[2]), float(particle_info[3])))
                    j+=1

        self.N = len(self.list_particles)
        self.update_coords()

    def update_coords(self):
        for i in range(self.N):
            self.list_particles[i].update_coords(self.np_lattice)

    def update_charges(self, castepfile):
        with open(castepfile) as f:
            self.charg = f.readlines()
        self.charg = [i.strip() for i in self.charg]

        for i in range(len(self.charg)):
            if "Atomic Populations (Mulliken)" in self.charg[i]:
                for j in range(i+4, i+4+self.N):
                    self.charges.append(self.charg[j].split()[-1])

        for i in range(self.N):
            self.list_particles[i].charge = float(self.charges[i])

    def get_CoM(self):
        self.mass=self.CoM=0.0
        for i in range(self.N):
            self.CoM+=self.list_particles[i].coords * self.list_particles[i].mass
            self.mass+=self.list_particles[i].mass
        return self.CoM / self.mass

    def get_rel_coords(self):
        for i in range(self.N):
            self.list_particles[i].rel_coords = np.array(self.list_particles[i].coords - self.CoM, dtype=float)

    def get_weighted_coords(self):
        for i in range(self.N):
            self.list_particles[i].weighted_coords = self.list_particles[i].rel_coords * self.list_particles[i].charge

    def get_dipole_moment(self):
        self.dipole_vector = np.zeros(3)
        for i in range(self.N):
            self.dipole_vector+=self.list_particles[i].weighted_coords
        self.dipole = np.linalg.norm(self.dipole_vector) / 0.20819434 # Conversion to Debye.



class Particle:
    def __init__(self, atom, frac_x, frac_y, frac_z):
        self.atom = atom
        self.frac_x = frac_x
        self.frac_y = frac_y
        self.frac_z = frac_z
        self.mass = { 'H' : 1.00784,
                      'C' : 12.0107,
                      'O' : 15.999,
                      'N' : 14.0067}[self.atom]
        self.charge = 0.0
        self.coords = np.zeros(3)
        self.rel_coords = np.zeros(3)
        self.weighted_coords = np.zeros(3)

    def update_coords(self, np_lattice):
        self.coords = np_lattice.dot(np.array([self.frac_x, self.frac_y, self.frac_z]))





geomfile = sys.argv[1]
castepfile = sys.argv[2]

system = System(geomfile, castepfile)
print(system.dipole)

