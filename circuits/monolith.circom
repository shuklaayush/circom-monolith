pragma circom 2.1.6;
include "./goldilocks.circom";
include "./constants.circom";

// TODO: Use optimized monolith_mds_12 for goldilocks
template concrete(round) {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    for (var row = 0; row < SPONGE_WIDTH(); row++) {
        var acc = ROUND_CONSTANTS(round, row);
        for (var column = 0; column < SPONGE_WIDTH(); column++) {
            acc += stateIn[column] * MAT_12(row, column);
        }
        stateOut[row] <== GlReduce(64)(acc);
    }
}

template Num2BitArrays(nLimbs, nBits) {
    signal input in;
    signal output out[nLimbs][nBits];
    var lc1 = 0;
    var e2 = 1;
    for (var i = 0; i < nLimbs; i++) {
        for (var j = 0; j < nBits; j++) {
            out[i][j] <-- (in >> (nBits*i + j)) & 1;
            out[i][j] * (1 - out[i][j]) === 0;
            lc1 += out[i][j] * e2;
            e2 = e2 + e2;
        }
    }

    lc1 === in;
}

template BitArrays2Num(nLimbs, nBits) {
    signal input in[nLimbs][nBits];
    signal output out;
    var lc1 = 0;
    var e2 = 1;
    for (var i = 0; i < nLimbs; i++) {
        for (var j = 0; j < nBits; j++) {
            lc1 += in[i][j] * e2;
            e2 = e2 + e2;
        }
    }

    out <== lc1;
}

template NegateBitArrays(nLimbs, nBits) {
    signal input in[nLimbs][nBits];
    signal output out[nLimbs][nBits];
    for (var i = 0; i < nLimbs; i++) {
        for (var j = 0; j < nBits; j++) {
            out[i][j] <== 1 - in[i][j];
        }
    }
}

template RotateBitArrayLeft(nBits, k) {
    signal input in[nBits];
    signal output out[nBits];
    for (var i = 0; i < nBits; i++) {
        out[i] <== in[(i - k + nBits) % nBits];
    }
}

template RotateBitArraysLeft(nLimbs,nBits, k) {
    signal input in[nLimbs][nBits];
    signal output out[nLimbs][nBits];
    for (var i = 0; i < nLimbs; i++) {
        out[i] <== RotateBitArrayLeft(nBits, k)(in[i]);
    }
}

template AND3BitArrays(nLimbs, nBits) {
    // Assumes all are bit-arrays
    signal input in1[nLimbs][nBits];
    signal input in2[nLimbs][nBits];
    signal input in3[nLimbs][nBits];
    signal output out[nLimbs][nBits];

    signal tmp[nLimbs][nBits];
    for (var i = 0; i < nLimbs; i++) {
        for (var j = 0; j < nBits; j++) {
            tmp[i][j] <== in1[i][j] * in2[i][j];
            out[i][j] <== tmp[i][j] * in3[i][j];
        }
    }
}

template XORBitArrays(nLimbs, nBits) {
    // Assumes both are bit-arrays
    signal input in1[nLimbs][nBits];
    signal input in2[nLimbs][nBits];
    signal output out[nLimbs][nBits];
    for (var i = 0; i < nLimbs; i++) {
        for (var j = 0; j < nBits; j++) {
            out[i][j] <== in1[i][j] + in2[i][j] - 2 * in1[i][j] * in2[i][j];
        }
    }
}

template bar() {
    signal input limbIn; // 64-bit input
    signal output limbOut;

    if (LOOKUP_BITS() == 8) {
        signal limbInBitArrays[8][8] <== Num2BitArrays(8, 8)(limbIn);
        signal limbInBitArraysNeg[8][8] <== NegateBitArrays(8, 8)(limbInBitArrays);

        signal limbInNegRot1[8][8] <== RotateBitArraysLeft(8, 8, 1)(limbInBitArraysNeg);
        signal limbInRot2[8][8] <== RotateBitArraysLeft(8, 8, 2)(limbInBitArrays);
        signal limbInRot3[8][8] <== RotateBitArraysLeft(8, 8, 3)(limbInBitArrays);

        signal tmp1[8][8] <== AND3BitArrays(8, 8)(limbInNegRot1, limbInRot2, limbInRot3);
        signal tmp2[8][8] <== XORBitArrays(8, 8)(limbInBitArrays, tmp1);

        signal limbOutBitArrays[8][8] <== RotateBitArraysLeft(8, 8, 1)(tmp2);
        limbOut <== BitArrays2Num(8, 8)(limbOutBitArrays);
    } else if (LOOKUP_BITS() == 16) {
        signal limbInBitArrays[4][16] <== Num2BitArrays(4, 16)(limbIn);
        signal limbInBitArraysNeg[4][16] <== NegateBitArrays(4, 16)(limbInBitArrays);

        signal limbInNegRot1[4][16] <== RotateBitArraysLeft(4, 16, 1)(limbInBitArraysNeg);
        signal limbInRot2[4][16] <== RotateBitArraysLeft(4, 16, 2)(limbInBitArrays);
        signal limbInRot3[4][16] <== RotateBitArraysLeft(4, 16, 3)(limbInBitArrays);

        signal tmp1[4][16] <== AND3BitArrays(4, 16)(limbInNegRot1, limbInRot2, limbInRot3);
        signal tmp2[4][16] <== XORBitArrays(4, 16)(limbInBitArrays, tmp1);

        signal limbOutBitArrays[4][16] <== RotateBitArraysLeft(4, 16, 1)(tmp2);
        limbOut <== BitArrays2Num(4, 16)(limbOutBitArrays);
    } else {
        assert(0);
    }
}

template bars() {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    for (var row = 0; row < SPONGE_WIDTH(); row++) {
        if (row < N_BARS()) {
            stateOut[row] <== bar()(stateIn[row]);
        } else {
            stateOut[row] <== stateIn[row];
        }
    }
}

template bricks() {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    stateOut[0] <== stateIn[0];
    for (var i = 1; i < SPONGE_WIDTH(); i++) {
        var tmp = GlMul()(stateIn[i - 1], stateIn[i - 1]);
        stateOut[i] <== stateIn[i] + tmp;
    }
}

template logBytes() {
    signal input in[8];
    log(in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]);
}

template logState() {
    signal input in[12];
    log(in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7], in[8], in[9], in[10], in[11]);
}

// TODO: Rename to monolith goldilocks
template Monolith() {
    signal input stateIn[SPONGE_WIDTH()];
    signal output stateOut[SPONGE_WIDTH()];

    signal tmp[N_ROUNDS() + 1][3][SPONGE_WIDTH()];

    tmp[0][2] <== concrete(0)(stateIn);
    for (var rc = 1; rc < N_ROUNDS() + 1; rc++) {
        tmp[rc][0] <== bars()(tmp[rc-1][2]);
        tmp[rc][1] <== bricks()(tmp[rc][0]);
        tmp[rc][2] <== concrete(rc)(tmp[rc][1]);
    }

    stateOut <== tmp[N_ROUNDS()][2];
}
