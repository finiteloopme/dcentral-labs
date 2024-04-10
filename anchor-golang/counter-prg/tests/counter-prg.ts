import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { CounterPrg } from "../target/types/counter_prg";

describe("counter-prg", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.CounterPrg as Program<CounterPrg>;
  let counterStore = anchor.web3.Keypair.generate();

  it("Is initialized!", async () => {
    let counter = new anchor.BN(10);
    // Add your test here.
    const tx = await program.methods.initialize(counter)
      .accounts({
        counter: counterStore.publicKey,
      })
      .signers([counterStore])
      .rpc();
    console.log("Your transaction signature", tx);
  });

  it("Is counter incremented", async() => {
    const tx = await program.methods.increment()
      .accounts({
        counter: counterStore.publicKey
      })
      // .signers([counterStore])
      .rpc();
    console.log("Your transaction signature", tx);

  });

});
