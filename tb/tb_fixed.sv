//=========================================================
// File: tb_round_robin.sv
//
// Top-level testbench for the ROUND-ROBIN arbiter.
//
// Responsibilities:
//
//   1. Generate clock.
//   2. Instantiate common arbiter interface.
//   3. Instantiate round-robin DUT.
//   4. Generate DUT reset.
//   5. Pass interface to UVM using config_db.
//   6. Start round_robin_test.
//=========================================================

module tb_round_robin;

    // ----------------------------------------------------
    // Import UVM and our arbiter package.
    // ----------------------------------------------------
    import uvm_pkg::*;
    import arbiter_pkg::*;


    // ====================================================
    // CLOCK
    // ====================================================

    logic clk;


    // Clock period = 10 time units.
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ====================================================
    // COMMON INTERFACE
    // ====================================================

    arbiter_if arb_if(clk);


    // ====================================================
    // ROUND-ROBIN DUT
    //
    // Unlike the fixed-priority arbiter, this DUT uses:
    //
    //   clk
    //   reset
    //   req
    //   grant
    // ====================================================

    round_robin_arbiter dut (
        .clk   (arb_if.clk),
        .reset (arb_if.reset),
        .req   (arb_if.req),
        .grant (arb_if.grant)
    );


    // ====================================================
    // RESET GENERATION
    // ====================================================

    initial begin
      
        arb_if.is_rr = 1'b1;

        // Start with no requests.
        arb_if.req = 4'b0000;

        // Assert reset.
        arb_if.reset = 1'b1;

        // Keep reset asserted through clock edges.
        //
        // This initializes the DUT pointer to:
        //
        //     pointer = 2'b00
        //
        repeat (2)
            @(posedge clk);

        // Deassert reset away from the positive edge.
        //
        // Doing this on the negative edge avoids ambiguity
        // with the DUT's positive-edge sequential logic.
        @(negedge clk);

        arb_if.reset = 1'b0;

    end


    // ====================================================
    // UVM STARTUP
    // ====================================================

    initial begin

        // ------------------------------------------------
        // Make the physical interface available to UVM.
        //
        // Driver and monitor retrieve it as:
        //
        // virtual arbiter_if vif;
        // ------------------------------------------------
        uvm_config_db #(virtual arbiter_if)::set(
            null,
            "*",
            "vif",
            arb_if
        );


        // ------------------------------------------------
        // Start round-robin UVM test.
        // ------------------------------------------------
        run_test("round_robin_test");

    end
  
  
    //=========================================================
    // WAVEFORM DUMP
    //=========================================================
    initial begin
        $dumpfile("round_robin_waveform.vcd");
        $dumpvars(0, tb_round_robin);
    end


endmodule
