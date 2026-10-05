//=========================================================
// Main UVM testbench compilation file
//=========================================================

`include "arbiter_if.sv"

// arbiter_pkg.sv itself includes all of our UVM classes:
//
// transaction
// sequence
// sequencer
// driver
// monitor
// agent
// scoreboard base
// fixed scoreboard
// round-robin scoreboard
// environment
// tests
//
`include "arbiter_pkg.sv"

// For now, run ONLY the fixed-priority top.
//`include "tb_fixed.sv"

// Use the ROUND-ROBIN top instead of the fixed top.
`include "tb_round_robin.sv"
