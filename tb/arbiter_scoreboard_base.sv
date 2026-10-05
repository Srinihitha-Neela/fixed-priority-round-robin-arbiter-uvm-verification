//=========================================================
// File: arbiter_scoreboard_base.sv
//
// Base scoreboard shared by BOTH arbiters.
//
// Common responsibilities:
//   1. Receive transactions from monitor
//   2. Ask derived scoreboard for expected grant
//   3. Compare expected grant with actual DUT grant
//   4. Report PASS / ERROR
//
// DUT-specific prediction is NOT implemented here.
//
// Derived classes will implement:
//   - fixed_priority_scoreboard
//   - round_robin_scoreboard
//=========================================================


// --------------------------------------------------------
// "virtual class" means this is intended to be a BASE
// class.
//
// We do NOT create arbiter_scoreboard_base directly.
// Instead, we create one of its derived scoreboards.
// --------------------------------------------------------
virtual class arbiter_scoreboard_base extends uvm_scoreboard;


    // ----------------------------------------------------
    // Analysis implementation
    //
    // This receives transactions sent by:
    //
    //     monitor.ap.write(tr)
    //
    // Later the environment will connect:
    //
    // monitor.ap
    //      |
//      v
    // scoreboard.analysis_export
    // ----------------------------------------------------
    uvm_analysis_imp #(
        arbiter_transaction,
        arbiter_scoreboard_base
    ) analysis_export;


    // ----------------------------------------------------
    // Counters
    //
    // Used to summarize verification results.
    // ----------------------------------------------------
    int unsigned total_transactions;
    int unsigned passed_transactions;
    int unsigned failed_transactions;


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "arbiter_scoreboard_base",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ----------------------------------------------------
    // BUILD PHASE
    // ----------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Create analysis implementation.
        analysis_export = new(
            "analysis_export",
            this
        );


        // Initialize counters.
        total_transactions  = 0;
        passed_transactions = 0;
        failed_transactions = 0;

    endfunction


    // ====================================================
    // PURE VIRTUAL PREDICTION FUNCTION
    //
    // The base scoreboard does not know how arbitration
    // should work.
    //
    // The derived scoreboard MUST implement this function.
    //
    // Fixed scoreboard:
    //      uses fixed-priority rules
    //
    // Round-robin scoreboard:
    //      uses request + expected pointer
    // ====================================================
    pure virtual function bit [3:0] predict_grant(
        arbiter_transaction tr
    );


    // ====================================================
    // EXTRA COVERAGE HOOK
    //
    // Base implementation does nothing.
    //
    // Round-robin scoreboard can override this function
    // later to sample pointer-related coverage.
    // ====================================================
    virtual function void sample_extra_coverage(
        arbiter_transaction tr
    );

        // Intentionally empty in base class.

    endfunction


    // ====================================================
    // WRITE FUNCTION
    //
    // Called automatically when the monitor sends a
    // transaction through its analysis port.
    //
    // Flow:
    //
    // Monitor
    //    |
    //    | ap.write(tr)
    //    v
    // Scoreboard write(tr)
    //    |
    //    v
    // predict_grant()
    //    |
    //    v
    // expected vs actual
    // ====================================================
    function void write(arbiter_transaction tr);

        bit [3:0] expected_grant;


        // ------------------------------------------------
        // RESET TRANSACTION
        //
        // We still call the prediction function during
        // reset so a stateful derived scoreboard can reset
        // its internal reference-model state.
        //
        // We do not count reset as a normal arbitration
        // comparison.
        // ------------------------------------------------
        if (tr.reset) begin

            expected_grant = predict_grant(tr);

            `uvm_info(
                "SCB",
                "Reset transaction observed",
                UVM_MEDIUM
            )

            return;

        end


        // ------------------------------------------------
        // Count normal arbitration transaction.
        // ------------------------------------------------
        total_transactions++;


        // ------------------------------------------------
        // Ask derived scoreboard/reference model:
        //
        // "What should grant be?"
        // ------------------------------------------------
        expected_grant = predict_grant(tr);


        // ------------------------------------------------
        // Compare expected result against actual DUT result.
        // ------------------------------------------------
        if (tr.grant === expected_grant) begin

            passed_transactions++;

            `uvm_info(
                "SCB",
                $sformatf(
                    "PASS | req=%b expected=%b actual=%b",
                    tr.req,
                    expected_grant,
                    tr.grant
                ),
                UVM_LOW
            )

        end
        else begin

            failed_transactions++;

            `uvm_error(
                "SCB",
                $sformatf(
                    "FAIL | req=%b expected=%b actual=%b",
                    tr.req,
                    expected_grant,
                    tr.grant
                )
            )

        end


        // ------------------------------------------------
        // Allow derived scoreboard to collect any
        // DUT-specific coverage.
        //
        // Fixed scoreboard may do nothing here.
        //
        // Round-robin scoreboard will use this for
        // pointer/state-related coverage.
        // ------------------------------------------------
        sample_extra_coverage(tr);

    endfunction


    // ====================================================
    // REPORT PHASE
    //
    // Print a simple final scoreboard summary.
    // ====================================================
    function void report_phase(uvm_phase phase);

        super.report_phase(phase);


        `uvm_info(
            "SCB_SUMMARY",
            $sformatf(
                "Total=%0d Passed=%0d Failed=%0d",
                total_transactions,
                passed_transactions,
                failed_transactions
            ),
            UVM_NONE
        )

    endfunction


endclass
