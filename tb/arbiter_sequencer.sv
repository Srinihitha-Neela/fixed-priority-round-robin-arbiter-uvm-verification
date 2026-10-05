//=========================================================
// File: arbiter_sequencer.sv
//
// Common sequencer used for BOTH:
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// The sequencer acts as the communication/control point
// between the sequence and the driver.
//
// Sequence  ->  Sequencer  ->  Driver
//=========================================================

class arbiter_sequencer
    extends uvm_sequencer #(arbiter_transaction);


    // ----------------------------------------------------
    // Register the sequencer with the UVM factory.
    //
    // Sequencer is a UVM COMPONENT, so we use
    // uvm_component_utils rather than uvm_object_utils.
    // ----------------------------------------------------
    `uvm_component_utils(arbiter_sequencer)


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "arbiter_sequencer",
        uvm_component parent = null
    );

        // Call constructor of parent uvm_sequencer class
        super.new(name, parent);

    endfunction


endclass
