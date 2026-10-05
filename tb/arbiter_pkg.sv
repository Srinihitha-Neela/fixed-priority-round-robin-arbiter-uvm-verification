//=========================================================
// File: arbiter_pkg.sv
//
// Common UVM package for the arbiter verification project.
//
// This package contains all UVM classes used to verify:
//
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// IMPORTANT:
// arbiter_if.sv is NOT included inside this package.
// The interface will be compiled BEFORE this package.
//=========================================================

package arbiter_pkg;

    // ----------------------------------------------------
    // Import the UVM package.
    //
    // This gives us access to UVM classes such as:
    //
    // uvm_test
    // uvm_env
    // uvm_agent
    // uvm_driver
    // uvm_monitor
    // uvm_scoreboard
    // uvm_sequence
    // uvm_sequence_item
    // uvm_config_db
    // etc.
    // ----------------------------------------------------
    import uvm_pkg::*;


    // ----------------------------------------------------
    // Include UVM macros.
    //
    // Needed for macros such as:
    //
    // `uvm_component_utils
    // `uvm_object_utils
    // `uvm_info
    // `uvm_error
    // `uvm_fatal
    // ----------------------------------------------------
    `include "uvm_macros.svh"


    // ====================================================
    // TRANSACTION
    //
    // Must come before components that use the
    // transaction type.
    // ====================================================
    `include "arbiter_transaction.sv"


    // ====================================================
    // SEQUENCE
    //
    // Uses arbiter_transaction.
    // ====================================================
    `include "arbiter_sequence.sv"


    // ====================================================
    // SEQUENCER
    //
    // Uses arbiter_transaction.
    // ====================================================
    `include "arbiter_sequencer.sv"


    // ====================================================
    // DRIVER
    //
    // Uses:
    //   - arbiter_transaction
    //   - arbiter_if
    //
    // arbiter_if must already have been compiled.
    // ====================================================
    `include "arbiter_driver.sv"


    // ====================================================
    // MONITOR
    //
    // Uses:
    //   - arbiter_transaction
    //   - arbiter_if
    // ====================================================
    `include "arbiter_monitor.sv"


    // ====================================================
    // AGENT
    //
    // Uses:
    //   - arbiter_sequencer
    //   - arbiter_driver
    //   - arbiter_monitor
    // ====================================================
    `include "arbiter_agent.sv"


    // ====================================================
    // SCOREBOARD BASE CLASS
    //
    // Must appear before the derived scoreboards.
    // ====================================================
    `include "arbiter_scoreboard_base.sv"


    // ====================================================
    // FIXED-PRIORITY SCOREBOARD
    //
    // Extends arbiter_scoreboard_base.
    // ====================================================
    `include "fixed_priority_scoreboard.sv"


    // ====================================================
    // ROUND-ROBIN SCOREBOARD
    //
    // Extends arbiter_scoreboard_base.
    // ====================================================
    `include "round_robin_scoreboard.sv"


    // ====================================================
    // ENVIRONMENT
    //
    // Uses:
    //   - arbiter_agent
    //   - arbiter_scoreboard_base
    //   - fixed_priority_scoreboard
    //   - round_robin_scoreboard
    //
    // arbiter_type_e is currently declared at the top of
    // arbiter_env.sv.
    // ====================================================
    `include "arbiter_env.sv"


    // ====================================================
    // TESTS
    //
    // These must appear AFTER arbiter_env.sv because they
    // use:
    //
    //   arbiter_env
    //   arbiter_type_e
    //
    // ====================================================
    `include "fixed_arbiter_test.sv"
    `include "round_robin_test.sv"


endpackage
