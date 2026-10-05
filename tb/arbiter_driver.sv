//=========================================================
// File: arbiter_driver.sv
//
// Common driver used for BOTH:
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// Main job:
//   - Receive transactions from the sequencer
//   - Extract req from the transaction
//   - Drive req onto the DUT interface
//
// The driver is intentionally DUT-independent.
// It does NOT calculate expected grant values.
//=========================================================

class arbiter_driver extends uvm_driver #(arbiter_transaction);

    // Register driver with the UVM factory.
    // Driver is a COMPONENT.
    `uvm_component_utils(arbiter_driver)


    // ----------------------------------------------------
    // Virtual interface
    //
    // Gives this class access to the actual arbiter_if
    // instance created in the top-level testbench.
    // ----------------------------------------------------
    virtual arbiter_if vif;


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "arbiter_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ----------------------------------------------------
    // BUILD PHASE
    //
    // Retrieve the virtual interface from uvm_config_db.
    //
    // The actual interface will later be placed into
    // config_db by tb_fixed.sv or tb_round_robin.sv.
    // ----------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Try to obtain the interface.
        if (!uvm_config_db #(virtual arbiter_if)::get(
                this,       // component requesting config
                "",         // search relative to this component
                "vif",      // configuration field name
                vif         // variable receiving interface
            ))
        begin

            // Without an interface the driver cannot
            // communicate with the DUT, so stop simulation.
            `uvm_fatal(
                "DRV",
                "Could not get virtual interface from config_db"
            )

        end

    endfunction


    // ----------------------------------------------------
    // RUN PHASE
    //
    // Continuously:
    //
    //   1. Get transaction from sequencer
    //   2. Wait for negative clock edge
    //   3. Drive req
    //   4. Keep req stable through positive edge
    //   5. Tell sequencer transaction is complete
    //
    // Driving on negedge and sampling on posedge helps
    // avoid race conditions between driver and monitor.
    // ----------------------------------------------------
    task run_phase(uvm_phase phase);

        arbiter_transaction tr;


        // Wait until reset is inactive.
        //
        // For fixed-priority top:
        //     reset will simply be held at 0.
        //
        // For round-robin top:
        //     reset starts at 1 and later becomes 0.
        wait (vif.reset == 1'b0);


        // Driver keeps waiting for transactions
        // until UVM ends the run phase.
        forever begin

            // --------------------------------------------
            // STEP 1:
            // Ask sequencer for next transaction.
            //
            // This call blocks until a transaction
            // becomes available.
            // --------------------------------------------
            seq_item_port.get_next_item(tr);


            // --------------------------------------------
            // STEP 2:
            // Wait for falling edge of common clock.
            //
            // The fixed DUT does not use this clock,
            // but the verification environment does.
            // --------------------------------------------
            @(negedge vif.clk);


            // --------------------------------------------
            // STEP 3:
            // Drive transaction request onto interface.
            //
            // Example:
            //
            // tr.req = 1011
            //
            // becomes
            //
            // vif.req = 1011
            // --------------------------------------------
            vif.req <= tr.req;


            `uvm_info(
                "DRV",
                $sformatf(
                    "Driving req = %b",
                    tr.req
                ),
                UVM_MEDIUM
            )


            // --------------------------------------------
            // STEP 4:
            // Keep req stable until the next positive edge.
            //
            // The monitor will sample around this edge.
            // The round-robin DUT also updates state here.
            // --------------------------------------------
            @(posedge vif.clk);


            // --------------------------------------------
            // STEP 5:
            // Tell sequencer that the transaction has
            // finished being processed by the driver.
            // --------------------------------------------
            seq_item_port.item_done();

        end

    endtask


endclass
