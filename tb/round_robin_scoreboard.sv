//=========================================================
// File: round_robin_scoreboard.sv
//
// Reference model + additional functional coverage
// for the 4-requester ROUND-ROBIN arbiter.
//
// The scoreboard independently maintains:
//      expected_pointer
//
// It does NOT look at the DUT's internal pointer.
//
// Pointer meaning:
//
//   00 : search 0 -> 1 -> 2 -> 3
//   01 : search 1 -> 2 -> 3 -> 0
//   10 : search 2 -> 3 -> 0 -> 1
//   11 : search 3 -> 0 -> 1 -> 2
//
// After a requester wins, the pointer moves to the
// requester immediately after the winner.
//=========================================================

class round_robin_scoreboard
    extends arbiter_scoreboard_base;

    `uvm_component_utils(round_robin_scoreboard)


    // ----------------------------------------------------
    // Independent reference-model state
    // ----------------------------------------------------
    bit [1:0] expected_pointer;

    // Pointer used for the CURRENT prediction.
    bit [1:0] pointer_before;

    // Pointer expected after the CURRENT arbitration.
    bit [1:0] pointer_after;


    // ----------------------------------------------------
    // Used for back-to-back grant coverage
    // ----------------------------------------------------
    bit [3:0] previous_grant;
    bit       previous_grant_valid;


    // ----------------------------------------------------
    // Used to identify the first normal transaction
    // following reset.
    // ----------------------------------------------------
    bit first_transaction_after_reset;


    // ====================================================
    // MANUAL COVERAGE HIT COUNTERS
    //
    // These counters do NOT replace the SystemVerilog
    // covergroups below.
    //
    // They are only used to print detailed hit information
    // directly in the Xcelium / EDA Playground transcript.
    // ====================================================

    // Request values 0000 -> 1111
    int unsigned req_hits[16];

    // Pointer states 00 -> 11
    int unsigned pointer_hits[4];

    // Pointer x request:
    // [pointer][request]
    int unsigned pointer_req_hits[4][16];

    // Grant bins:
    // 0 -> 0000
    // 1 -> 0001
    // 2 -> 0010
    // 3 -> 0100
    // 4 -> 1000
    int unsigned grant_hits[5];

    // Same-grant coverage counters
    // 0 -> requester 0 = 0001
    // 1 -> requester 1 = 0010
    // 2 -> requester 2 = 0100
    // 3 -> requester 3 = 1000
    int unsigned same_grant_hits[4];

    // First transaction after reset
    int unsigned reset_pointer_00_hits;


    // ====================================================
    // ROUND-ROBIN-SPECIFIC FUNCTIONAL COVERAGE
    //
    // Common req/grant coverage already exists in monitor.
    //
    // Here we add state-related coverage.
    // ====================================================

    covergroup rr_cg with function sample(
        bit [1:0] pointer_s,
        bit [3:0] req_s,
        bit [3:0] grant_s,
        bit       after_reset_s
    );

        option.per_instance = 1;


        // ------------------------------------------------
        // Have all four pointer states been exercised?
        // ------------------------------------------------
        cp_pointer : coverpoint pointer_s {

            bins pointer_0 = {2'b00};
            bins pointer_1 = {2'b01};
            bins pointer_2 = {2'b10};
            bins pointer_3 = {2'b11};

        }


        // ------------------------------------------------
        // Request values while in each pointer state.
        // ------------------------------------------------
        cp_req : coverpoint req_s {

            bins all_req[] = {[4'b0000 : 4'b1111]};

        }


        // ------------------------------------------------
        // Pointer x request coverage
        //
        // 4 pointer states x 16 request values = 64 bins.
        // ------------------------------------------------
        pointer_req_cross : cross cp_pointer, cp_req;


        // ------------------------------------------------
        // Pointer immediately following reset.
        // ------------------------------------------------
        cp_pointer_after_reset : coverpoint pointer_s
            iff (after_reset_s) {

            bins correct_reset_pointer = {2'b00};

            illegal_bins wrong_reset_pointer = {
                2'b01,
                2'b10,
                2'b11
            };

        }


        // ------------------------------------------------
        // Current grant coverage inside RR model.
        // ------------------------------------------------
        cp_grant : coverpoint grant_s {

            bins no_grant = {4'b0000};
            bins grant_0   = {4'b0001};
            bins grant_1   = {4'b0010};
            bins grant_2   = {4'b0100};
            bins grant_3   = {4'b1000};

            illegal_bins invalid_grant = default;

        }

    endgroup


    // ====================================================
    // BACK-TO-BACK SAME-REQUESTER COVERAGE
    // ====================================================

    covergroup same_grant_cg with function sample(
        bit [3:0] grant_s
    );

        option.per_instance = 1;

        cp_same_grant : coverpoint grant_s {

            bins requester_0 = {4'b0001};
            bins requester_1 = {4'b0010};
            bins requester_2 = {4'b0100};
            bins requester_3 = {4'b1000};

        }

    endgroup


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "round_robin_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        // Create coverage groups.
        rr_cg         = new();
        same_grant_cg = new();

    endfunction


    // ----------------------------------------------------
    // BUILD PHASE
    // ----------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Initial reference-model state.
        expected_pointer = 2'b00;

        pointer_before = 2'b00;
        pointer_after  = 2'b00;

        previous_grant       = 4'b0000;
        previous_grant_valid = 1'b0;

        first_transaction_after_reset = 1'b1;


        // =================================================
        // Initialize manual coverage counters
        // =================================================

        for (int r = 0; r < 16; r++) begin
            req_hits[r] = 0;
        end

        for (int p = 0; p < 4; p++) begin

            pointer_hits[p] = 0;

            for (int r = 0; r < 16; r++) begin
                pointer_req_hits[p][r] = 0;
            end

        end

        for (int g = 0; g < 5; g++) begin
            grant_hits[g] = 0;
        end

        for (int g = 0; g < 4; g++) begin
            same_grant_hits[g] = 0;
        end

        reset_pointer_00_hits = 0;

    endfunction


    // ====================================================
    // ROUND-ROBIN REFERENCE MODEL
    //
    // This overrides predict_grant() from the base class.
    // ====================================================
    virtual function bit [3:0] predict_grant(
        arbiter_transaction tr
    );

        bit [3:0] expected_grant;


        // ------------------------------------------------
        // RESET
        // ------------------------------------------------
        if (tr.reset) begin

            expected_pointer = 2'b00;

            pointer_before = 2'b00;
            pointer_after  = 2'b00;

            previous_grant       = 4'b0000;
            previous_grant_valid = 1'b0;

            first_transaction_after_reset = 1'b1;

            return 4'b0000;

        end


        // ------------------------------------------------
        // Save pointer state used for this arbitration.
        // ------------------------------------------------
        pointer_before = expected_pointer;


        // ------------------------------------------------
        // Default:
        //
        // no grant
        // pointer does not move
        // ------------------------------------------------
        expected_grant = 4'b0000;
        pointer_after  = pointer_before;


        // =================================================
        // POINTER = 00
        //
        // Search order:
        //      0 -> 1 -> 2 -> 3
        // =================================================
        case (pointer_before)

            2'b00: begin

                if (tr.req[0]) begin

                    expected_grant = 4'b0001;

                    // Winner = requester 0
                    // Next search begins at requester 1.
                    pointer_after = 2'b01;

                end

                else if (tr.req[1]) begin

                    expected_grant = 4'b0010;

                    // Winner = requester 1
                    // Next search begins at requester 2.
                    pointer_after = 2'b10;

                end

                else if (tr.req[2]) begin

                    expected_grant = 4'b0100;

                    // Winner = requester 2
                    // Next search begins at requester 3.
                    pointer_after = 2'b11;

                end

                else if (tr.req[3]) begin

                    expected_grant = 4'b1000;

                    // Winner = requester 3
                    // Wrap around to requester 0.
                    pointer_after = 2'b00;

                end

            end


            // =============================================
            // POINTER = 01
            //
            // Search order:
            //      1 -> 2 -> 3 -> 0
            // =============================================
            2'b01: begin

                if (tr.req[1]) begin

                    expected_grant = 4'b0010;
                    pointer_after  = 2'b10;

                end

                else if (tr.req[2]) begin

                    expected_grant = 4'b0100;
                    pointer_after  = 2'b11;

                end

                else if (tr.req[3]) begin

                    expected_grant = 4'b1000;
                    pointer_after  = 2'b00;

                end

                else if (tr.req[0]) begin

                    expected_grant = 4'b0001;
                    pointer_after  = 2'b01;

                end

            end


            // =============================================
            // POINTER = 10
            //
            // Search order:
            //      2 -> 3 -> 0 -> 1
            // =============================================
            2'b10: begin

                if (tr.req[2]) begin

                    expected_grant = 4'b0100;
                    pointer_after  = 2'b11;

                end

                else if (tr.req[3]) begin

                    expected_grant = 4'b1000;
                    pointer_after  = 2'b00;

                end

                else if (tr.req[0]) begin

                    expected_grant = 4'b0001;
                    pointer_after  = 2'b01;

                end

                else if (tr.req[1]) begin

                    expected_grant = 4'b0010;
                    pointer_after  = 2'b10;

                end

            end


            // =============================================
            // POINTER = 11
            //
            // Search order:
            //      3 -> 0 -> 1 -> 2
            // =============================================
            2'b11: begin

                if (tr.req[3]) begin

                    expected_grant = 4'b1000;
                    pointer_after  = 2'b00;

                end

                else if (tr.req[0]) begin

                    expected_grant = 4'b0001;
                    pointer_after  = 2'b01;

                end

                else if (tr.req[1]) begin

                    expected_grant = 4'b0010;
                    pointer_after  = 2'b10;

                end

                else if (tr.req[2]) begin

                    expected_grant = 4'b0100;
                    pointer_after  = 2'b11;

                end

            end


            // Defensive default.
            default: begin

                expected_grant = 4'b0000;
                pointer_after  = 2'b00;

            end

        endcase


        // ------------------------------------------------
        // Update independent model for NEXT arbitration.
        // ------------------------------------------------
        expected_pointer = pointer_after;


        // Return current expected grant to base scoreboard.
        return expected_grant;

    endfunction


    // ====================================================
    // ROUND-ROBIN-SPECIFIC COVERAGE
    //
    // Called by base scoreboard after predict_grant().
    //
    // pointer_before still represents the pointer that was
    // used to make the CURRENT prediction.
    // ====================================================
    virtual function void sample_extra_coverage(
        arbiter_transaction tr
    );

        // ------------------------------------------------
        // Original SystemVerilog functional coverage
        // ------------------------------------------------
        rr_cg.sample(
            pointer_before,
            tr.req,
            tr.grant,
            first_transaction_after_reset
        );


        // =================================================
        // MANUAL COVERAGE HIT COUNTERS
        // =================================================

        // Request bin.
        req_hits[tr.req]++;

        // Pointer bin.
        pointer_hits[pointer_before]++;

        // Pointer x request cross bin.
        pointer_req_hits[pointer_before][tr.req]++;


        // -------------------------------------------------
        // Grant bins
        // -------------------------------------------------
        case (tr.grant)

            4'b0000:
                grant_hits[0]++;

            4'b0001:
                grant_hits[1]++;

            4'b0010:
                grant_hits[2]++;

            4'b0100:
                grant_hits[3]++;

            4'b1000:
                grant_hits[4]++;

            default: begin
                // Invalid grants are handled by the
                // covergroup illegal bin / scoreboard.
            end

        endcase


        // -------------------------------------------------
        // Pointer immediately after reset
        // -------------------------------------------------
        if (first_transaction_after_reset) begin

            if (pointer_before == 2'b00)
                reset_pointer_00_hits++;

        end


        // ------------------------------------------------
        // Back-to-back same requester.
        //
        // Only sample if:
        //
        // 1. There was a previous grant
        // 2. Current grant is non-zero
        // 3. Current grant equals previous grant
        // ------------------------------------------------
        if (
            previous_grant_valid &&
            (tr.grant != 4'b0000) &&
            (tr.grant == previous_grant)
        ) begin

            same_grant_cg.sample(tr.grant);

            // Manual hit counter for the same condition.
            case (tr.grant)

                4'b0001:
                    same_grant_hits[0]++;

                4'b0010:
                    same_grant_hits[1]++;

                4'b0100:
                    same_grant_hits[2]++;

                4'b1000:
                    same_grant_hits[3]++;

            endcase

        end


        // ------------------------------------------------
        // Save current grant for next comparison.
        // ------------------------------------------------
        if (tr.grant != 4'b0000) begin

            previous_grant       = tr.grant;
            previous_grant_valid = 1'b1;

        end
        else begin

            previous_grant       = 4'b0000;
            previous_grant_valid = 1'b0;

        end


        // We have now processed the first normal
        // transaction after reset.
        first_transaction_after_reset = 1'b0;

    endfunction


    // ====================================================
    // REPORT PHASE
    //
    // Prints detailed functional coverage hit counts
    // directly in the simulator transcript.
    // ====================================================
    function void report_phase(uvm_phase phase);

        int covered_req_bins;
        int covered_pointer_bins;
        int covered_grant_bins;
        int covered_cross_bins;
        int covered_same_grant_bins;

        real req_manual_cov;
        real pointer_manual_cov;
        real grant_manual_cov;
        real cross_manual_cov;
        real same_grant_manual_cov;

        super.report_phase(phase);


        covered_req_bins        = 0;
        covered_pointer_bins    = 0;
        covered_grant_bins      = 0;
        covered_cross_bins      = 0;
        covered_same_grant_bins = 0;


        $display("");
        $display("============================================================");
        $display("       ROUND-ROBIN DETAILED COVERAGE HIT REPORT");
        $display("============================================================");


        // =================================================
        // REQUEST BINS
        // =================================================

        $display("");
        $display("---------------- REQUEST BINS ----------------");
        $display(" Request       Hits        Status");
        $display("----------------------------------------------");

        for (int r = 0; r < 16; r++) begin

            if (req_hits[r] > 0)
                covered_req_bins++;

            if (req_hits[r] > 0)
                $display(
                    "  %04b          %0d          COVERED",
                    r[3:0],
                    req_hits[r]
                );
            else
                $display(
                    "  %04b          %0d          UNCOVERED",
                    r[3:0],
                    req_hits[r]
                );

        end


        // =================================================
        // POINTER BINS
        // =================================================

        $display("");
        $display("---------------- POINTER BINS ----------------");
        $display(" Pointer       Hits        Status");
        $display("----------------------------------------------");

        for (int p = 0; p < 4; p++) begin

            if (pointer_hits[p] > 0)
                covered_pointer_bins++;

            if (pointer_hits[p] > 0)
                $display(
                    "   %02b           %0d          COVERED",
                    p[1:0],
                    pointer_hits[p]
                );
            else
                $display(
                    "   %02b           %0d          UNCOVERED",
                    p[1:0],
                    pointer_hits[p]
                );

        end


        // =================================================
        // GRANT BINS
        // =================================================

        $display("");
        $display("----------------- GRANT BINS -----------------");
        $display(" Grant         Hits        Status");
        $display("----------------------------------------------");

        for (int g = 0; g < 5; g++) begin

            if (grant_hits[g] > 0)
                covered_grant_bins++;

        end


        if (grant_hits[0] > 0)
            $display(" 0000          %0d          COVERED",
                     grant_hits[0]);
        else
            $display(" 0000          %0d          UNCOVERED",
                     grant_hits[0]);


        if (grant_hits[1] > 0)
            $display(" 0001          %0d          COVERED",
                     grant_hits[1]);
        else
            $display(" 0001          %0d          UNCOVERED",
                     grant_hits[1]);


        if (grant_hits[2] > 0)
            $display(" 0010          %0d          COVERED",
                     grant_hits[2]);
        else
            $display(" 0010          %0d          UNCOVERED",
                     grant_hits[2]);


        if (grant_hits[3] > 0)
            $display(" 0100          %0d          COVERED",
                     grant_hits[3]);
        else
            $display(" 0100          %0d          UNCOVERED",
                     grant_hits[3]);


        if (grant_hits[4] > 0)
            $display(" 1000          %0d          COVERED",
                     grant_hits[4]);
        else
            $display(" 1000          %0d          UNCOVERED",
                     grant_hits[4]);


        // =================================================
        // RESET POINTER COVERAGE
        // =================================================

        $display("");
        $display("------------ RESET POINTER BIN --------------");
        $display(" Pointer       Hits        Status");
        $display("----------------------------------------------");

        if (reset_pointer_00_hits > 0)
            $display(
                "   00           %0d          COVERED",
                reset_pointer_00_hits
            );
        else
            $display(
                "   00           %0d          UNCOVERED",
                reset_pointer_00_hits
            );


        // =================================================
        // SAME GRANT BINS
        // =================================================

        $display("");
        $display("---------- BACK-TO-BACK SAME GRANT -----------");
        $display(" Grant         Hits        Status");
        $display("----------------------------------------------");

        for (int g = 0; g < 4; g++) begin

            if (same_grant_hits[g] > 0)
                covered_same_grant_bins++;

        end


        if (same_grant_hits[0] > 0)
            $display(" 0001          %0d          COVERED",
                     same_grant_hits[0]);
        else
            $display(" 0001          %0d          UNCOVERED",
                     same_grant_hits[0]);


        if (same_grant_hits[1] > 0)
            $display(" 0010          %0d          COVERED",
                     same_grant_hits[1]);
        else
            $display(" 0010          %0d          UNCOVERED",
                     same_grant_hits[1]);


        if (same_grant_hits[2] > 0)
            $display(" 0100          %0d          COVERED",
                     same_grant_hits[2]);
        else
            $display(" 0100          %0d          UNCOVERED",
                     same_grant_hits[2]);


        if (same_grant_hits[3] > 0)
            $display(" 1000          %0d          COVERED",
                     same_grant_hits[3]);
        else
            $display(" 1000          %0d          UNCOVERED",
                     same_grant_hits[3]);


        // =================================================
        // POINTER x REQUEST CROSS
        // =================================================

        $display("");
        $display("============================================================");
        $display("              POINTER x REQUEST CROSS");
        $display("============================================================");
        $display(" Pointer       Request       Hits        Status");
        $display("------------------------------------------------------------");

        for (int p = 0; p < 4; p++) begin

            for (int r = 0; r < 16; r++) begin

                if (pointer_req_hits[p][r] > 0)
                    covered_cross_bins++;

                if (pointer_req_hits[p][r] > 0)
                    $display(
                        "   %02b           %04b          %0d          COVERED",
                        p[1:0],
                        r[3:0],
                        pointer_req_hits[p][r]
                    );
                else
                    $display(
                        "   %02b           %04b          %0d          UNCOVERED",
                        p[1:0],
                        r[3:0],
                        pointer_req_hits[p][r]
                    );

            end

        end


        // =================================================
        // CALCULATE MANUAL COVERAGE PERCENTAGES
        // =================================================

        req_manual_cov =
            (100.0 * covered_req_bins) / 16.0;

        pointer_manual_cov =
            (100.0 * covered_pointer_bins) / 4.0;

        grant_manual_cov =
            (100.0 * covered_grant_bins) / 5.0;

        cross_manual_cov =
            (100.0 * covered_cross_bins) / 64.0;

        same_grant_manual_cov =
            (100.0 * covered_same_grant_bins) / 4.0;


        // =================================================
        // SUMMARY
        // =================================================

        $display("");
        $display("============================================================");
        $display("                MANUAL COVERAGE SUMMARY");
        $display("============================================================");

        $display(
            "Request bins             : %0d / 16   = %0.2f%%",
            covered_req_bins,
            req_manual_cov
        );

        $display(
            "Pointer bins             : %0d / 4    = %0.2f%%",
            covered_pointer_bins,
            pointer_manual_cov
        );

        $display(
            "Grant bins               : %0d / 5    = %0.2f%%",
            covered_grant_bins,
            grant_manual_cov
        );

        $display(
            "Pointer x Request bins   : %0d / 64   = %0.2f%%",
            covered_cross_bins,
            cross_manual_cov
        );

        $display(
            "Same-grant bins          : %0d / 4    = %0.2f%%",
            covered_same_grant_bins,
            same_grant_manual_cov
        );

        $display(
            "Reset pointer 00 hits    : %0d",
            reset_pointer_00_hits
        );


        // =================================================
        // Native SystemVerilog covergroup coverage
        // =================================================

        $display("");
        $display("------------- NATIVE COVERGROUP COVERAGE -------------");

        $display(
            "rr_cg coverage           : %0.2f%%",
            rr_cg.get_inst_coverage()
        );

        $display(
            "same_grant_cg coverage   : %0.2f%%",
            same_grant_cg.get_inst_coverage()
        );

        $display("============================================================");
        $display("");

    endfunction


endclass
