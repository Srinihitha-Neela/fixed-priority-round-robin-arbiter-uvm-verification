//=========================================================
// File: arbiter_agent.sv
//
// Common agent used for BOTH:
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// The agent groups together:
//   - Sequencer
//   - Driver
//   - Monitor
//
// It also connects the sequencer to the driver.
//
//            arbiter_agent
//       ----------------------
//       |                    |
//       | Sequencer          |
//       |     |              |
//       |     v              |
//       |   Driver           |
//       |                    |
//       |   Monitor          |
//       |                    |
//       ----------------------
//=========================================================

class arbiter_agent extends uvm_agent;

    // Register agent with UVM factory
    `uvm_component_utils(arbiter_agent)


    // ----------------------------------------------------
    // Handles for components contained inside the agent
    // ----------------------------------------------------

    arbiter_sequencer sequencer;
    arbiter_driver    driver;
    arbiter_monitor   monitor;


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "arbiter_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ----------------------------------------------------
    // BUILD PHASE
    //
    // Create the sequencer, driver and monitor.
    // ----------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Create sequencer
        sequencer =
            arbiter_sequencer::type_id::create(
                "sequencer",
                this
            );


        // Create driver
        driver =
            arbiter_driver::type_id::create(
                "driver",
                this
            );


        // Create monitor
        monitor =
            arbiter_monitor::type_id::create(
                "monitor",
                this
            );

    endfunction


    // ----------------------------------------------------
    // CONNECT PHASE
    //
    // Connect driver's seq_item_port to the
    // sequencer's seq_item_export.
    //
    // This allows transactions to flow:
    //
    // Sequence -> Sequencer -> Driver
    // ----------------------------------------------------
    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction


endclass
