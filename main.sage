load("test_pairing.sage")
load("global_parameters.sage")
load("r1cs_qap.sage")

def setup(k, apoly, bpoly, cpoly, n, T):
    random_variables = [FF.random_element() for _ in range(5)]
    tau, alpha, beta, gamma, delta = random_variables

    k_vk, k_pk, z_t = [], [], []
    apoly1, bpoly1, bpoly2 = [], [], []
    for i in range(0, n):
        apoly1.append(multiply(G1, int(PR_k(apoly[i].list())(tau))))
        bpoly1.append(multiply(G1, int(PR_k(bpoly[i].list())(tau))))
        bpoly2.append(multiply(G2, int(PR_k(bpoly[i].list())(tau))))
        a_it = beta * PR_k(apoly[i].list())(tau)
        b_it = alpha * PR_k(bpoly[i].list())(tau)
        c_it = PR_k(cpoly[i].list())(tau)
        if i <= k:
            k_vki = 1/gamma * (beta * a_it + alpha * b_it + c_it)
            k_vk.append(multiply(G1, int(k_vki)))
        else:
            k_pki = 1/delta * (beta * a_it + alpha * b_it + c_it)
            k_pk.append(multiply(G1, int(k_pki)))

    for j in range(0, T.degree() - 1):
        z_t.append(multiply(G1, int(1/delta * tau^j * T(tau))))
    print(f"setup function:\n z_t length == {len(z_t)}")
    print(f"setup function:\n z_t == {z_t}")
    prover_key = []
    verifier_key = []

    alpha, beta, gamma, delta = int(alpha), int(beta), int(gamma), int(delta)

    alpha1 = multiply(G1, alpha)
    beta1 = multiply(G1, beta)
    beta2 = multiply(G2, beta)
    delta1 = multiply(G1, delta)
    delta2 = multiply(G2, delta)
    gamma2 = multiply(G2, gamma)

    prover_key.append([alpha1, beta1, beta2, delta1, delta2])
    prover_key.append(apoly1)
    prover_key.append(bpoly1)
    prover_key.append(bpoly2)
    prover_key.append(k_pk)
    prover_key.append(z_t)

    verifier_key.append(pairing(beta2, alpha1))
    verifier_key.append(gamma2)
    verifier_key.append(delta2)
    verifier_key.append(k_vk)

    return prover_key, verifier_key


def prover(prover_key, input, witness, h):
    r, s = int(FF.random_element()), int(FF.random_element())
    alpha1, beta1, beta2, delta1, delta2 = prover_key[0]
    apoly1 = prover_key[1]
    bpoly1 = prover_key[2]
    bpoly2 = prover_key[3]
    k_pk = prover_key[4]
    z_t = prover_key[5]


    rd1 = multiply(delta1, r)
    sd1, sd2 = multiply(delta1, s), multiply(delta2, s)
    ar1 = add(alpha1, rd1)
    bs1 = add(beta1, sd1)
    bs2 = add(beta2, sd2)

    z = [1] + input + witness
    k = len(input)
    for i in range(len(apoly1)):
        ar1 = add(ar1, multiply(apoly1[i], int(z[i])))
        bs1 = add(bs1, multiply(bpoly1[i], int(z[i])))
        bs2 = add(bs2, multiply(bpoly2[i], int(z[i])))

    krs1 = multiply(ar1, s)
    krs1 = add(krs1, multiply(bs1, r))
    rsd1 = multiply(sd1, r)
    krs1 = add(krs1, neg(rsd1))

    print(f"prover function:\n z_t == {z_t}")
    print(f"prover function:\n h == {h}")
    for i in range(len(k_pk)):
        krs1 = add(krs1, multiply(k_pk[i], int(witness[i])))
    for i in range(len(z_t)):
        krs1 = add(krs1, multiply(z_t[i], int(h[i])))
    return [ar1, bs2, krs1]


def verifier(verifier_key, proof, input):
    input = [1] + input
    input = [int(elem) for elem in input]
    print(f"verifier function:\n input == {input}")
    ab_pairing, gamma2, delta2, k_vk = verifier_key
    ar1, bs2, krs1 = proof
    p1 = pairing(bs2, ar1)
    p2 = ab_pairing

    kx_sum = multiply(k_vk[0], input[0])
    assert(len(input) == len(k_vk))
    for i in range(1, len(k_vk)):
        kx_sum = add(kx_sum, multiply(k_vk[i], input[i]))
    p2 += pairing(gamma2, kx_sum)
    p2 += pairing(delta2, krs1)
    print(f"p1 == {p1}")
    print(f"p2 == {p2}")
    return p1 == p2


def main():
    L = Matrix(FF, [[0, 0, 1, 0, 0, 0, 0, 0], [0, 0, 0, 1, 0, 0, 0, 0], [0, 0, 5, 0, 0, 0, 0, 0], [0, 0, 0, 0, 4, 0, 0, 0], [0, 0, 13, 0, 0, 0, 0, 0]])
    R = Matrix(FF, [[0, 0, 1, 0, 0, 0, 0, 0], [0, 0, 0, 1, 0, 0, 0, 0], [0, 0, 0, 0, 1, 0, 0, 0], [0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 1, 0, 0]])
    O = Matrix(FF, [[0, 0, 0, 0, 1, 0, 0, 0], [0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 0, 0, 0, 1], [0, 1, 0, 10, -1, 0, -1, 1]])

    x = FF(2)
    y = FF(3)
    v1 = x * x
    v2 = y * y
    v3 = 5 * x * v1
    v4 = 4 * v1 * v2
    out = 5*x**3 - 4*x**2*y**2 + 13*x*y**2 + x**2 - 10*y
    input = [out]
    witness = [x, y, v1, v2, v3, v4]
    z = vector(FF, [1] + input + witness)
    Lp, Rp, Op, T, h = qap_instance(L, R, O, z)
    k = len(input)
    pk, vk = setup(k, Lp, Rp, Op, Lp.nrows(), T)
    proof = prover(pk, input, witness, h)
    res = verifier(vk, proof, input)
    print(res)


if __name__ == "__main__":
    main()
