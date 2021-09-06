#!/usr/bin/sage
# vim: syntv2x=python

import sys
try:
    from sagelib.common import CMOV
    from sagelib.generic_map import GenericMap
    from sagelib.z_selection import find_z_sswu
    from sagelib.sqrt import sqrt_checked, sqrt_ratio_straightline
except ImportError:
    sys.exit("Error loading preprocessed sage files. Try running `make clean pyfiles`")

# Arguments:
# - F, a field object, e.g., F = GF(2^521 - 1)
def find_S_sswu(F):
    S = F.primitive_element()
    return S

class OptimizedSSWU(GenericMap):
    def __init__(self, F, A, B):
        self.name = "SSWU"
        self.F = F
        self.A = F(A)
        self.B = F(B)

        if self.A == 0:
            raise ValueError("S-SWU requires A != 0")
        if self.B == 0:
            raise ValueError("S-SWU requires B != 0")
        self.Z = find_z_sswu(F, F(A), F(B))
        self.S = find_S_sswu(F)
        self.E = EllipticCurve(F, [F(A), F(B)])

        # constants for straight-line impl
        self.c2 = -F(1) / self.Z
        self.c1 = self.sqrt(self.Z / self.S)

        # values at which the map is undefined
        # i.e., when Z^2 * u^4 + Z * u^2 = 0
        # which is at u = 0 and when Z * u^2 = -1
        self.undefs = [F(0)]
        if self.c2.is_square():
            ex = self.c2.sqrt()
            self.undefs += [ex, -ex]

    def not_straight_line(self, u):
        inv0 = self.inv0
        is_square = self.is_square
        sgn0 = self.sgn0
        sqrt = self.sqrt
        u = self.F(u)
        A = self.A
        B = self.B
        Z = self.Z

        tv1 = inv0(Z^2 * u^4 + Z * u^2)
        x1 = (-B / A) * (1 + tv1)
        if tv1 == 0:
            x1 = B / (Z * A)
        gx1 = x1^3 + A * x1 + B
        x2 = Z * u^2 * x1
        gx2 = x2^3 + A * x2 + B
        if is_square(gx1):
            x = x1
            y = sqrt(gx1)
        else:
            x = x2
            y = sqrt(gx2)
        if sgn0(u) != sgn0(y):
            y = -y
        return (x, y)

    def sqrt_ratio(self, u, v):
        x = self.F(u) / self.F(v)
        r1 = sqrt_checked(self.F, x)
        r2 = sqrt_ratio_straightline(self.F, u, v)
        assert r1 == r2
        return r2

    def straight_line(self, u):
        A = self.A
        B = self.B
        Z = self.Z
        u = self.F(u)
        c1 = self.c1

        tv1 = u^2
        tv1 = Z * tv1
        tv2 = tv1^2
        tv2 = tv2 + tv1
        tv3 = tv2 + 1
        tv3 = B * tv3
        tv4 = CMOV(Z, -tv2, tv2 != 0)
        tv4 = A * tv4
        tv2 = tv3^2
        tv5 = tv4^2
        tv5 = A * tv5
        tv2 = tv2 + tv5
        tv2 = tv2 * tv3
        tv6 = tv4^3
        tv5 = B * tv6
        tv2 = tv2 + tv5
        x = tv1 * tv3
        (is_gx1_square, y1) = self.sqrt_ratio(tv2, tv6)
        y = c3 * tv1 
        y = y * u
        y = y * y1
        x = CMOV(x, tv3, is_gx1_square)
        y = CMOV(y, y1, is_gx1_square)
        u_parity = mod(u, self.F(2))
        y_parity = mod(y, self.F(2))
        y = CMOV(-y, y, u_parity == y_parity)
        x = x / tv4

        return (x, y)

if __name__ == "__main__":
    for _ in range(0, 32):
        OptimizedSSWU.test_random()
