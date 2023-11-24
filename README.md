# circom-monolith

This repository contains a circom implementation of the [Monolith](https://eprint.iacr.org/2023/1025) hash function over the Goldilocks prime field $\mathbb{F}_p$ where $p = 2^{64} - 2^{32} + 1$.

[Open in zkREPL](https://zkrepl.dev/?gist=9f513ee275e003ebf8a53559cc8b9198)

## Test

To run a test against the [test vectors](https://github.com/HorizenLabs/monolith/blob/823039b29ea05d77f20613311da9a179e70c88ea/src/monolith_hash/monolith_goldilocks.rs#L396-L415)

```
yarn install
yarn test
```

## Acknowledgements

The code is based on the [reference implementation](https://github.com/HorizenLabs/monolith/tree/main) of Monolith from Horizon Labs.

The implementation of the Goldilocks field is taken from [plonky2-circom](https://github.com/polymerdao/plonky2-circom/blob/main/circom/circuits/goldilocks.circom).

## Disclaimer

These circuits were written over a few hours during [ZK Hack Istanbul](https://www.zkistanbul.com).

While they pass the test vectors and should generally be correct, they have **NOT** been formally audited. Therefore, I strongly recommend against deploying them in a production setting. There's probably also a lot of scope for optimizations to reduce the number of constraints.

PRs welcome
