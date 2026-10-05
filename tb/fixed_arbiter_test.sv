//=========================================================
// File: fixed_arbiter_test.sv
//
// UVM test for the FIXED-PRIORITY arbiter.
//
// Main responsibilities of this test:
//
//   1. Configure the reusable arbiter environment so that
//      it knows we are testing the fixed-priority DUT.
//
//   2. Create the reusable UVM environment.
//
//   3. Print the completed UVM testbench hierarchy.
//
//   4. Create and start the common arbiter sequence.
//
// Important:
//
// The test itself does NOT:
//
//   - Drive DUT signals directly.
//   - Monitor DUT outputs directly.
//   - Calculate expected grants.
//   - Compare expected and actual results.
//
// Those jobs belong to the driver, monitor and scoreboard.
//=========================================================


class fixed_arbiter_test extends uvm_test;


    // ----------------------------------------------------
    // Register this component with the UVM factory.
    //
    // Because fixed_arbiter_test is a UVM COMPONENT,
    // we use:
    //
    //     `uvm_component_utils
    //
    // This factory registration allows us to start the
    // test from the top module using:
    //
    //     run_test("fixed_arbiter_test");
    // ----------------------------------------------------
    `uvm_component_utils(fixed_arbiter_test)


    // ----------------------------------------------------
    // Handle for the reusable arbiter environment.
    //
    // The environment contains:
    //
    //     arbiter_agent
    //         |
    //         +-- sequencer
    //         +-- driver
    //         +-- monitor
    //
    //     scoreboard
    //
    // The actual scoreboard type will be selected using
    // the arbiter_type configuration.
    // ----------------------------------------------------
    arbiter_env env;


    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    //
    // Every UVM component has a name and parent.
    //
    // For this test, UVM will normally create it as:
    //
    //     uvm_test_top
    //
    // The parent of the top-level UVM test is normally null.
    // ====================================================
    function new(
        string name = "fixed_arbiter_test",
        uvm_component parent = null
    );

        // Call the constructor of the parent class:
        //
        //     uvm_test
        //
        // This initializes the UVM component correctly.
        super.new(name, parent);

    endfunction


    // ====================================================
    // BUILD PHASE
    // ====================================================
    //
    // build_phase is used mainly for:
    //
    //     - Reading configuration
    //     - Setting configuration
    //     - Creating UVM components
    //
    // build_phase is a FUNCTION because it does not
    // consume simulation time.
    //
    // In this test we:
    //
    //     1. Tell arbiter_env that this is a
    //        FIXED_PRIORITY test.
    //
    //     2. Create arbiter_env.
    // ====================================================
    function void build_phase(uvm_phase phase);


        // ------------------------------------------------
        // Always call the parent class implementation of
        // the phase before adding our own behavior.
        // ------------------------------------------------
        super.build_phase(phase);


        // ------------------------------------------------
        // Store the arbiter type in the UVM configuration
        // database.
        //
        // Type:
        //
        //     arbiter_type_e
        //
        // Target component:
        //
        //     "env"
        //
        // Field name:
        //
        //     "arbiter_type"
        //
        // Value:
        //
        //     FIXED_PRIORITY
        //
        // Later, arbiter_env will retrieve this value using:
        //
        //     uvm_config_db::get()
        //
        // and will create:
        //
        //     fixed_priority_scoreboard
        //
        // instead of:
        //
        //     round_robin_scoreboard
        // ------------------------------------------------
        uvm_config_db #(arbiter_type_e)::set(
            this,
            "env",
            "arbiter_type",
            FIXED_PRIORITY
        );


        // ------------------------------------------------
        // Create the reusable arbiter environment using
        // the UVM factory.
        //
        // "env" becomes the instance name.
        //
        // "this" means that the current test is the parent
        // of the environment.
        //
        // Hierarchy:
        //
        //     uvm_test_top
        //          |
        //          +-- env
        //
        // The environment's build_phase will then create
        // the agent and the correct scoreboard.
        // ------------------------------------------------
        env = arbiter_env::type_id::create(
            "env",
            this
        );

    endfunction


    // ====================================================
    // END OF ELABORATION PHASE
    // ====================================================
    //
    // By the time UVM reaches this phase:
    //
    //     - All UVM components have been created.
    //
    //     - The component hierarchy has been built.
    //
    //     - TLM connections have been made during
    //       connect_phase.
    //
    // This is therefore a useful place to print the
    // complete UVM testbench topology.
    //
    // Phase order around this point:
    //
    //     build_phase
    //          |
    //          v
    //     connect_phase
    //          |
    //          v
    //     end_of_elaboration_phase
    //          |
    //          v
    //     start_of_simulation_phase
    //          |
    //          v
    //     run_phase
    //
    // This phase is also a FUNCTION because it does not
    // consume simulation time.
    // ====================================================
    function void end_of_elaboration_phase(
        uvm_phase phase
    );


        // Call the parent implementation first.
        super.end_of_elaboration_phase(phase);


        // ------------------------------------------------
        // Print an informational UVM message.
        //
        // "FIXED_TEST" is the message ID.
        //
        // UVM_LOW is the verbosity level.
        // ------------------------------------------------
        `uvm_info(
            "FIXED_TEST",
            "Printing UVM testbench topology",
            UVM_LOW
        )


        // ------------------------------------------------
        // Print the complete UVM component hierarchy.
        //
        // We expect something similar to:
        //
        //     uvm_test_top
        //         |
        //         +-- env
        //              |
        //              +-- agent
        //              |    |
        //              |    +-- sequencer
        //              |    +-- driver
        //              |    +-- monitor
        //              |
        //              +-- scoreboard
        //
        // For this test, the actual scoreboard object is:
        //
        //     fixed_priority_scoreboard
        // ------------------------------------------------
        uvm_top.print_topology();

    endfunction


    // ====================================================
    // RUN PHASE
    // ====================================================
    //
    // run_phase is where time-consuming verification
    // activity normally occurs.
    //
    // Unlike build_phase, run_phase is a TASK because
    // sequences, drivers and DUT activity consume
    // simulation time.
    //
    // Here we:
    //
    //     1. Raise an objection.
    //     2. Create the sequence.
    //     3. Start the sequence.
    //     4. Wait for the sequence to finish.
    //     5. Drop the objection.
    // ====================================================
    task run_phase(uvm_phase phase);


        // ------------------------------------------------
        // Handle for our common arbiter sequence.
        //
        // This same sequence is reused for BOTH:
        //
        //     fixed-priority arbiter
        //     round-robin arbiter
        //
        // The sequence generates request transactions.
        // ------------------------------------------------
        arbiter_sequence seq;


        // ------------------------------------------------
        // Raise a UVM objection.
        //
        // This tells UVM:
        //
        //     "The test is still doing useful work.
        //      Do not end run_phase yet."
        //
        // Without an objection, UVM could finish the
        // run phase before our sequence completes.
        // ------------------------------------------------
        phase.raise_objection(this);


        // ------------------------------------------------
        // Print a message indicating that stimulus is
        // about to start.
        // ------------------------------------------------
        `uvm_info(
            "FIXED_TEST",
            "Starting fixed-priority arbiter test",
            UVM_LOW
        )


        // ------------------------------------------------
        // Create the sequence using the UVM factory.
        //
        // arbiter_sequence is a UVM OBJECT, so its create()
        // call only requires the object name.
        //
        // This is different from components such as env,
        // which also have a parent.
        // ------------------------------------------------
        seq = arbiter_sequence::type_id::create(
            "seq"
        );


        // ------------------------------------------------
        // Start the sequence on the sequencer.
        //
        // Component hierarchy:
        //
        //     env
        //      |
        //      +-- agent
        //            |
        //            +-- sequencer
        //
        //
        // Stimulus flow:
        //
        //     arbiter_sequence
        //            |
        //            v
        //     arbiter_sequencer
        //            |
        //            v
        //     arbiter_driver
        //            |
        //            v
        //       arbiter_if
        //            |
        //            v
        //           DUT
        //
        //
        // seq.start() is a blocking task.
        //
        // Therefore this line does not return until the
        // sequence has finished generating all of its
        // transactions.
        // ------------------------------------------------
        seq.start(
            env.agent.sequencer
        );


        // ------------------------------------------------
        // If execution reaches here, seq.start() has
        // completed.
        //
        // Therefore all sequence items have been sent
        // through the sequencer/driver path.
        // ------------------------------------------------
        `uvm_info(
            "FIXED_TEST",
            "Fixed-priority arbiter sequence completed",
            UVM_LOW
        )


        // ------------------------------------------------
        // Drop the objection.
        //
        // This tells UVM:
        //
        //     "This test no longer needs to keep
        //      run_phase alive."
        //
        // Once all raised objections have been dropped,
        // UVM can leave run_phase and continue to later
        // phases such as:
        //
        //     extract_phase
        //     check_phase
        //     report_phase
        //
        // Our scoreboard's report_phase will eventually
        // print the PASS/FAIL transaction summary.
        // ------------------------------------------------
        phase.drop_objection(this);

    endtask


endclass
