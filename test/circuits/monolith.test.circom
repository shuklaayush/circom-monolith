pragma circom 2.1.6;

include "../../circuits/constants.circom";
include "../../circuits/monolith.circom";

template MonolithTest() {
    signal input in;
    signal output out;

    // Dummy input/output
    in === 1;
    out <== 1;

    if (LOOKUP_BITS() == 8) {
        component monolith = Monolith();
        monolith.in <== [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
        monolith.out === [
            5867581605548782913,
            588867029099903233,
            6043817495575026667,
            805786589926590032,
            9919982299747097782,
            6718641691835914685,
            7951881005429661950,
            15453177927755089358,
            974633365445157727,
            9654662171963364206,
            6281307445101925412,
            13745376999934453119
        ];

        component hashNoPad = HashNoPad(20);
        for (var i = 0; i < 20; i++) {
            hashNoPad.in[i] <== i;
        }
        hashNoPad.out[0] === 8996128650757811998;
        hashNoPad.out[1] === 12880985024432515815;
        hashNoPad.out[2] === 3454345201888921593;
        hashNoPad.out[3] === 18389931647560656493;

        component twoToOne = TwoToOne();
        twoToOne.left <== [
            5578432682130415841,
            17984826319860468265,
            2977584103897394617,
            5110399557104769054
        ];
        twoToOne.right <== [
            15607844769443632556,
            11898110123231206647,
            4706907245069888922,
            18370926738804976449
        ];
        twoToOne.out[0] === 17681331911885733250;
        twoToOne.out[1] === 14066725269898914213;
        twoToOne.out[2] === 163313156297651991;
        twoToOne.out[3] === 116953707891782130;

    } else if (LOOKUP_BITS() == 16) {
        component monolith = Monolith();
        monolith.in <== [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
        monolith.out === [
            15270549627416999494,
            2608801733076195295,
            2511564300649802419,
            14351608014180687564,
            4101801939676807387,
            234091379199311770,
            3560400203616478913,
            17913168886441793528,
            7247432905090441163,
            667535998170608897,
            5848119428178849609,
            7505720212650520546
        ];
    } else {
        assert(0);
    }
}

component main = MonolithTest();
