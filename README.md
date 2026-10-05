# UVM Verification of Fixed-Priority and Round-Robin Arbiters

## Overview

This project implements and verifies two **4-requester arbitration architectures** using **SystemVerilog and UVM (Universal Verification Methodology)**:

- **Fixed-Priority Arbiter**
- **Round-Robin Arbiter**

The verification environment uses reusable UVM components, directed and constrained-random stimulus, independent reference-model-based scoreboards, and functional coverage.

The project focuses on verifying arbitration correctness, priority behavior, round-robin fairness, reset behavior, corner cases, and coverage closure.

---

## Arbiter Designs

### 1. Fixed-Priority Arbiter

The fixed-priority arbiter supports four requesters with the priority:

```text
Requester 3 > Requester 2 > Requester 1 > Requester 0
```

When multiple requests are asserted simultaneously, the highest-priority active requester receives the grant.

Example:

```text
Request : 0111
Grant   : 0100
```

Although requesters 0, 1, and 2 are active, requester 2 receives the grant because it has the highest priority among the active requesters.

The fixed-priority arbiter is implemented as a combinational design.

### Fixed-Priority Mapping

| Request | Grant |
|---|---|
| 0000 | 0000 |
| 0001 | 0001 |
| 0010 | 0010 |
| 0011 | 0010 |
| 0100 | 0100 |
| 0101 | 0100 |
| 0110 | 0100 |
| 0111 | 0100 |
| 1000 | 1000 |
| 1001 | 1000 |
| 1010 | 1000 |
| 1011 | 1000 |
| 1100 | 1000 |
| 1101 | 1000 |
| 1110 | 1000 |
| 1111 | 1000 |

---

### 2. Round-Robin Arbiter

The round-robin arbiter dynamically changes priority to provide fair access among the four requesters.

A **2-bit pointer** determines where the next arbitration search begins.

| Pointer | Search Order |
|---|---|
| `00` | 0 → 1 → 2 → 3 |
| `01` | 1 → 2 → 3 → 0 |
| `10` | 2 → 3 → 0 → 1 |
| `11` | 3 → 0 → 1 → 2 |

After a requester receives a grant, the pointer moves to the requester immediately following the winner.

For example, with all four requesters continuously active:

```text
Request = 1111

Pointer    Grant
----------------
00         0001
01         0010
10         0100
11         1000
00         0001
...
```

This prevents a single requester from permanently dominating access.

Both the grant and pointer are registered on the positive clock edge.

---

## UVM Verification Architecture

The verification environment is organized using standard UVM components.

```text
                 +------------------+
                 |     UVM Test     |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 |     Sequence     |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 |    Sequencer     |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 |      Driver      |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 |       DUT        |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 |     Monitor      |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 |    Scoreboard    |
                 +------------------+
                    |           |
                    v           v
              Reference       Actual
                Model          DUT
                    \           /
                     \         /
                       Compare
```

The environment contains:

- Transaction
- Sequence
- Sequencer
- Driver
- Monitor
- Agent
- Environment
- Base scoreboard
- Fixed-priority scoreboard
- Round-robin scoreboard
- Functional coverage
- Fixed-priority test
- Round-robin test

---

## Verification Strategy

The stimulus combines **directed testing, corner-case testing, and constrained-random verification**.

The main sequence generates:

```text
16 directed request patterns
 8 repeated all-request cases
50 constrained-random transactions
----------------------------------
74 total transactions
```

### Directed Testing

All possible 4-bit request combinations are explicitly generated:

```text
0000
0001
0010
...
1111
```

This guarantees that every request pattern is exercised.

### Contention Testing

The request:

```text
1111
```

is repeatedly applied to exercise heavy contention.

For the fixed-priority arbiter:

```text
1111 → 1000
```

because requester 3 always has the highest priority.

For the round-robin arbiter, repeated contention exercises rotation between requesters.

### Constrained-Random Testing

Additional randomized transactions are generated to exercise different request sequences and state transitions.

---

## Scoreboard and Reference Models

Independent reference models are used to predict the expected grant.

The scoreboard compares:

```text
Expected Grant  <---- Reference Model

                     VS

Actual Grant    <---- DUT
```

Any mismatch is reported as a UVM error.

---

## Fixed-Priority Reference Model

The expected grant is calculated according to:

```text
req[3] > req[2] > req[1] > req[0]
```

The reference model independently determines the expected output for each monitored transaction.

---

## Round-Robin Reference Model

The round-robin scoreboard maintains its own expected pointer state.

For every transaction, it:

1. Determines the current expected pointer.
2. Applies the corresponding round-robin search order.
3. Predicts the expected grant.
4. Calculates the next expected pointer.
5. Compares the expected grant against the DUT output.

The scoreboard does not depend on the DUT's internal pointer for prediction.

---

## Functional Coverage

Functional coverage is used to measure whether important design scenarios have been exercised.

### Fixed-Priority Coverage

The fixed-priority coverage model checks:

- All 16 request patterns
- All 5 legal grant values
- All 16 legal request-to-grant mappings

The request-to-grant mappings are explicitly modeled because a generic request × grant cross would contain combinations that are impossible for a correct fixed-priority arbiter.

Example:

```text
req = 1111
```

has only one legal output:

```text
grant = 1000
```

Therefore, the coverage model focuses on meaningful legal behavior rather than unreachable combinations.

### Fixed-Priority Coverage Result

```text
Request bins          : 16 / 16 = 100%
Grant bins            :  5 / 5  = 100%
Correct mapping bins  : 16 / 16 = 100%

fixed_cg coverage     : 100%
```

---

## Round-Robin Coverage

The round-robin coverage model includes:

- Request coverage
- Pointer-state coverage
- Grant coverage
- Pointer × Request cross coverage
- Reset-pointer behavior
- Consecutive same-grant scenarios

Unlike the fixed-priority arbiter, the round-robin output depends on both the request and the current pointer:

```text
Fixed Priority:

Request → Grant


Round Robin:

Pointer + Request → Grant
```

Therefore, pointer × request cross coverage is important for measuring round-robin state-space exploration.

### Current Round-Robin Coverage

```text
Request bins             : 16 / 16 = 100.00%
Pointer bins             :  4 / 4  = 100.00%
Grant bins               :  5 / 5  = 100.00%
Pointer x Request bins   : 43 / 64 = 67.19%
Same-grant bins          :  2 / 4  = 50.00%
Reset pointer 00 hits    : 1

rr_cg coverage           : 93.44%
same_grant_cg coverage   : 50.00%
```

The remaining uncovered pointer × request and same-grant bins identify targets for further coverage-directed stimulus.

---

## Coverage-Driven Verification

One objective of this project is not simply obtaining a high coverage percentage, but developing meaningful coverage models.

A generic request × grant cross can include unreachable combinations and therefore does not necessarily represent useful verification progress.

Design-specific coverage was consequently implemented to measure scenarios that correspond to actual arbiter behavior.

For the round-robin arbiter, coverage holes are identified at the pointer × request level so that targeted stimulus can be added instead of relying only on additional random transactions.

---

## Project Structure

```text
fixed-priority-round-robin-arbiter-uvm-verification/
│
├── README.md
│
├── rtl/
│   └── design.sv
│
├── tb/
│   ├── testbench.sv
│   ├── arbiter_if.sv
│   ├── arbiter_transaction.sv
│   ├── arbiter_sequence.sv
│   ├── arbiter_sequencer.sv
│   ├── arbiter_driver.sv
│   ├── arbiter_monitor.sv
│   ├── arbiter_agent.sv
│   ├── arbiter_scoreboard_base.sv
│   ├── fixed_priority_scoreboard.sv
│   ├── round_robin_scoreboard.sv
│   ├── arbiter_env.sv
│   ├── fixed_arbiter_test.sv
│   ├── round_robin_test.sv
│   ├── arbiter_pkg.sv
│   ├── tb_fixed.sv
│   └── tb_round_robin.sv
│
├── sim/
│   └── run.do
│
├── results/
│   ├── fixed_priority/
│   │   ├── fixed_priority_waveform.png
│   │   ├── fixed_priority_coverage.png
│   │   └── fixed_simulation_log.txt
│   │
│   └── round_robin/
│       ├── round_robin_waveform.png
│       ├── round_robin_coverage.png
│       └── round_robin_simulation_log.txt
│
└── docs/
    └── verification_plan.md
```

---

## Waveform Verification

### Fixed-Priority Arbiter

The fixed-priority waveform demonstrates that the highest-priority active requester receives the grant.

Example cases include:

```text
req = 0001 → grant = 0001
req = 0011 → grant = 0010
req = 0111 → grant = 0100
req = 1111 → grant = 1000
```



---

### Round-Robin Arbiter

The round-robin waveform demonstrates pointer-based priority rotation and registered grant behavior.

With continuous contention:

```text
req = 1111
```

the expected grant sequence is:

```text
0001 → 0010 → 0100 → 1000 → ...
```
---

## Tools and Technologies

- **SystemVerilog**
- **UVM (Universal Verification Methodology)**
- **Cadence Xcelium**
- **EDA Playground**
- Functional Coverage
- Constrained-Random Verification
- Reference-Model-Based Scoreboarding

---

## Key Verification Concepts Demonstrated

This project demonstrates:

- UVM testbench architecture
- Transaction-level stimulus
- Sequence and sequencer operation
- Driver/DUT communication
- Passive monitoring
- Analysis-port-based transaction transfer
- Reusable UVM agent architecture
- Reference-model-based scoreboarding
- Stateful round-robin prediction
- Directed verification
- Constrained-random verification
- Functional coverage
- Cross coverage
- Coverage-hole analysis
- Corner-case verification
- Reset verification
- One-hot grant behavior
- Fair arbitration behavior

---

## Future Improvements

Potential extensions include:

- Coverage-directed sequences for complete round-robin cross coverage
- SystemVerilog Assertions (SVA)
- One-hot grant assertions
- Grant-without-request assertions
- Round-robin fairness properties
- Parameterized number of requesters
- Regression testing with multiple random seeds
- Additional coverage closure automation

---

## Conclusion

This project demonstrates the design and UVM-based verification of fixed-priority and round-robin arbiters.

The verification environment combines reusable UVM components, independent reference models, scoreboards, directed stimulus, constrained-random stimulus, corner-case testing, and functional coverage.

The fixed-priority arbiter achieves complete coverage of all defined legal request-to-grant mappings. The round-robin environment additionally verifies state-dependent arbitration using pointer-aware prediction and coverage, enabling systematic identification of remaining coverage holes.

The project provides practical experience with verification techniques commonly used in digital design verification workflows.
