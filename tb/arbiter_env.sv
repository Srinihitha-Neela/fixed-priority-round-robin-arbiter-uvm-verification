//=========================================================
// File: arbiter_env.sv
//
// Reusable UVM environment for BOTH:
//
//   1. Fixed-priority arbiter
//   2. Round-robin arbiter
//
// The environment always creates the SAME agent.
//
// Depending on configuration, it creates either:
//
//   - fixed_priority_scoreboard
//
//             OR
//
//   - round_robin_scoreboard
//
// The monitor is then connected to the selected
// scoreboard.
//=========================================================


// --------------------------------------------------------
// Enum used to tell the environment which arbiter
// algorithm is currently being verified.
// --------------------------------------------------------
typedef enum {
    FIXED_PRIORITY,
    ROUND_ROBIN
} arbiter_type_e;


// ========================================================
// ARBITER ENVIRONMENT
// ========================================================
class arbiter_env extends uvm_env;

    `uvm_component_utils(arbiter_env)


    // ----------------------------------------------------
    // Common agent
    //
    // Same agent is used for both DUTs.
    // ----------------------------------------------------
    arbiter_agent agent;


    // ----------------------------------------------------
    // Base-class scoreboard handle.
    //
    // This handle can point to EITHER:
    //
    // fixed_priority_scoreboard
    //
    // or
    //
    // round_robin_scoreboard
    //
    // This is polymorphism.
    // ----------------------------------------------------
    arbiter_scoreboard_base scoreboard;


    // ----------------------------------------------------
    // Configuration variable telling us which scoreboard
    // should be created.
    // ----------------------------------------------------
    arbiter_type_e arbiter_type;


    // ----------------------------------------------------
    // Constructor
    // ----------------------------------------------------
    function new(
        string name = "arbiter_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ====================================================
    // BUILD PHASE
    //
    // Create:
    //
    //   1. Common agent
    //   2. Correct scoreboard
    // ====================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // ------------------------------------------------
        // Get arbiter type from uvm_config_db.
        //
        // The TEST will put this value into config_db.
        // ------------------------------------------------
        if (!uvm_config_db #(arbiter_type_e)::get(
                this,
                "",
                "arbiter_type",
                arbiter_type
            ))
        begin

            `uvm_fatal(
                "ENV",
                "arbiter_type was not set in config_db"
            )

        end


        // ------------------------------------------------
        // Create common agent.
        //
        // This is identical for both DUTs.
        // ------------------------------------------------
        agent =
            arbiter_agent::type_id::create(
                "agent",
                this
            );


        // ------------------------------------------------
        // Create DUT-specific scoreboard.
        // ------------------------------------------------
        case (arbiter_type)


            // =============================================
            // FIXED-PRIORITY ARBITER
            // =============================================
            FIXED_PRIORITY: begin

                scoreboard =
                    fixed_priority_scoreboard::type_id::create(
                        "scoreboard",
                        this
                    );

                `uvm_info(
                    "ENV",
                    "Using FIXED-PRIORITY scoreboard",
                    UVM_LOW
                )

            end


            // =============================================
            // ROUND-ROBIN ARBITER
            // =============================================
            ROUND_ROBIN: begin

                scoreboard =
                    round_robin_scoreboard::type_id::create(
                        "scoreboard",
                        this
                    );

                `uvm_info(
                    "ENV",
                    "Using ROUND-ROBIN scoreboard",
                    UVM_LOW
                )

            end


            // =============================================
            // Defensive default
            // =============================================
            default: begin

                `uvm_fatal(
                    "ENV",
                    "Unknown arbiter_type configuration"
                )

            end

        endcase

    endfunction


    // ====================================================
    // CONNECT PHASE
    //
    // Connect:
    //
    //     monitor analysis port
    //
    //              to
    //
    //     scoreboard analysis implementation
    // ====================================================
    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        agent.monitor.ap.connect(
            scoreboard.analysis_export
        );

    endfunction


endclass
