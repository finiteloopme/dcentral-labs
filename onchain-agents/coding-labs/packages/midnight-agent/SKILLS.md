# Midnight Agent Skills - Compact Language Reference

This document provides comprehensive context for generating Compact smart contracts
for the Midnight Network. It serves as the LLM system prompt for code generation.

## Version Compatibility (v1.0)

| Component | Version |
|-----------|---------|
| Compact Compiler | 0.28.0 |
| Compact Language | 0.20 |
| Compact Runtime | 0.14.0 |
| Midnight.js | v3.0.0 |
| Ledger | 7.0.0 |
| Proof Server | 7.0.0 |
| Indexer | v3.0.0 |

**Important**: Always use `pragma language_version 0.20;` in generated contracts.

## Network Environments

### Preview (Development)
- Node RPC: https://rpc.preview.midnight.network
- Indexer: https://indexer.preview.midnight.network/api/v3/graphql
- Faucet: https://faucet.preview.midnight.network/

### Preprod (Staging)
- Node RPC: https://rpc.preprod.midnight.network
- Indexer: https://indexer.preprod.midnight.network/api/v3/graphql
- Faucet: https://faucet.preprod.midnight.network/

---

## Compact Language Overview

Compact is a **strongly statically typed**, **bounded** smart contract language designed for
privacy-preserving applications using zero-knowledge proofs. Unlike Solidity, Compact contracts
have three execution contexts:

1. **Public Ledger** - Replicated state on the blockchain (visible to all)
2. **ZK Circuits** - Prove correctness without revealing private data
3. **Local/Off-chain** - Private computations via witnesses (user's device only)

### Key Differences from Solidity

| Aspect | Solidity | Compact |
|--------|----------|---------|
| Execution | EVM bytecode | ZK circuits |
| State | Storage slots | Ledger ADTs |
| Functions | Functions | Circuits |
| Privacy | Public by default | Private by default |
| External calls | Contract calls | Witnesses |

---

## Basic Contract Structure

```compact
pragma language_version 0.20;

import CompactStandardLibrary;

// User-defined types
enum State { UNSET, SET }

struct MyData {
  value: Uint<64>;
  flag: Boolean;
}

// Public ledger state
export ledger counter: Counter;
export ledger data: MyData;
export ledger state: State;

// Constructor (called on deployment)
constructor(initialValue: Uint<64>) {
  counter.increment(initialValue as Uint<16>);
  state = State.SET;
}

// Private computation (implemented in TypeScript)
witness getSecretKey(): Bytes<32>;

// Public circuit (entry point)
export circuit increment(): [] {
  counter.increment(1);
}

// Internal circuit (not exported)
circuit helper(x: Field): Field {
  return x + 1;
}
```

---

## Primitive Types

### Boolean
```compact
const flag: Boolean = true;
const notFlag = !flag;
```

### Unsigned Integers

```compact
// Sized integers (up to n bits)
const small: Uint<8> = 255;        // 0-255
const medium: Uint<32> = 1000000;  // 0 to 2^32-1
const large: Uint<64> = 0;         // 0 to 2^64-1

// Bounded integers
const bounded: Uint<0..100> = 50;  // 0-100 inclusive
```

**Note**: `Uint` subtypes: `Uint<0..n>` is a subtype of `Uint<0..m>` if n < m.

### Field
```compact
// Prime field element (ZK proving system scalar field)
const f: Field = 42;
```

### Bytes
```compact
const hash: Bytes<32> = persistentHash("hello");
const padded: Bytes<32> = pad(32, "short");
```

### Tuples and Vectors
```compact
const tuple: [Uint<8>, Boolean] = [42, true];
const vec: Vector<3, Field> = [1, 2, 3];
const first = tuple[0];  // 42
```

---

## User-Defined Types

### Structures
```compact
struct Person {
  name: Bytes<32>;
  age: Uint<8>;
  active: Boolean;
}

// Creation
const p = Person { pad(32, "Alice"), 30, true };
const p2 = Person { name: pad(32, "Bob"), age: 25, active: false };

// Spread syntax
const p3 = Person { ...p, age: 31 };

// Access
const personAge = p.age;
```

### Enumerations
```compact
enum Status { PENDING, APPROVED, REJECTED }

const s: Status = Status.PENDING;
```

---

## Ledger Declarations

Ledger fields store public on-chain state. They use special ADT types.

### Cell (implicit for simple types)
```compact
export ledger value: Uint<64>;      // Implicitly Cell<Uint<64>>
export ledger owner: Bytes<32>;

// Usage in circuits
circuit setValue(v: Uint<64>): [] {
  value = v;                        // Shorthand for value.write(v)
}

circuit getValue(): Uint<64> {
  return value;                     // Shorthand for value.read()
}
```

### Counter
```compact
export ledger count: Counter;

circuit inc(): [] {
  count.increment(1);               // Or: count += 1
}

circuit dec(): [] {
  count.decrement(1);               // Or: count -= 1
}

circuit getCount(): Uint<64> {
  return count.read();              // Or: return count;
}
```

### Map
```compact
export ledger balances: Map<Bytes<32>, Uint<64>>;

circuit setBalance(addr: Bytes<32>, amount: Uint<64>): [] {
  balances.insert(addr, amount);
}

circuit getBalance(addr: Bytes<32>): Uint<64> {
  return balances.lookup(addr);
}

circuit hasBalance(addr: Bytes<32>): Boolean {
  return balances.member(addr);
}
```

### Set
```compact
export ledger whitelist: Set<Bytes<32>>;

circuit addToWhitelist(addr: Bytes<32>): [] {
  whitelist.insert(addr);
}

circuit isWhitelisted(addr: Bytes<32>): Boolean {
  return whitelist.member(addr);
}
```

### List
```compact
export ledger history: List<Uint<64>>;

circuit addEntry(v: Uint<64>): [] {
  history.pushFront(v);
}

circuit getFirst(): Maybe<Uint<64>> {
  return history.head();
}
```

### MerkleTree
```compact
export ledger commitments: MerkleTree<20, Bytes<32>>;

circuit addCommitment(c: Bytes<32>): [] {
  commitments.insert(c);
}
```

---

## Circuits

Circuits are the main operational elements. They compile to ZK circuits.

### Exported Circuits (Entry Points)
```compact
export circuit transfer(to: Bytes<32>, amount: Uint<64>): [] {
  // Public entry point
}
```

### Pure Circuits
```compact
pure circuit hash(x: Field): Bytes<32> {
  return persistentHash(x);
}
```

Pure circuits cannot access ledger state or call witnesses.

### Circuit Parameters and Return Types
```compact
circuit example(a: Uint<32>, b: Boolean): [Uint<32>, Boolean] {
  return [a + 1, !b];
}
```

---

## Witnesses

Witnesses are private computations executed locally on the user's device.
They are declared in Compact but implemented in TypeScript.

```compact
// Declaration in Compact
witness getSecretKey(): Bytes<32>;
witness signMessage(msg: Bytes<32>): Bytes<64>;

// Usage in circuit
export circuit authorize(): [] {
  const sk = getSecretKey();
  const pk = persistentHash(sk);
  assert(owner == pk, "Not authorized");
}
```

**Security Warning**: Witness results are untrusted input. Always validate
witness outputs within the circuit using assertions or commitments.

---

## Privacy and Disclosure (Compact 0.20+)

In Compact 0.20+, function parameters and local variables are **witness values** by default.
They cannot be directly used in ledger operations without explicit disclosure.

### The `disclose()` Function

To use a witness value (parameter, local variable, or witness return) in a ledger operation,
you must wrap it with `disclose()`:

```compact
// WRONG - amount is a witness value, cannot be used directly in ledger operation
export circuit transfer(to: Bytes<32>, amount: Uint<64>): [] {
  balances[to] += amount;  // ERROR: witness value in ledger write
}

// CORRECT - disclose the value first
export circuit transfer(to: Bytes<32>, amount: Uint<64>): [] {
  balances[disclose(to)] += disclose(amount);  // OK: disclosed values can be used
}
```

### When to Use disclose()

| Operation | Needs disclose()? |
|-----------|-------------------|
| Ledger state reads with parameter key | **Yes** |
| Ledger state writes using parameter | **Yes** |
| Comparisons with ledger values | **Yes** |
| Pure arithmetic with parameters | No |
| Assertions with parameters | **Yes** |
| Return values to caller | No |

### Examples

```compact
// Counter with disclosed increment amount
export ledger counter: Counter;

export circuit increment(amount: Uint<16>): [] {
  counter.increment(disclose(amount));  // amount must be disclosed
}

// Map access with disclosed key
export ledger balances: Map<Bytes<32>, Uint<64>>;

export circuit getBalance(addr: Bytes<32>): Uint<64> {
  return balances[disclose(addr)];  // key must be disclosed for map access
}

// Multiple disclosures
export circuit updateBalance(addr: Bytes<32>, newBalance: Uint<64>): [] {
  balances[disclose(addr)] = disclose(newBalance);
}
```

### Witness Naming Convention

Witness functions should use the `private_` prefix by convention:

```compact
witness private_getSecretKey(): Bytes<32>;
witness private_signMessage(msg: Bytes<32>): Bytes<64>;
witness private_computeAmount(): Uint<64>;
```

This makes it clear which functions are implemented off-chain in TypeScript.

---

## Control Flow

### If Statements
```compact
if (condition) {
  // then branch
} else {
  // else branch
}
```

### For Loops
```compact
// Loop over vector
for (const item of vec) {
  // process item
}

// Loop over range
for (const i of 0..10) {
  // i goes from 0 to 9
}
```

### Assertions
```compact
assert(balance >= amount, "Insufficient balance");
assert(owner == sender, "Not authorized");
```

---

## Standard Library Functions

### Hashing

```compact
// Persistent (for stored data)
const h: Bytes<32> = persistentHash(value);
const c: Bytes<32> = persistentCommit(value, randomness);

// Transient (for temporary checks)
const th: Field = transientHash(value);
const tc: Field = transientCommit(value, rand);
```

### Maybe Type
```compact
const m: Maybe<Uint<64>> = some(42);
const n: Maybe<Uint<64>> = none<Uint<64>>();

if (m.isSome) {
  const v = m.value;
}
```

### Either Type
```compact
const l: Either<Uint<64>, Boolean> = left<Uint<64>, Boolean>(42);
const r: Either<Uint<64>, Boolean> = right<Uint<64>, Boolean>(true);
```

### Block Time
```compact
circuit checkExpiry(deadline: Uint<64>): Boolean {
  return blockTimeGt(deadline);  // Current time > deadline
}
```

---

## Common Patterns

### Authorization with Secret Key
```compact
export ledger authority: Bytes<32>;
export ledger round: Counter;

witness secretKey(): Bytes<32>;

circuit publicKey(round: Field, sk: Bytes<32>): Bytes<32> {
  return persistentHash<Vector<3, Bytes<32>>>(
    [pad(32, "myapp:pk"), round as Bytes<32>, sk]
  );
}

export circuit authorize(): [] {
  const sk = secretKey();
  const pk = publicKey(round, sk);
  assert(authority == pk, "Not authorized");
  round.increment(1);  // Prevent replay attacks
}
```

### Commitment Scheme
```compact
export ledger commitments: Set<Bytes<32>>;

witness revealValue(): [Uint<64>, Bytes<32>];  // value, nonce

export circuit commit(commitment: Bytes<32>): [] {
  commitments.insert(commitment);
}

export circuit reveal(): Uint<64> {
  const [value, nonce] = revealValue();
  const expected = persistentCommit(value, nonce);
  assert(commitments.member(expected), "Unknown commitment");
  commitments.remove(expected);
  return value;
}
```

### Simple Counter
```compact
pragma language_version 0.20;
import CompactStandardLibrary;

export ledger round: Counter;

export circuit increment(): [] {
  round.increment(1);
}

export circuit getValue(): Uint<64> {
  return round;
}
```

### Token with Balances
```compact
pragma language_version 0.20;
import CompactStandardLibrary;

export ledger balances: Map<Bytes<32>, Uint<64>>;
export ledger totalSupply: Uint<64>;

witness ownAddress(): Bytes<32>;

constructor(initialSupply: Uint<64>, creator: Bytes<32>) {
  balances.insert(creator, initialSupply);
  totalSupply = initialSupply;
}

export circuit transfer(to: Bytes<32>, amount: Uint<64>): [] {
  const from = ownAddress();
  const fromBalance = balances.lookup(from);
  assert(fromBalance >= amount, "Insufficient balance");
  
  balances.insert(from, fromBalance - amount);
  
  const toBalance = balances.member(to) ? balances.lookup(to) : 0;
  balances.insert(to, toBalance + amount);
}

export circuit balanceOf(addr: Bytes<32>): Uint<64> {
  return balances.member(addr) ? balances.lookup(addr) : 0;
}
```

### Voting with Private Ballots
```compact
pragma language_version 0.20;
import CompactStandardLibrary;

enum VoteOption { NONE, YES, NO }

export ledger yesVotes: Counter;
export ledger noVotes: Counter;
export ledger hasVoted: Set<Bytes<32>>;
sealed export ledger votingOpen: Boolean;

witness voterKey(): Bytes<32>;

constructor() {
  votingOpen = true;
}

export circuit vote(choice: VoteOption): [] {
  assert(votingOpen, "Voting is closed");
  
  const voter = persistentHash(voterKey());
  assert(!hasVoted.member(voter), "Already voted");
  
  hasVoted.insert(voter);
  
  if (choice == VoteOption.YES) {
    yesVotes.increment(1);
  } else if (choice == VoteOption.NO) {
    noVotes.increment(1);
  }
}

export circuit getResults(): [Uint<64>, Uint<64>] {
  return [yesVotes, noVotes];
}
```

---

## Security Best Practices

1. **Never trust witness results** - Always validate with assertions
2. **Use round counters** - Prevent linkability between transactions
3. **Sealed ledger fields** - Use `sealed` for immutable state after deployment
4. **Commitment schemes** - Hide values until reveal time
5. **Time locks** - Use `blockTimeGt/Lt` for deadline enforcement
6. **Avoid replay attacks** - Include nonces or counters in signatures

---

## TypeScript Integration

Witnesses are implemented in TypeScript:

```typescript
import { type Witnesses } from './contract.js';

const witnesses: Witnesses<PrivateState> = {
  secretKey: (context) => {
    // Access private state
    const [state, sk] = getSecretKey(context.privateState);
    return [state, sk];
  },
};
```

---

## References

- [Compact Language Reference](https://docs.midnight.network/next/compact/reference/lang-ref)
- [Ledger Data Types](https://docs.midnight.network/next/compact/reference/ledger-adt)
- [Standard Library](https://docs.midnight.network/next/category/standard-library)
- [Midnight.js GitHub](https://github.com/midnightntwrk/midnight-js)
