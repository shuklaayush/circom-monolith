pragma circom 2.1.6;

include "../../circuits/constants.circom";
include "../../circuits/monolith.circom";

template MonolithTest() {
    signal input in;
    signal output out;

    // Dummy input/output
    in === 1;
    out <== 1;

    component monolith = Monolith();
    monolith.stateIn <== [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    if (LOOKUP_BITS() == 8) {
        monolith.stateOut === [
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
    } else if (LOOKUP_BITS() == 16) {
        monolith.stateOut === [
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