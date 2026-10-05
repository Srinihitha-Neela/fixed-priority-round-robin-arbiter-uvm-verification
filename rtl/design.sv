//=========================================================
// 4-REQUESTER FIXED-PRIORITY ARBITER
//=========================================================
//
// This arbiter has four requesters: req[3:0].
//
// Fixed priority order:
//
//      req[3] > req[2] > req[1] > req[0]
//
// req[3] has the highest priority.
// req[0] has the lowest priority.
//
// The output grant is one-hot:
//      0001 -> requester 0 granted
//      0010 -> requester 1 granted
//      0100 -> requester 2 granted
//      1000 -> requester 3 granted
//      0000 -> no requester granted
//
// This arbiter is purely combinational.
//=========================================================

module fixed_priority_arbiter (
    input  logic [3:0] req,
    output logic [3:0] grant
);

    //=====================================================
    // FIXED-PRIORITY COMBINATIONAL LOGIC
    //=====================================================
    always_comb begin

        // Default: no requester is granted.
        // This value remains when req = 0000.
        grant = 4'b0000;

        // Fixed priority: 3 > 2 > 1 > 0

        // Requester 3 has the highest priority.
        // If req[3] is active, requester 3 wins even if
        // other lower-priority requesters are also active.
        if (req[3])
            grant = 4'b1000;

        // Requester 2 is checked only if req[3] is inactive.
        else if (req[2])
            grant = 4'b0100;

        // Requester 1 is checked only if both
        // req[3] and req[2] are inactive.
        else if (req[1])
            grant = 4'b0010;

        // Requester 0 has the lowest priority.
        // It is granted only if req[3], req[2], and req[1]
        // are all inactive.
        else if (req[0])
            grant = 4'b0001;

    end

endmodule


//=========================================================
// 4-requester ROUND-ROBIN arbiter
//=========================================================
//
// Unlike fixed priority, the round-robin arbiter changes
// its starting priority after every successful grant.
//
// A 2-bit pointer stores the requester from which the
// priority search should begin.
//
// Pointer meanings:
//
//      pointer = 00 : Search 0 -> 1 -> 2 -> 3
//      pointer = 01 : Search 1 -> 2 -> 3 -> 0
//      pointer = 10 : Search 2 -> 3 -> 0 -> 1
//      pointer = 11 : Search 3 -> 0 -> 1 -> 2
//
// After a requester wins, the pointer moves to the
// requester immediately after the winner.
//
// Example:
//      pointer = 00
//      req     = 0011
//
// Search starts from requester 0.
// Since req[0] = 1:
//      next_grant   = 0001
//      next_pointer = 01
//
// Therefore, the next arbitration begins from requester 1.
//
// Both the pointer and grant are registered on the
// positive edge of the clock.
//=========================================================

module round_robin_arbiter (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] req,
    output logic [3:0] grant
);

    // Current round-robin pointer.
    //
    // 00 -> requester 0 gets first priority
    // 01 -> requester 1 gets first priority
    // 10 -> requester 2 gets first priority
    // 11 -> requester 3 gets first priority
    logic [1:0] pointer;

    // Next value of the round-robin pointer.
    // This is calculated combinationally and loaded into
    // pointer at the next positive clock edge.
    logic [1:0] next_pointer;

    // Combinationally calculated grant that will be
    // registered at the next positive clock edge.
    logic [3:0] next_grant;


    //=====================================================
    // COMBINATIONAL NEXT-STATE / NEXT-GRANT LOGIC
    //=====================================================
    //
    // This block determines:
    //
    // 1. Which requester should receive the grant.
    // 2. What the next pointer value should be.
    //
    // The current pointer determines the search order.
    //=====================================================
    always_comb begin

        // Defaults
        //
        // Initially assume there is no grant.
        next_grant   = 4'b0000;

        // If no requester is active, the pointer remains
        // in its current state.
        next_pointer = pointer;

        // Select arbitration order based on current pointer.
        case (pointer)

            // ------------------------------------------------
            // pointer = 00
            // Search: 0 -> 1 -> 2 -> 3
            //
            // Requester 0 has first priority in this state.
            // ------------------------------------------------
            2'b00: begin

                // Requester 0 is checked first.
                if (req[0]) begin
                    next_grant   = 4'b0001;

                    // After requester 0 wins, the next
                    // arbitration starts from requester 1.
                    next_pointer = 2'b01;
                end

                // If requester 0 is inactive,
                // check requester 1.
                else if (req[1]) begin
                    next_grant   = 4'b0010;

                    // After requester 1 wins, start from 2.
                    next_pointer = 2'b10;
                end

                // If requesters 0 and 1 are inactive,
                // check requester 2.
                else if (req[2]) begin
                    next_grant   = 4'b0100;

                    // After requester 2 wins, start from 3.
                    next_pointer = 2'b11;
                end

                // Requester 3 is checked last.
                else if (req[3]) begin
                    next_grant   = 4'b1000;

                    // After requester 3 wins, wrap around
                    // and start from requester 0.
                    next_pointer = 2'b00;
                end

            end


            // ------------------------------------------------
            // pointer = 01
            // Search: 1 -> 2 -> 3 -> 0
            //
            // Requester 1 has first priority in this state.
            // ------------------------------------------------
            2'b01: begin

                // Requester 1 is checked first.
                if (req[1]) begin
                    next_grant   = 4'b0010;

                    // Next search begins from requester 2.
                    next_pointer = 2'b10;
                end

                // Requester 2 has second priority.
                else if (req[2]) begin
                    next_grant   = 4'b0100;

                    // Next search begins from requester 3.
                    next_pointer = 2'b11;
                end

                // Requester 3 has third priority.
                else if (req[3]) begin
                    next_grant   = 4'b1000;

                    // Wrap around to requester 0.
                    next_pointer = 2'b00;
                end

                // Requester 0 is checked last.
                else if (req[0]) begin
                    next_grant   = 4'b0001;

                    // Next search begins from requester 1.
                    next_pointer = 2'b01;
                end

            end


            // ------------------------------------------------
            // pointer = 10
            // Search: 2 -> 3 -> 0 -> 1
            //
            // Requester 2 has first priority in this state.
            // ------------------------------------------------
            2'b10: begin

                // Requester 2 is checked first.
                if (req[2]) begin
                    next_grant   = 4'b0100;

                    // Next search begins from requester 3.
                    next_pointer = 2'b11;
                end

                // Requester 3 has second priority.
                else if (req[3]) begin
                    next_grant   = 4'b1000;

                    // Wrap around to requester 0.
                    next_pointer = 2'b00;
                end

                // Requester 0 has third priority.
                else if (req[0]) begin
                    next_grant   = 4'b0001;

                    // Next search begins from requester 1.
                    next_pointer = 2'b01;
                end

                // Requester 1 is checked last.
                else if (req[1]) begin
                    next_grant   = 4'b0010;

                    // Next search begins from requester 2.
                    next_pointer = 2'b10;
                end

            end


            // ------------------------------------------------
            // pointer = 11
            // Search: 3 -> 0 -> 1 -> 2
            //
            // Requester 3 has first priority in this state.
            // ------------------------------------------------
            2'b11: begin

                // Requester 3 is checked first.
                if (req[3]) begin
                    next_grant   = 4'b1000;

                    // After requester 3 wins, wrap around
                    // and start from requester 0.
                    next_pointer = 2'b00;
                end

                // Requester 0 has second priority.
                else if (req[0]) begin
                    next_grant   = 4'b0001;

                    // Next search begins from requester 1.
                    next_pointer = 2'b01;
                end

                // Requester 1 has third priority.
                else if (req[1]) begin
                    next_grant   = 4'b0010;

                    // Next search begins from requester 2.
                    next_pointer = 2'b10;
                end

                // Requester 2 is checked last.
                else if (req[2]) begin
                    next_grant   = 4'b0100;

                    // Next search begins from requester 3.
                    next_pointer = 2'b11;
                end

            end


            // ------------------------------------------------
            // Defensive default case.
            //
            // Since pointer is 2 bits, its normal valid
            // states are 00, 01, 10, and 11.
            //
            // If an unexpected state is encountered,
            // clear the grant and return the pointer to 00.
            // ------------------------------------------------
            default: begin
                next_grant   = 4'b0000;
                next_pointer = 2'b00;
            end

        endcase

    end


    //=====================================================
    // REGISTERED POINTER AND GRANT
    //=====================================================
    //
    // Both pointer and grant are updated on the positive
    // edge of the clock.
    //
    // Reset is asynchronous and active high.
    //=====================================================
    always_ff @(posedge clk or posedge reset) begin

        // On reset:
        //
        // pointer returns to 00, meaning the first
        // arbitration begins with requester 0.
        //
        // No requester is granted during reset.
        if (reset) begin
            pointer <= 2'b00;
            grant   <= 4'b0000;
        end

        // During normal operation, register the pointer
        // and grant calculated by the combinational block.
        else begin
            pointer <= next_pointer;
            grant   <= next_grant;
        end

    end

endmodule
