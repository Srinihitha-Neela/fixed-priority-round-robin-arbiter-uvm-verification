//=========================================================
// File: arbiter_monitor.sv
//
// Common monitor used for BOTH:
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// Main jobs:
//   - Observe req, grant and reset
//   - Convert observed signals into a transaction
//   - Sample common functional coverage
//   - Send transaction to the scoreboard
//   - Print final functional coverage
//
// IMPORTANT:
// The monitor NEVER drives DUT signals.
// It only observes them.
//=========================================================

class arbiter_monitor extends uvm_monitor;

    // Register monitor with UVM factory
    `uvm_component_utils(arbiter_monitor)


    // ----------------------------------------------------
    // Virtual interface
    // ----------------------------------------------------
    virtual arbiter_if vif;


    // ----------------------------------------------------
    // Analysis port
    //
    // Monitor --> analysis_port --> Scoreboard
    // ----------------------------------------------------
    uvm_analysis_port #(arbiter_transaction) ap;


    // ====================================================
    // COMMON FUNCTIONAL COVERAGE
    //
    // Measures:
    //   1. All 16 request combinations
    //   2. All legal grant values
    //   3. req x grant combinations
    // ====================================================

    covergroup arbiter_cg;

        option.per_instance = 1;


        // ------------------------------------------------
        // REQUEST COVERAGE
        //
        // req is 4 bits:
        // 0000 to 1111 = 16 possible combinations.
        //
        // [] creates a separate bin for each value.
        // ------------------------------------------------
        cp_req : coverpoint vif.req {

            bins all_req[] = {[4'b0000 : 4'b1111]};

        }


        // ------------------------------------------------
        // GRANT COVERAGE
        //
        // Legal values:
        //
        // 0000 -> no requester granted
        // 0001 -> requester 0
        // 0010 -> requester 1
        // 0100 -> requester 2
        // 1000 -> requester 3
        //
        // Anything else means multiple grants and is
        // considered illegal.
        // ------------------------------------------------
        cp_grant : coverpoint vif.grant {

            bins no_grant = {4'b0000};

            bins grant_0 = {4'b0001};
            bins grant_1 = {4'b0010};
            bins grant_2 = {4'b0100};
            bins grant_3 = {4'b1000};

            illegal_bins invalid_grant = default;

        }


        // ------------------------------------------------
        // CROSS COVERAGE
        //
        // Measures combinations of request and grant.
        //
        // Examples:
        //
        // req = 0001, grant = 0001
        // req = 0011, grant = 0010
        // req = 1111, grant = 1000
        // etc.
        // ------------------------------------------------
        req_grant_cross : cross cp_req, cp_grant;


    endgroup : arbiter_cg



    // ====================================================
    // CONSTRUCTOR
    // ====================================================

    function new(
        string name = "arbiter_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        // Create the functional coverage group.
        arbiter_cg = new();

    endfunction



    // ====================================================
    // BUILD PHASE
    //
    // 1. Create analysis port
    // 2. Retrieve virtual interface
    // ====================================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Create monitor analysis port.
        ap = new("ap", this);


        // Get virtual interface from UVM config database.
        if (!uvm_config_db #(virtual arbiter_if)::get(
                this,
                "",
                "vif",
                vif
            ))
        begin

            `uvm_fatal(
                "MON",
                "Could not get virtual interface from config_db"
            )

        end

    endfunction



    // ====================================================
    // RUN PHASE
    //
    // Observe DUT activity at every positive clock edge.
    // ====================================================

    task run_phase(uvm_phase phase);

        arbiter_transaction tr;


        forever begin

            // Wait for positive clock edge.
            @(posedge vif.clk);


            // ------------------------------------------------
            // Allow DUT outputs/state to settle.
            //
            // This is particularly useful for the round-robin
            // arbiter because its internal priority pointer can
            // change at the positive clock edge.
            // ------------------------------------------------
            #1step;


            // ------------------------------------------------
            // Create a transaction containing the values
            // observed by the monitor.
            // ------------------------------------------------
            tr = arbiter_transaction::type_id::create(
                "monitored_tr"
            );


            // Capture interface values.
            tr.req   = vif.req;
            tr.grant = vif.grant;
            tr.reset = vif.reset;


            // ------------------------------------------------
            // FUNCTIONAL COVERAGE SAMPLING
            //
            // Only sample during normal operation.
            //
            // Reset cycles are excluded from req/grant
            // functional coverage.
            // ------------------------------------------------
            if (!vif.reset) begin

                arbiter_cg.sample();

            end


            // ------------------------------------------------
            // Display observed transaction.
            // ------------------------------------------------
            `uvm_info(
                "MON",
                $sformatf(
                    "Observed req=%b grant=%b reset=%b",
                    tr.req,
                    tr.grant,
                    tr.reset
                ),
                UVM_MEDIUM
            )


            // ------------------------------------------------
            // Send observed transaction to scoreboard.
            // ------------------------------------------------
            ap.write(tr);

        end

    endtask



    // ====================================================
    // REPORT PHASE
    //
    // Called automatically by UVM near the end of the test.
    //
    // Prints final functional coverage collected by this
    // monitor instance.
    // ====================================================

    function void report_phase(uvm_phase phase);

        real coverage;

        super.report_phase(phase);


        // Get final functional coverage percentage.
        coverage = arbiter_cg.get_inst_coverage();


        // Print coverage report.
        $display("");
        $display("=================================================");
        $display("          FUNCTIONAL COVERAGE REPORT");
        $display("=================================================");
        $display("Request / Grant Functional Coverage = %0.2f%%",
                 coverage);
        $display("=================================================");
        $display("");

    endfunction


endclass
