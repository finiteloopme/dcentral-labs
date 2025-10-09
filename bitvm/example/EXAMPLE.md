An end-to-end BitVM3 example involves two parties (Alice and Bob) pre-signing a transaction graph for an off-chain computation, typically for a "[trustless vault](https://www.google.com/search?cs=0&sca_esv=fa0d648ec49d7a9f&sxsrf=AE3TifNK-KZyd-7WIptWrXa85ll0CKbCLg%3A1759965280795&q=trustless+vault&sa=X&ved=2ahUKEwibv9bK3ZWQAxVYWGwGHZKyOVoQxccNegQIAhAB&mstk=AUtExfCxpJa9cG7_6ASV0WKPJRIUFjF1do-c9-gmrgIhRcH7nDN1qc9j4B_GJSwflpsPST0QewMgitZ2HXYF9iGMYzwjv1oE8DG1LQ-TO76rF_ckMVUg-zw-Tg94W77zyxiqKFQ4kM7Kg4aWxLmTMiy_JUjOOsmRGU7z3___S9RUYZiuOvA&csui=3)" or bridging a Bitcoin-based stablecoin, then using [garbled circuits](https://www.google.com/search?cs=0&sca_esv=fa0d648ec49d7a9f&sxsrf=AE3TifNK-KZyd-7WIptWrXa85ll0CKbCLg%3A1759965280795&q=garbled+circuits&sa=X&ved=2ahUKEwibv9bK3ZWQAxVYWGwGHZKyOVoQxccNegQIAhAC&mstk=AUtExfCxpJa9cG7_6ASV0WKPJRIUFjF1do-c9-gmrgIhRcH7nDN1qc9j4B_GJSwflpsPST0QewMgitZ2HXYF9iGMYzwjv1oE8DG1LQ-TO76rF_ckMVUg-zw-Tg94W77zyxiqKFQ4kM7Kg4aWxLmTMiy_JUjOOsmRGU7z3___S9RUYZiuOvA&csui=3) to execute the computation off-chain while verifying the integrity on-chain only if a dispute arises. Alice deposits BTC and Bob deposits USDT, and the BitVM3 process runs a garbled version of a trustless vault contract, which relies on a snark verifier off-chain to check state updates from another network. If Bob tries to make a malicious withdrawal, Alice can challenge the withdrawal, and the BitVM3's challenge-response game ensures that the protocol correctly executes the state update, even if the operator is malicious. 

The Use Case: Lending Stablecoins with BTC (Trustless Vault)



* **Participants**: Alice (has BTC) and Bob (has USDT). 
* 
* **Goal**: Alice wants to lend USDT to other users, and BitVM3 enables a trustless mechanism for this. 
* 
* **Pre-Signing**: Alice and Bob pre-sign a transaction graph that outlines all possible execution paths for the contract, ensuring an immutable contract once consensus is reached. 
* 

How the Computation Works Off-Chain



* **Garbled Circuits**: A garbled circuit is used to run the actual computation of the trustless vault off-chain. 
* **[SNARK Verifier](https://www.google.com/search?cs=0&sca_esv=fa0d648ec49d7a9f&sxsrf=AE3TifNK-KZyd-7WIptWrXa85ll0CKbCLg%3A1759965280795&q=SNARK+Verifier&sa=X&ved=2ahUKEwibv9bK3ZWQAxVYWGwGHZKyOVoQxccNegQIIxAB&mstk=AUtExfCxpJa9cG7_6ASV0WKPJRIUFjF1do-c9-gmrgIhRcH7nDN1qc9j4B_GJSwflpsPST0QewMgitZ2HXYF9iGMYzwjv1oE8DG1LQ-TO76rF_ckMVUg-zw-Tg94W77zyxiqKFQ4kM7Kg4aWxLmTMiy_JUjOOsmRGU7z3___S9RUYZiuOvA&csui=3)**: An off-chain SNARK verifier checks the state of another network (like a layer 2) to facilitate deposits, withdrawals, and state updates to the bridge. 
* **[BitHash](https://www.google.com/search?cs=0&sca_esv=fa0d648ec49d7a9f&sxsrf=AE3TifNK-KZyd-7WIptWrXa85ll0CKbCLg%3A1759965280795&q=BitHash&sa=X&ved=2ahUKEwibv9bK3ZWQAxVYWGwGHZKyOVoQxccNegQIJRAB&mstk=AUtExfCxpJa9cG7_6ASV0WKPJRIUFjF1do-c9-gmrgIhRcH7nDN1qc9j4B_GJSwflpsPST0QewMgitZ2HXYF9iGMYzwjv1oE8DG1LQ-TO76rF_ckMVUg-zw-Tg94W77zyxiqKFQ4kM7Kg4aWxLmTMiy_JUjOOsmRGU7z3___S9RUYZiuOvA&csui=3)**: A novel hash function optimized for Bitcoin Script, BitHash is introduced by BitVM3 to reduce collateral requirements and make economically feasible for bridges. 

On-Chain Verification and Dispute Resolution



* **Challenging a Malicious Withdrawal**: If Bob (the operator in this case) attempts a malicious withdrawal, a challenger (or Alice) can raise a challenge. 
* **On-Chain Assertion**: The challenger then submits a proof to the Bitcoin network that the operator's action was incorrect. 
* **[Proving](https://www.google.com/search?cs=0&sca_esv=fa0d648ec49d7a9f&sxsrf=AE3TifNK-KZyd-7WIptWrXa85ll0CKbCLg%3A1759965280795&q=Proving&sa=X&ved=2ahUKEwibv9bK3ZWQAxVYWGwGHZKyOVoQxccNegQINRAB&mstk=AUtExfCxpJa9cG7_6ASV0WKPJRIUFjF1do-c9-gmrgIhRcH7nDN1qc9j4B_GJSwflpsPST0QewMgitZ2HXYF9iGMYzwjv1oE8DG1LQ-TO76rF_ckMVUg-zw-Tg94W77zyxiqKFQ4kM7Kg4aWxLmTMiy_JUjOOsmRGU7z3___S9RUYZiuOvA&csui=3)**: BitVM3 enables the on-chain execution of a snark verifier to check the proof. 
* **Final On-Chain Execution**: BitVM3's architecture ensures that the protocol correctly executes the state update, even if the operator is malicious