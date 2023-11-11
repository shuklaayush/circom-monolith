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

template Num2ByteArray(n) {
    signal input in;
    signal output out[n][8];
    var lc1 = 0;
    var e2 = 1;
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < 8; j++) {
            out[i][j] <-- (in >> (8*i + j)) & 1;
            out[i][j] * (1 - out[i][j]) === 0;
            lc1 += out[i][j] * e2;
            e2 = e2 + e2;
        }
    }

    lc1 === in;
}

template ByteArray2Num(n) {
    signal input in[n][8];
    signal output out;
    var lc1 = 0;
    var e2 = 1;
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < 8; j++) {
            lc1 += in[i][j] * e2;
            e2 = e2 + e2;
        }
    }

    out <== lc1;
}

template NegateByteArray(n) {
    signal input in[n][8];
    signal output out[n][8];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < 8; j++) {
            out[i][j] <== 1 - in[i][j];
        }
    }
}

template RotateByteLeft(k) {
    signal input in[8];
    signal output out[8];
    for (var i = 0; i < 8; i++) {
        out[i] <== in[(i - k + 8) % 8];
    }
}

template RotateByteArrayLeft(n, k) {
    signal input in[n][8];
    signal output out[n][8];
    for (var i = 0; i < n; i++) {
        out[i] <== RotateByteLeft(k)(in[i]);
    }
}

template AND3ByteArrays(n) {
    // Assumes all are bit-arrays
    signal input in1[n][8];
    signal input in2[n][8];
    signal input in3[n][8];
    signal output out[n][8];

    signal tmp[n][8];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < 8; j++) {
            tmp[i][j] <== in1[i][j] * in2[i][j];
            out[i][j] <== tmp[i][j] * in3[i][j];
        }
    }
}

template XORByteArrays(n) {
    // Assumes both are bit-arrays
    signal input in1[n][8];
    signal input in2[n][8];
    signal output out[n][8];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < 8; j++) {
            out[i][j] <== in1[i][j] + in2[i][j] - 2 * in1[i][j] * in2[i][j];
        }
    }
}

template bar() {
    signal input limbIn; // 64-bit input
    signal output limbOut;

    if (LOOKUP_BITS() == 8) {
        signal limbInBytes[8][8] <== Num2ByteArray(8)(limbIn);
        signal limbInBytesNeg[8][8] <== NegateByteArray(8)(limbInBytes);

        signal limbInNegRot1[8][8] <== RotateByteArrayLeft(8, 1)(limbInBytesNeg);
        signal limbInRot2[8][8] <== RotateByteArrayLeft(8, 2)(limbInBytes);
        signal limbInRot3[8][8] <== RotateByteArrayLeft(8, 3)(limbInBytes);

        signal tmp1[8][8] <== AND3ByteArrays(8)(limbInNegRot1, limbInRot2, limbInRot3);
        signal tmp2[8][8] <== XORByteArrays(8)(limbInBytes, tmp1);

        signal limbOutBytes[8][8] <== RotateByteArrayLeft(8, 1)(tmp2);
        limbOut <== ByteArray2Num(8)(limbOutBytes);
    } else if (LOOKUP_BITS() == 16) {
        // TODO
        assert(0);

        // let limbl1 =
        //     ((!limb & 0x8000800080008000) >> 15) | ((!limb & 0x7FFF7FFF7FFF7FFF) << 1); // Left rotation by 1
        // let limbl2 =
        //     ((limb & 0xC000C000C000C000) >> 14) | ((limb & 0x3FFF3FFF3FFF3FFF) << 2); // Left rotation by 2
        // let limbl3 =
        //     ((limb & 0xE000E000E000E000) >> 13) | ((limb & 0x1FFF1FFF1FFF1FFF) << 3); // Left rotation by 3

        // // y_i = x_i + (1 + x_{i+1}) * x_{i+2} * x_{i+3}
        // let tmp = limb ^ limbl1 & limbl2 & limbl3;
        // ((tmp & 0x8000800080008000) >> 15) | ((tmp & 0x7FFF7FFF7FFF7FFF) << 1)
        // // Final rotation
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
