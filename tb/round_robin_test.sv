//=========================================================
// File: round_robin_test.sv
//
// UVM test for the ROUND-ROBIN arbiter.
//
// Responsibilities:
//
//   1. Tell arbiter_env to use the round-robin scoreboard.
//
//   2. Create the reusable arbiter environment.
//
//   3. Print the completed UVM hierarchy.
//
//   4. Create and start the common arbiter sequence.
//
// Notice:
// The same sequence, sequencer, driver, monitor and agent
// used for the fixed-priority arbiter are reused here.
//=========================================================

class round_robin_test extends uvm_test;

    // Register this test with the UVM factory.
    `uvm_component_utils(round_robin_test)


    // ----------------------------------------------------
    // Reusable environment handle
    // ----------------------------------------------------
    arbiter_env env;


    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    function new(
        string name = "round_robin_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ====================================================
    // BUILD PHASE
    //
    // 1. Configure environment for ROUND_ROBIN.
    // 2. Create environment.
    // ====================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // ------------------------------------------------
        // Tell the reusable environment:
        //
        // "We are currently verifying the
        //  round-robin arbiter."
        //
        // Therefore arbiter_env will create:
        //
        // round_robin_scoreboard
        // ------------------------------------------------
        uvm_config_db #(arbiter_type_e)::set(
            this,
            "env",
            "arbiter_type",
            ROUND_ROBIN
        );


        // ------------------------------------------------
        // Create the reusable environment.
        // ------------------------------------------------
        env = arbiter_env::type_id::create(
            "env",
            this
        );

    endfunction


    // ====================================================
    // END OF ELABORATION PHASE
    //
    // By this point:
    //
    //   - Components have been created.
    //   - Driver/sequencer connection has been made.
    //   - Monitor/scoreboard connection has been made.
    //
    // Print the complete UVM hierarchy.
    // ====================================================
    function void end_of_elaboration_phase(
        uvm_phase phase
    );

        super.end_of_elaboration_phase(phase);

        `uvm_info(
            "RR_TEST",
            "Printing UVM testbench topology",
            UVM_LOW
        )

        uvm_top.print_topology();

    endfunction


    // ====================================================
    // RUN PHASE
    //
    // Create and start the SAME common arbiter sequence
    // that we use for the fixed-priority arbiter.
    // ====================================================
    task run_phase(uvm_phase phase);

        arbiter_sequence seq;


        // ------------------------------------------------
        // Keep the UVM run phase alive while our sequence
        // is executing.
        // ------------------------------------------------
        phase.raise_objection(this);


        `uvm_info(
            "RR_TEST",
            "Starting round-robin arbiter test",
            UVM_LOW
        )


        // ------------------------------------------------
        // Create the common arbiter sequence.
        // ------------------------------------------------
        seq = arbiter_sequence::type_id::create(
            "seq"
        );


        // ------------------------------------------------
        // Start sequence on the common sequencer.
        //
        // Hierarchy:
        //
        // env
        //  |
        //  +-- agent
        //       |
        //       +-- sequencer
        // ------------------------------------------------
        seq.start(env.agent.sequencer);


        `uvm_info(
            "RR_TEST",
            "Round-robin arbiter sequence completed",
            UVM_LOW
        )


        // ------------------------------------------------
        // Sequence has completed.
        //
        // The test no longer needs to keep run_phase alive.
        // ------------------------------------------------
        phase.drop_objection(this);

    endtask


endclass
