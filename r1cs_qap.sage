def matrix_to_polynomials(matrix, FF):
    row, col = matrix.nrows(), matrix.ncols()
    poly_list = []
    for i in range(col):
        points = []
        for j in range(row):
            x = FF(j+1)
            y = matrix[j][i]
            points.append((x, y))
        poly = PR_k.lagrange_polynomial(points)
        coefs = poly.list()[::-1]
        if len(coefs) < row:
            coefs = [0] * (row - len(coefs)) + coefs
        poly_list.append(coefs[::-1])
    return Matrix(FF, poly_list)


def create_zd(ncols): return [i for i in range(1, ncols+1)]


def create_target_polynomial(Z_d):
    T = (k - Z_d[0])
    for j in range(1, len(Z_d)):
        T *= (k - Z_d[j])
    return T


def create_vanishing_polynomial(U, V, W, Z_d):
    T = create_target_polynomial(Z_d)
    h = (U * V - W) // T
    return h.list()


def test_vanishing_polynomial(U, V, W, T, h):
    h = PR_k(h)
    for i in range(1, 100):
        tau = FF.random_element()
        assert(U * V == W + h * T)
    print("GOOOOL")


def qap_instance(L, R, O, w):
    Lw = L * w
    Rw = R * w
    Ow = O * w

    LRw = Lw.pairwise_product(Rw)

    Lp = matrix_to_polynomials(L, FF)
    Rp = matrix_to_polynomials(R, FF)
    Op = matrix_to_polynomials(O, FF)

    A = PR_k((w * Lp).list())
    B = PR_k((w * Rp).list())
    C = PR_k((w * Op).list())

    Z_d = create_zd(L.ncols())
    T = create_target_polynomial(Z_d)
    h = create_vanishing_polynomial(A, B, C, Z_d)
    return Lp, Rp, Op, T, h

