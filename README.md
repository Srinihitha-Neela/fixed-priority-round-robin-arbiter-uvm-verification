# Fixed-Priority and Round-Robin Arbiter UVM Verification

SystemVerilog/UVM verification of two 4-requester arbiters: a **fixed-priority arbiter** and a **round-robin arbiter**. The verification environment combines directed and constrained-random stimulus, independent reference-model scoreboards, functional coverage, and **SystemVerilog Assertions (SVA)**.

---

## Project Overview

This project verifies two arbitration schemes:

### Fixed-Priority Arbiter

The fixed-priority arbiter uses the priority order:

```text
req[3] > req[2] > req[1] > req[0]
```

If multiple requesters are active simultaneously, the highest-priority requester receives the grant.

| Request | Grant |
|---|---|
| `0000` | `0000` |
| `0001` | `0001` |
| `0011` | `0010` |
| `0111` | `0100` |
| `1111` | `1000` |

### Round-Robin Arbiter

The round-robin arbiter uses a rotating priority pointer to provide fair arbitration among four requesters.

| Pointer | Search Order |
|---|---|
| `00` | 0 → 1 → 2 → 3 |
| `01` | 1 → 2 → 3 → 0 |
| `10` | 2 → 3 → 0 → 1 |
| `11` | 3 → 0 → 1 → 2 |

After a requester wins, the pointer advances to the requester immediately following the winner.

The round-robin implementation uses a **registered grant**, so its timing is handled differently from the combinational fixed-priority arbiter in both the scoreboard and SVA.

---

## Verification Architecture

The UVM environment contains:

```text
Sequence
   |
Sequencer
   |
Driver
   |
   v
  DUT
   |
Monitor
   |
   +----------------------+
   |                      |
   v                      v
Scoreboard         Functional Coverage
   |
Reference Model

Interface SVA independently checks
cycle-level properties.
```

Main verification components include:

- Transaction
- Directed and constrained-random sequence
- Sequencer
- Driver
- Monitor
- Agent
- Environment
- Independent fixed-priority scoreboard
- Independent round-robin scoreboard
- Functional coverage
- SystemVerilog Assertions

---

## Verification Strategy

The main sequence generates **74 transactions**:

- **16 directed transactions** covering request combinations `0000` through `1111`
- **8 repeated `1111` transactions** for contention testing
- **50 constrained-random transactions**

The directed traffic ensures that all request patterns are exercised.

Repeated full-contention traffic helps exercise round-robin rotation.

Constrained-random traffic provides additional combinations and state transitions.

---

## Reference-Model Scoreboards

### Fixed-Priority Scoreboard

The scoreboard independently predicts the expected grant according to:

```text
req[3] > req[2] > req[1] > req[0]
```

The DUT grant is compared against this prediction for every monitored transaction.

### Round-Robin Scoreboard

The round-robin scoreboard maintains its own reference pointer and independently predicts the expected winning requester.

The scoreboard does **not depend on the DUT's internal pointer**, keeping the reference model independent from the implementation.

---

## SystemVerilog Assertions (SVA)

Concurrent SystemVerilog Assertions are centralized inside:

```text
tb/arbiter_if.sv
```

The SVA layer complements the UVM scoreboard by checking important cycle-level and temporal properties during simulation.

### Common Assertion

The common assertion verifies that:

- Grant contains no `X` or `Z` values.
- Grant is zero-hot or one-hot using:

```systemverilog
$onehot0(grant)
```

Legal values include:

```text
0000
0001
0010
0100
1000
```

Multi-hot grants such as `0011` or `1100` are illegal.

### Fixed-Priority Assertions

The fixed-priority assertions verify:

- No grant is issued to an inactive requester.
- Any active request results in a grant.
- Requester 3 receives the grant whenever `req[3]` is active.
- Requester 2 wins when requester 3 is inactive.
- Requester 1 wins when requesters 3 and 2 are inactive.
- Requester 0 wins when it is the highest active requester.
- No request results in no grant.

Because the fixed-priority DUT is **combinational**, request and grant are checked at the same sampled clock edge.

### Round-Robin Assertions

The round-robin assertions verify:

- No grant is issued to a requester that was not requesting.
- A previous non-zero request results in a non-zero registered grant.
- Grant changes under sustained `req = 1111` contention.
- Reset clears the registered grant.

Because the round-robin arbiter has a **registered output**, `$past(req)` is used where necessary to align the assertions with the DUT timing.

### SVA Cover Properties

Cover properties are also included to demonstrate that important scenarios were exercised:

- `req = 1111` held for four consecutive cycles.
- Transition from an idle request vector to an active request vector.

The SVA layer is passive and therefore does not modify DUT functionality, stimulus, waveforms, or existing functional coverage.

---

## Functional Coverage

Functional coverage is collected separately from SVA/property checking.

### Fixed-Priority Coverage

The fixed-specific coverage model verifies all 16 legal request-to-grant mappings.

```text
Request bins          : 16 / 16 = 100%
Grant bins            : 5 / 5   = 100%
Correct mapping bins  : 16 / 16 = 100%

fixed_cg coverage     : 100%
```

This confirms that all fixed-priority request combinations and their expected grant mappings were exercised.

### Round-Robin Coverage

The round-robin coverage model includes:

- Request bins
- Pointer bins
- Grant bins
- Pointer × request cross coverage
- Same-grant scenarios
- Reset pointer behavior

Recorded results:

```text
Request bins            : 16 / 16 = 100.00%
Pointer bins            : 4 / 4   = 100.00%
Grant bins              : 5 / 5   = 100.00%

Pointer x Request bins  : 43 / 64 = 67.19%
Same-grant bins         : 2 / 4   = 50.00%

rr_cg coverage          : 93.44%
```

The pointer × request cross is intentionally retained because round-robin behavior depends on both the current request vector and arbitration state.

---

## Simulation Results

The verification environment successfully processed the generated transactions without functional mismatches in the validated runs.

After SVA was added:

- DUT functionality remained unchanged.
- Scoreboard results remained unchanged.
- Waveforms remained unchanged.
- Existing functional coverage remained unchanged.
- Additional assertion-based checking was introduced.

This is expected because assertions act as **passive verification checkers** and do not modify the DUT or generated stimulus.

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
└── results/
    ├── Fixed_priority_coverage_report.pdf
    ├── Fixed_simulation_log.pdf
    ├── Round_robin_simulation_log.pdf
    ├── fixed_priority_waveform.png
    ├── round_robin_coverage.pdf
    └── round_robin_waveform.png
```
---

## Tools and Technologies

- SystemVerilog
- UVM
- SystemVerilog Assertions (SVA)
- Cadence Xcelium 25.03
- EDA Playground
- Functional coverage
- Waveform analysis

---

## Key Verification Concepts Demonstrated

This project demonstrates practical knowledge of:

- UVM testbench architecture
- Directed verification
- Constrained-random verification
- UVM sequences and transactions
- Drivers and monitors
- Self-checking scoreboards
- Independent reference modeling
- Functional coverage
- Cross coverage
- SystemVerilog Assertions
- `$onehot0()` invariant checking
- Temporal checking using `$past()`
- SVA cover properties
- Combinational versus registered DUT timing
- Fixed-priority arbitration
- Stateful round-robin arbitration
- Contention and fairness-oriented verification
- Waveform-based debugging

---

## Future Improvements

Potential extensions include:

- Coverage-directed sequences to close the remaining round-robin pointer × request bins.
- Additional round-robin pointer-transition assertions.
- Stronger bounded-fairness properties.
- Parameterizing the arbiter for different numbers of requesters.
- Regression testing using multiple random seeds.
- Automated functional and assertion coverage reporting.

---

## Conclusion

This project verifies two different arbitration architectures using complementary verification techniques.

The **UVM scoreboards** perform end-to-end functional checking using independent reference models.

**Functional coverage** measures whether important request, grant, and round-robin state combinations have been exercised.

**SystemVerilog Assertions** provide an additional layer of cycle-level and temporal checking for arbitration invariants, priority behavior, registered round-robin behavior, and reset handling.

Together, these techniques demonstrate a structured RTL verification methodology applicable to **Digital Verification and Design Verification roles**.
