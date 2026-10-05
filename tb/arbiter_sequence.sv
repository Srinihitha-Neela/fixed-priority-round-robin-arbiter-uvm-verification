//=========================================================
// File: arbiter_sequence.sv
//
// Common sequence used for BOTH:
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// This sequence generates:
//   1. All 16 possible request combinations
//   2. Important directed corner cases
//   3. Random request traffic
//
// The sequence creates arbiter_transaction objects.
// It does NOT directly drive DUT signals.
//=========================================================

class arbiter_sequence extends uvm_sequence #(arbiter_transaction);

    // Register sequence with UVM factory
    `uvm_object_utils(arbiter_sequence)


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(string name = "arbiter_sequence");

        super.new(name);

    endfunction


    // ----------------------------------------------------
    // body()
    //
    // Main task of the sequence.
    // All stimulus generation happens here.
    // ----------------------------------------------------
    task body();

        // Handle for the transaction that we will create
        arbiter_transaction tr;


        // =================================================
        // PART 1: DIRECTED TESTING
        //
        // Generate every possible 4-bit req combination:
        //
        // 0000
        // 0001
        // 0010
        // ...
        // 1111
        //
        // This guarantees that all 16 request values
        // are tested at least once.
        // =================================================

        for (int i = 0; i < 16; i++) begin

            // Create a new transaction
            tr = arbiter_transaction::type_id::create(
                $sformatf("directed_tr_%0d", i)
            );


            // Tell sequencer that we are starting an item
            start_item(tr);


            // Directed assignment.
            // We are intentionally choosing the req value
            // rather than randomizing it.
            tr.req = i[3:0];


            // Transaction is ready for the driver
            finish_item(tr);

        end


        // =================================================
        // PART 2: IMPORTANT CORNER CASE
        //
        // Repeated all-request condition.
        //
        // This is especially useful for the round-robin
        // arbiter because repeated req=1111 should cause
        // the grant priority to rotate.
        // =================================================

        repeat (8) begin

            tr = arbiter_transaction::type_id::create(
                "all_request_tr"
            );


            start_item(tr);


            // All four requesters are requesting
            tr.req = 4'b1111;


            finish_item(tr);

        end


        // =================================================
        // PART 3: CONSTRAINED-RANDOM TRAFFIC
        //
        // Generate additional random requests.
        //
        // req is declared "rand" inside our transaction,
        // so randomize() will generate a random 4-bit req.
        // =================================================

      repeat (50) begin

            tr = arbiter_transaction::type_id::create(
                "random_tr"
            );


            start_item(tr);


            // Randomize the transaction.
            //
            // Currently there are no constraints,
            // so req may take any value from 0000 to 1111.
            if (!tr.randomize()) begin

                `uvm_error(
                    "SEQ",
                    "Transaction randomization failed"
                )

            end


            finish_item(tr);

        end

    endtask


endclass
