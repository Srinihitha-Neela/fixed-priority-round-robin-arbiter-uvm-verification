//=========================================================
// File: arbiter_transaction.sv
//
// Transaction used for BOTH:
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// A transaction represents one request/response operation.
//
// req   -> stimulus sent to DUT
// grant -> response observed from DUT
// reset -> reset state observed by monitor
//=========================================================

class arbiter_transaction extends uvm_sequence_item;


    // ----------------------------------------------------
    // Request
    //
    // rand because this field will be randomized
    // by our UVM sequence.
    // ----------------------------------------------------
    rand bit [3:0] req;


    // ----------------------------------------------------
    // Grant
    //
    // NOT random because grant is produced by the DUT.
    // The monitor will capture the DUT grant and store
    // it here.
    // ----------------------------------------------------
    bit [3:0] grant;


    // ----------------------------------------------------
    // Reset
    //
    // NOT random here because reset is controlled by
    // the top-level testbench.
    //
    // The monitor records its value so the scoreboard
    // knows whether the DUT was in reset.
    // ----------------------------------------------------
    bit reset;


    // ----------------------------------------------------
    // Register transaction with the UVM factory.
    //
    // Field macros also tell UVM about the transaction
    // fields for operations such as print/copy/compare.
    // ----------------------------------------------------
    `uvm_object_utils_begin(arbiter_transaction)

        `uvm_field_int(req,   UVM_ALL_ON)
        `uvm_field_int(grant, UVM_ALL_ON)
        `uvm_field_int(reset, UVM_ALL_ON)

    `uvm_object_utils_end


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(string name = "arbiter_transaction");

        // Call constructor of parent class
        super.new(name);

    endfunction


endclass
