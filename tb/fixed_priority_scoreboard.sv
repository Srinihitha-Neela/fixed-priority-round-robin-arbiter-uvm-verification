//=========================================================
// File: fixed_priority_scoreboard.sv
//
// Scoreboard/reference model + detailed functional coverage
// for the 4-requester FIXED-PRIORITY arbiter.
//
// Priority order:
//
//      req[3]  -> highest priority
//      req[2]
//      req[1]
//      req[0]  -> lowest priority
//
// This scoreboard inherits the common comparison/reporting
// mechanism from arbiter_scoreboard_base.
//=========================================================

class fixed_priority_scoreboard
    extends arbiter_scoreboard_base;

    `uvm_component_utils(fixed_priority_scoreboard)


    // ====================================================
    // MANUAL COVERAGE HIT COUNTERS
    // ====================================================

    // Request values 0000 -> 1111
    int unsigned req_hits[16];

    // Grant bins:
    // 0 -> 0000
    // 1 -> 0001
    // 2 -> 0010
    // 3 -> 0100
    // 4 -> 1000
    int unsigned grant_hits[5];

    // Correct request -> grant mapping.
    //
    // Index corresponds to request value.
    //
    // Example:
    // mapping_hits[3] corresponds to:
    //
    //      req   = 0011
    //      grant = 0010
    //
    int unsigned mapping_hits[16];


    // ====================================================
    // FIXED-PRIORITY FUNCTIONAL COVERAGE
    // ====================================================

    covergroup fixed_cg with function sample(
        bit [3:0] req_s,
        bit [3:0] grant_s
    );

        option.per_instance = 1;


        // ------------------------------------------------
        // All 16 request patterns
        // ------------------------------------------------
        cp_req : coverpoint req_s {

            bins all_req[] = {[4'b0000 : 4'b1111]};

        }


        // ------------------------------------------------
        // All legal grant outputs
        // ------------------------------------------------
        cp_grant : coverpoint grant_s {

            bins no_grant = {4'b0000};
            bins grant_0   = {4'b0001};
            bins grant_1   = {4'b0010};
            bins grant_2   = {4'b0100};
            bins grant_3   = {4'b1000};

            illegal_bins invalid_grant = default;

        }


        // ------------------------------------------------
        // CORRECT req -> grant mappings
        //
        // This is better than a raw cp_req x cp_grant cross
        // because a raw cross would create many impossible
        // combinations.
        //
        // Here every bin represents one legal fixed-priority
        // input/output relationship.
        // ------------------------------------------------
        cp_fixed_mapping : coverpoint {req_s, grant_s} {

            bins req_0000 = {8'b0000_0000};

            bins req_0001 = {8'b0001_0001};

            bins req_0010 = {8'b0010_0010};

            bins req_0011 = {8'b0011_0010};

            bins req_0100 = {8'b0100_0100};

            bins req_0101 = {8'b0101_0100};

            bins req_0110 = {8'b0110_0100};

            bins req_0111 = {8'b0111_0100};

            bins req_1000 = {8'b1000_1000};

            bins req_1001 = {8'b1001_1000};

            bins req_1010 = {8'b1010_1000};

            bins req_1011 = {8'b1011_1000};

            bins req_1100 = {8'b1100_1000};

            bins req_1101 = {8'b1101_1000};

            bins req_1110 = {8'b1110_1000};

            bins req_1111 = {8'b1111_1000};

        }

    endgroup


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "fixed_priority_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        // Create fixed-priority covergroup.
        fixed_cg = new();

    endfunction


    // ----------------------------------------------------
    // BUILD PHASE
    // ----------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Initialize request and mapping counters.
        for (int r = 0; r < 16; r++) begin

            req_hits[r]     = 0;
            mapping_hits[r] = 0;

        end


        // Initialize grant counters.
        for (int g = 0; g < 5; g++) begin

            grant_hits[g] = 0;

        end

    endfunction


    // ====================================================
    // FIXED-PRIORITY REFERENCE MODEL
    // ====================================================
    virtual function bit [3:0] predict_grant(
        arbiter_transaction tr
    );

        bit [3:0] expected_grant;


        // Default: no requester is granted.
        expected_grant = 4'b0000;


        // ------------------------------------------------
        // Reset
        // ------------------------------------------------
        if (tr.reset) begin

            return 4'b0000;

        end


        // ------------------------------------------------
        // Fixed-priority arbitration
        //
        // req[3] > req[2] > req[1] > req[0]
        // ------------------------------------------------
        if (tr.req[3]) begin

            expected_grant = 4'b1000;

        end

        else if (tr.req[2]) begin

            expected_grant = 4'b0100;

        end

        else if (tr.req[1]) begin

            expected_grant = 4'b0010;

        end

        else if (tr.req[0]) begin

            expected_grant = 4'b0001;

        end


        return expected_grant;

    endfunction


    // ====================================================
    // FIXED-PRIORITY COVERAGE SAMPLING
    //
    // Called by the base scoreboard after predict_grant().
    // ====================================================
    virtual function void sample_extra_coverage(
        arbiter_transaction tr
    );

        bit [3:0] expected;


        // Do not count reset transaction as normal
        // functional stimulus.
        if (tr.reset)
            return;


        // ------------------------------------------------
        // Native SystemVerilog coverage
        // ------------------------------------------------
        fixed_cg.sample(
            tr.req,
            tr.grant
        );


        // ------------------------------------------------
        // Request hit counter
        // ------------------------------------------------
        req_hits[tr.req]++;


        // ------------------------------------------------
        // Grant hit counter
        // ------------------------------------------------
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
                // Invalid grants are handled elsewhere.
            end

        endcase


        // ------------------------------------------------
        // Determine expected grant for mapping counter.
        //
        // We calculate it locally so this reporting logic
        // does not modify any scoreboard state.
        // ------------------------------------------------
        expected = 4'b0000;

        if (tr.req[3])
            expected = 4'b1000;

        else if (tr.req[2])
            expected = 4'b0100;

        else if (tr.req[1])
            expected = 4'b0010;

        else if (tr.req[0])
            expected = 4'b0001;


        // Only count the mapping if DUT output is correct.
        if (tr.grant == expected) begin

            mapping_hits[tr.req]++;

        end

    endfunction


    // ====================================================
    // REPORT PHASE
    // ====================================================
    function void report_phase(uvm_phase phase);

        int covered_req_bins;
        int covered_grant_bins;
        int covered_mapping_bins;

        real req_manual_cov;
        real grant_manual_cov;
        real mapping_manual_cov;

        super.report_phase(phase);


        covered_req_bins     = 0;
        covered_grant_bins   = 0;
        covered_mapping_bins = 0;


        $display("");
        $display("============================================================");
        $display("      FIXED-PRIORITY DETAILED COVERAGE HIT REPORT");
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
            $display(
                " 0000          %0d          COVERED",
                grant_hits[0]
            );
        else
            $display(
                " 0000          %0d          UNCOVERED",
                grant_hits[0]
            );


        if (grant_hits[1] > 0)
            $display(
                " 0001          %0d          COVERED",
                grant_hits[1]
            );
        else
            $display(
                " 0001          %0d          UNCOVERED",
                grant_hits[1]
            );


        if (grant_hits[2] > 0)
            $display(
                " 0010          %0d          COVERED",
                grant_hits[2]
            );
        else
            $display(
                " 0010          %0d          UNCOVERED",
                grant_hits[2]
            );


        if (grant_hits[3] > 0)
            $display(
                " 0100          %0d          COVERED",
                grant_hits[3]
            );
        else
            $display(
                " 0100          %0d          UNCOVERED",
                grant_hits[3]
            );


        if (grant_hits[4] > 0)
            $display(
                " 1000          %0d          COVERED",
                grant_hits[4]
            );
        else
            $display(
                " 1000          %0d          UNCOVERED",
                grant_hits[4]
            );


        // =================================================
        // CORRECT REQUEST -> GRANT MAPPING
        // =================================================

        $display("");
        $display("============================================================");
        $display("            CORRECT REQUEST -> GRANT MAPPING");
        $display("============================================================");
        $display(" Request       Expected Grant       Hits       Status");
        $display("------------------------------------------------------------");


        for (int r = 0; r < 16; r++) begin

            bit [3:0] expected;

            expected = 4'b0000;


            if (r[3])
                expected = 4'b1000;

            else if (r[2])
                expected = 4'b0100;

            else if (r[1])
                expected = 4'b0010;

            else if (r[0])
                expected = 4'b0001;


            if (mapping_hits[r] > 0)
                covered_mapping_bins++;


            if (mapping_hits[r] > 0)
                $display(
                    "  %04b             %04b             %0d       COVERED",
                    r[3:0],
                    expected,
                    mapping_hits[r]
                );
            else
                $display(
                    "  %04b             %04b             %0d       UNCOVERED",
                    r[3:0],
                    expected,
                    mapping_hits[r]
                );

        end


        // =================================================
        // MANUAL COVERAGE CALCULATION
        // =================================================

        req_manual_cov =
            (100.0 * covered_req_bins) / 16.0;

        grant_manual_cov =
            (100.0 * covered_grant_bins) / 5.0;

        mapping_manual_cov =
            (100.0 * covered_mapping_bins) / 16.0;


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
            "Grant bins               : %0d / 5    = %0.2f%%",
            covered_grant_bins,
            grant_manual_cov
        );

        $display(
            "Correct mapping bins     : %0d / 16   = %0.2f%%",
            covered_mapping_bins,
            mapping_manual_cov
        );


        // =================================================
        // Native SystemVerilog coverage
        // =================================================

        $display("");
        $display("------------- NATIVE COVERGROUP COVERAGE -------------");

        $display(
            "fixed_cg coverage        : %0.2f%%",
            fixed_cg.get_inst_coverage()
        );

        $display("============================================================");
        $display("");

    endfunction


endclass
