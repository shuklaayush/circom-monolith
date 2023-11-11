pragma circom 2.0.6;
include "./goldilocks.circom";
include "./constants.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template MDS_GL() {
    signal input in[12];
    signal output out[12];
    component reduce[12];
    for (var i = 0; i < 12; i++) {
        reduce[i] = GlReduce(74);
    }

    reduce[ 0].x <== 25*in[0] + 15*in[1] + 41*in[2] + 16*in[3] +  2*in[4] + 28*in[5] + 13*in[6] + 13*in[7] + 39*in[8] + 18*in[9] + 34*in[10] + 20*in[11];
    reduce[ 1].x <== 20*in[0] + 17*in[1] + 15*in[2] + 41*in[3] + 16*in[4] +  2*in[5] + 28*in[6] + 13*in[7] + 13*in[8] + 39*in[9] + 18*in[10] + 34*in[11];
    reduce[ 2].x <== 34*in[0] + 20*in[1] + 17*in[2] + 15*in[3] + 41*in[4] + 16*in[5] +  2*in[6] + 28*in[7] + 13*in[8] + 13*in[9] + 39*in[10] + 18*in[11];
    reduce[ 3].x <== 18*in[0] + 34*in[1] + 20*in[2] + 17*in[3] + 15*in[4] + 41*in[5] + 16*in[6] +  2*in[7] + 28*in[8] + 13*in[9] + 13*in[10] + 39*in[11];
    reduce[ 4].x <== 39*in[0] + 18*in[1] + 34*in[2] + 20*in[3] + 17*in[4] + 15*in[5] + 41*in[6] + 16*in[7] +  2*in[8] + 28*in[9] + 13*in[10] + 13*in[11];
    reduce[ 5].x <== 13*in[0] + 39*in[1] + 18*in[2] + 34*in[3] + 20*in[4] + 17*in[5] + 15*in[6] + 41*in[7] + 16*in[8] +  2*in[9] + 28*in[10] + 13*in[11];
    reduce[ 6].x <== 13*in[0] + 13*in[1] + 39*in[2] + 18*in[3] + 34*in[4] + 20*in[5] + 17*in[6] + 15*in[7] + 41*in[8] + 16*in[9] +  2*in[10] + 28*in[11];
    reduce[ 7].x <== 28*in[0] + 13*in[1] + 13*in[2] + 39*in[3] + 18*in[4] + 34*in[5] + 20*in[6] + 17*in[7] + 15*in[8] + 41*in[9] + 16*in[10] +  2*in[11];
    reduce[ 8].x <==  2*in[0] + 28*in[1] + 13*in[2] + 13*in[3] + 39*in[4] + 18*in[5] + 34*in[6] + 20*in[7] + 17*in[8] + 15*in[9] + 41*in[10] + 16*in[11];
    reduce[ 9].x <== 16*in[0] +  2*in[1] + 28*in[2] + 13*in[3] + 13*in[4] + 39*in[5] + 18*in[6] + 34*in[7] + 20*in[8] + 17*in[9] + 15*in[10] + 41*in[11];
    reduce[10].x <== 41*in[0] + 16*in[1] +  2*in[2] + 28*in[3] + 13*in[4] + 13*in[5] + 39*in[6] + 18*in[7] + 34*in[8] + 20*in[9] + 17*in[10] + 15*in[11];
    reduce[11].x <== 15*in[0] + 41*in[1] + 16*in[2] +  2*in[3] + 28*in[4] + 13*in[5] + 13*in[6] + 39*in[7] + 18*in[8] + 34*in[9] + 20*in[10] + 17*in[11];

    for (var i = 0; i < 12; i++) {
        out[i] <== reduce[i].out;
    }
}

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
