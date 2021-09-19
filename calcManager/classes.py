#! /usr/bin/python3.7


class Kpoint:
    def __init__(self, x, y, z, weight, comment):
        self.x       = x
        self.y       = y
        self.z       = z
        self.weight  = weight
        self.comment = comment

class ThreeVector:
    def __init__(self, x, y, z, comment):
        self.x       = x
        self.y       = y
        self.z       = z
        self.comment = comment

class ThreeMatrix:
    def __init__(self, xx, xy, xz, yx, yy, yz, zx, zy, zz, comments):
        self.xx, self.xy, self.xz = xx, xy, xz
        self.yx, self.yy, self.yz = yx, yy, yz
        self.zx, self.zy, self.zz = zx, zy, zz
        self.comments             = comments
        #self.determinant          = self.get_determinant()

    #def get_determinant(self):
    #    return self.xx * ( self.yy * self.zz - self.yz * self.zy ) -\
    #           self.xy * ( self.yx * self.zz - self.yz * self.zx ) +\
    #           self.xz * ( self.yx * self.zy - self.yy * self.zx )


