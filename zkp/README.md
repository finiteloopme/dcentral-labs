
# ZKP

With _zkRollups_, there is a decent amount of discussion and opinions on
which is the best **Zero Knowledge Proof** (_ZKP_) technology to use.  And
fair enough too - there are many things to consider like circuit design,
compute power required, finality time, cost, etc.  
So while this debate is required, we face into the risk of _paralysis by
analysis_.  

An argument could be made that _Generative AI_ poses a similar dilema when
selecting models for ML workflows.  

And the way _AI&ML_ community has pivoted to using tools/patterns (and pipelines?) to
swap models in and out of their workflows got us thinking could we use
a similar pattern with ZKP.

## An experiment

Using **reth** as an ETH compliant RPC client gives us three distinct advantages:

1. A _frictionless_ way of syncing state with the target EVM chain
2. Given that _rustlang_ is a commonly used language to develop ZKP systems, they can be natively included in a node running _reth_
3. Extensibility and modularity of _reth_ allows us to extend _Ethereum Node_ functionality to support various provers (witness generation techniques)

### Proving process

Generate proof of a state in EVM involves two different steps:

1. Witness generation.  Also known as tracing or input
2. Generating a proof using the witness

Each prover, requires a specific type of witness.  So a witness generated for _ZKP A_ can not be used with _ZKP B_.  So it makes sense that witness generation is done _reth_ nodes either on demand or as the blocks are processed.

Proving itself happens off chain.  This allows us the option of configuring and deploying multiple _ZKP_ systems if required.

# Reference

1. [Reth](https://reth.rs/) is an highly modular, client implementation of Ethereum full node written in Rust

