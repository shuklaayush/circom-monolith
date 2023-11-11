pragma circom 2.0.6;
include "./goldilocks.circom";
include "./constants.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template concrete(round) {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    for row in 0..SPONGE_WIDTH() {
        for column in 0..SPONGE_WIDTH() {
            stateOut[row] += stateIn[column] * MAT_12()[row][column]; // TODO: goldilocks mul
        }
        stateOut[row] += ROUND_CONSTANTS()[round][row]; // TODO: goldilocks add
    }
}

template bar() {
    signal input elIn
    signal output elOut;

// TODO
//    let limb = *el as u64;
//    *el = match LOOKUP_BITS {
//        8 => {
//            let limbl1 =
//                ((!limb & 0x8080808080808080) >> 7) | ((!limb & 0x7F7F7F7F7F7F7F7F) << 1); // Left rotation by 1
//            let limbl2 =
//                ((limb & 0xC0C0C0C0C0C0C0C0) >> 6) | ((limb & 0x3F3F3F3F3F3F3F3F) << 2); // Left rotation by 2
//            let limbl3 =
//                ((limb & 0xE0E0E0E0E0E0E0E0) >> 5) | ((limb & 0x1F1F1F1F1F1F1F1F) << 3); // Left rotation by 3
//
//            // y_i = x_i + (1 + x_{i+1}) * x_{i+2} * x_{i+3}
//            let tmp = limb ^ limbl1 & limbl2 & limbl3;
//            ((tmp & 0x8080808080808080) >> 7) | ((tmp & 0x7F7F7F7F7F7F7F7F) << 1)
//        }
//        16 => {
//            let limbl1 =
//                ((!limb & 0x8000800080008000) >> 15) | ((!limb & 0x7FFF7FFF7FFF7FFF) << 1); // Left rotation by 1
//            let limbl2 =
//                ((limb & 0xC000C000C000C000) >> 14) | ((limb & 0x3FFF3FFF3FFF3FFF) << 2); // Left rotation by 2
//            let limbl3 =
//                ((limb & 0xE000E000E000E000) >> 13) | ((limb & 0x1FFF1FFF1FFF1FFF) << 3); // Left rotation by 3
//
//            // y_i = x_i + (1 + x_{i+1}) * x_{i+2} * x_{i+3}
//            let tmp = limb ^ limbl1 & limbl2 & limbl3;
//            ((tmp & 0x8000800080008000) >> 15) | ((tmp & 0x7FFF7FFF7FFF7FFF) << 1)
//            // Final rotation
//        }
//        _ => {
//            panic!("Unsupported lookup size");
//        }
//    } as u128;
}

template bars() {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    for row in 0..N_BARS() {
        stateOut[row] <== bar()(stateIn[row]);
    }
}

template bricks() {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    for iRev in 1..SPONGE_WIDTH() {
        var i = SPONGE_WIDTH() - iRev;
        var prev = state[i - 1];
        stateOut[i] <== prev * prev
    }
}

template Monolith() {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    signal tmp[N_ROUNDS][3][SPONGE_WIDTH()];

    tmp[0][2] <== concrete()(stateIn);
    for rc in 1..N_ROUNDS() {
        tmp[rc][0] <== concrete(rc)(tmp[rc-1][2]);
        tmp[rc][1] <== bars()(tmp[rc][0]);
        tmp[rc][2] <== bricks()(tmp[rc][1]);
    }

    stateOut <== tmp[N_ROUNDS() - 1][2];
}


// fn hash_no_pad(input: &[F]) -> Self::Hash {
//     hash_n_to_hash_no_pad::<F, Self::Permutation>(input)
// }
//
// fn two_to_one(left: Self::Hash, right: Self::Hash) -> Self::Hash {
//     compress::<F, Self::Permutation>(left, right)
// }

template Poseidon_GL(nOuts) {
    signal input in[8];
    signal input capacity[4];
    signal output out[nOuts];

    signal state[31][12];
    component f1_x2[4][12];
    component f1_x4[4][12];
    component f1_x6[4][12];

    component p_x2[22];
    component p_x4[22];
    component p_x6[22];

    component f2_x2[4][12];
    component f2_x4[4][12];
    component f2_x6[4][12];

    component mds[30];

    for (var j=0; j<8; j++) {
        state[0][j] <== in[j];
    }
    for (var j=0; j<4; j++) {
        state[0][8+j] <== capacity[j];
    }

    for (var i=0; i<4; i++) {
        mds[i] = MDS_GL();
        for (var j=0; j<12; j++) {
            var c = GL_CONST(i*12+j);
            f1_x2[i][j] = GlReduce(66);
            f1_x4[i][j] = GlReduce(66);
            f1_x6[i][j] = GlReduce(66);
            f1_x2[i][j].x <== (state[i][j] + c) * (state[i][j] + c);
            f1_x4[i][j].x <== f1_x2[i][j].out * f1_x2[i][j].out;
            f1_x6[i][j].x <== f1_x2[i][j].out * f1_x4[i][j].out;
            mds[i].in[j] <== (state[i][j] + c) * f1_x6[i][j].out;
        }
        for (var j=0; j<12; j++) {
            state[i+1][j] <== mds[i].out[j];
        }
    }

    for (var i=0; i<22; i++) {
        var c = GL_CONST((4+i)*12);
        mds[4+i] = MDS_GL();
        p_x2[i] = GlReduce(66);
        p_x4[i] = GlReduce(66);
        p_x6[i] = GlReduce(66);
        p_x2[i].x <== (state[4+i][0]+c) * (state[4+i][0]+c);
        p_x4[i].x <== p_x2[i].out * p_x2[i].out;
        p_x6[i].x <== p_x2[i].out * p_x4[i].out;
        mds[4+i].in[0] <== (state[4+i][0]+c) * p_x6[i].out;
        for (var j=1; j<12; j++) {
            var c = GL_CONST((4+i)*12 +j);
            mds[4+i].in[j] <== state[4+i][j] + c;
        }

        for (var j=0; j<12; j++) {
            state[4+i+1][j] <== mds[4+i].out[j];
        }
    }

    for (var i=0; i<4; i++) {
        mds[26+i] = MDS_GL();
        for (var j=0; j<12; j++) {
            var c = GL_CONST((26+i)*12+j);
            f2_x2[i][j] = GlReduce(66);
            f2_x4[i][j] = GlReduce(66);
            f2_x6[i][j] = GlReduce(66);
            f2_x2[i][j].x <== (state[26+i][j]+c) * (state[26+i][j]+c);
            f2_x4[i][j].x <== f2_x2[i][j].out * f2_x2[i][j].out;
            f2_x6[i][j].x <== f2_x2[i][j].out * f2_x4[i][j].out;
            mds[26+i].in[j] <== (state[26+i][j]+c) * f2_x6[i][j].out;
        }
        for (var j=0; j<12; j++) {
            state[26+i+1][j] <== mds[26+i].out[j];
        }
    }

    for (var j=0; j<nOuts; j++) {
        out[j] <== state[30][j];
    }
}

template Poseidon_BN(nOuts) {
    signal input in[8];
    signal input capacity[4];
    signal output out[nOuts];

    assert(nOuts <= 12);
    component pEx = PoseidonEx(4, 4);
    pEx.initialState <== 0;
    pEx.inputs[0] <== in[0] * 2 ** 128 + in[1] * 2 ** 64 + in[2];
    pEx.inputs[1] <== in[3] * 2 ** 128 + in[4] * 2 ** 64 + in[5];
    pEx.inputs[2] <== in[6] * 2 ** 128 + in[7] * 2 ** 64 + capacity[0];
    pEx.inputs[3] <== capacity[1] * 2 ** 128 + capacity[2] * 2 ** 64 + capacity[3];

    component nBits[4];
    signal gl_hashes[12][64];
    var e2;
    for (var i = 0; i < 4; i++) {
      nBits[i] = Num2Bits(254);
      nBits[i].in <== pEx.out[i];
      for (var j = 0; j < 3; j++) {
        gl_hashes[i * 3 + j][0] <== nBits[i].out[(2 - j) * 64];
        e2 = 2;
        for (var k = 1; k < 64; k++) {
          gl_hashes[i * 3 + j][k] <== gl_hashes[i * 3 + j][k - 1] + nBits[i].out[(2 - j) * 64 + k] * e2;
          e2 = e2 + e2;
        }
      }
    }

    for (var i = 0; i < nOuts; i++) {
      out[i] <== gl_hashes[i][63];
    }
}

template HashNoPad_BN(nInputs, nOutputs) {
    signal input in[nInputs];
    signal input capacity[4];
    signal output out[nOutputs];
    assert(nOutputs <= 12);

    var nHash = (nInputs + 7) \ 8;
    component cPoseidon[nHash];
    component tmpHash[nHash][12];

    for (var i = 0; i < nHash; i++) {
        cPoseidon[i] = Poseidon_BN(12);
    }
    cPoseidon[0].capacity[0] <== capacity[0];
    cPoseidon[0].capacity[1] <== capacity[1];
    cPoseidon[0].capacity[2] <== capacity[2];
    cPoseidon[0].capacity[3] <== capacity[3];

    for (var i = 0; i < nHash; i++) {
        for (var j = 0; j < 8; j++) {
            var index = i * 8 + j;
            if (index >= nInputs) {
                if (i > 0) {
                  cPoseidon[i].in[j] <== cPoseidon[i-1].out[j];
                } else {
                  cPoseidon[i].in[j] <== 0;
                }
            } else {
                cPoseidon[i].in[j] <== in[index];
            }
        }
        if (i > 0) {
            cPoseidon[i].capacity[0] <== cPoseidon[i-1].out[8];
            cPoseidon[i].capacity[1] <== cPoseidon[i-1].out[9];
            cPoseidon[i].capacity[2] <== cPoseidon[i-1].out[10];
            cPoseidon[i].capacity[3] <== cPoseidon[i-1].out[11];
        }
    }

    component cGlReduce[nOutputs];
    for (var i = 0; i < nOutputs; i++) {
        cGlReduce[i] = GlReduce(1);
        cGlReduce[i].x <== cPoseidon[nHash - 1].out[i];
        out[i] <== cGlReduce[i].out;
    }
}

template HashNoPad_GL(nInputs, nOutputs) {
    signal input in[nInputs];
    signal input capacity[4];
    signal output out[nOutputs];
    assert(nOutputs <= 12);

    var nHash = (nInputs + 7) \ 8;
    component cPoseidon[nHash];
    component tmpHash[nHash][12];

    for (var i = 0; i < nHash; i++) {
        cPoseidon[i] = Poseidon_GL(12);
    }
    cPoseidon[0].capacity[0] <== capacity[0];
    cPoseidon[0].capacity[1] <== capacity[1];
    cPoseidon[0].capacity[2] <== capacity[2];
    cPoseidon[0].capacity[3] <== capacity[3];

    for (var i = 0; i < nHash; i++) {
        for (var j = 0; j < 8; j++) {
            var index = i * 8 + j;
            if (index >= nInputs) {
                if (i > 0) {
                  cPoseidon[i].in[j] <== cPoseidon[i-1].out[j];
                } else {
                  cPoseidon[i].in[j] <== 0;
                }
            } else {
                cPoseidon[i].in[j] <== in[index];
            }
        }
        if (i > 0) {
            cPoseidon[i].capacity[0] <== cPoseidon[i-1].out[8];
            cPoseidon[i].capacity[1] <== cPoseidon[i-1].out[9];
            cPoseidon[i].capacity[2] <== cPoseidon[i-1].out[10];
            cPoseidon[i].capacity[3] <== cPoseidon[i-1].out[11];
        }
    }

    for (var i = 0; i < nOutputs; i++) {
        out[i] <== cPoseidon[nHash - 1].out[i];
    }
}
