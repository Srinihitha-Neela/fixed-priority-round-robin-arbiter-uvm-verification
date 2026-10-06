//=========================================================
// File: tb_fixed.sv
//
// Top-level testbench for the FIXED-PRIORITY arbiter.
//
// Responsibilities:
//
//   1. Generate a clock for UVM synchronization.
//   2. Instantiate the common arbiter interface.
//   3. Instantiate the fixed-priority DUT.
//   4. Pass the interface to UVM using config_db.
//   5. Start fixed_arbiter_test.
//
// Note:
// The fixed-priority DUT itself does NOT need a clock.
// The clock exists only so the reusable UVM driver and
// monitor have a common synchronization mechanism.
//=========================================================

module tb_fixed;

    // ----------------------------------------------------
    // Import UVM and our arbiter package.
    // ----------------------------------------------------
    import uvm_pkg::*;
    import arbiter_pkg::*;


    // ====================================================
    // CLOCK
    // ====================================================

    logic clk;


    // ----------------------------------------------------
    // Generate a clock.
    //
    // Initial value:
    //     clk = 0
    //
    // Toggle every 5 time units.
    //
    // Therefore the full clock period is 10 time units.
    // ----------------------------------------------------
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ====================================================
    // INTERFACE
    //
    // Instantiate our common arbiter interface.
    //
    // clk is passed into the interface.
    // ====================================================

    arbiter_if arb_if(clk);


    // ====================================================
    // DUT
    //
    // Fixed-priority arbiter has only:
    //
    //     req
    //     grant
    //
    // It does NOT use clk or reset.
    // ====================================================

    fixed_priority_arbiter dut (
        .req   (arb_if.req),
        .grant (arb_if.grant)
    );


    // ====================================================
    // UVM SETUP
    // ====================================================

    initial begin
      
        arb_if.is_rr = 1'b0;

        // ------------------------------------------------
        // The fixed-priority DUT has no reset.
        //
        // However, our reusable interface contains reset
        // because the round-robin DUT needs it.
        //
        // Keep reset LOW for the fixed-priority test.
        // ------------------------------------------------
        arb_if.reset = 1'b0;


        // ------------------------------------------------
        // Start req at zero.
        //
        // Later the UVM driver will control req.
        // ------------------------------------------------
        arb_if.req = 4'b0000;


        // ------------------------------------------------
        // Put the physical interface into UVM config_db.
        //
        // Driver and monitor contain:
        //
        //     virtual arbiter_if vif;
        //
        // and retrieve this interface during build_phase.
        //
        // "*" means components below the UVM hierarchy
        // may retrieve this interface using the key "vif".
        // ------------------------------------------------
        uvm_config_db #(virtual arbiter_if)::set(
            null,
            "*",
            "vif",
            arb_if
        );


        // ------------------------------------------------
        // Start the UVM test.
        //
        // UVM factory finds:
        //
        //     fixed_arbiter_test
        //
        // because it was registered using:
        //
        // `uvm_component_utils(fixed_arbiter_test)
        // ------------------------------------------------
        run_test("fixed_arbiter_test");

    end
  
  
    //=========================================================
    // WAVEFORM DUMP
    //=========================================================
    initial begin
        $dumpfile("fixed_priority_waveform.vcd");
        $dumpvars(0, tb_fixed);
    end


endmodule

