// -----------------------------------------------------------------------------
// File        : avalon_st_driver_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "avalon_st_if.sv"
`include "avalon_st_agent_pack.sv"
`include "avalon_st_driver.sv"

import avalon_st_agent_pack::*;

module tb ();

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////

    // Data width.
    localparam int unsigned DATA_WIDTH_IN_BYTES = 4;

    //////////////////////////////////////////////////////////////////////////////
    // Declarations.
    //////////////////////////////////////////////////////////////////////////////
    // Clock and reset.
    bit clk;
    bit rst_n;

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));

    // Create the master and slave agent to control the interface
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(MASTER), .VALID_READY_P(MASTER_VALID_P)) master_agent = new(vif);
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(SLAVE),  .VALID_READY_P(SLAVE_RDY_P)   ) slave_agent  = new(vif);

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    byte_queue queue;

    // Generate clock.
    initial begin
        clk = 0;
        forever #CLK_TOGGLE clk = ~clk; 
    end

    // Initialize reset signal.
    initial begin
        rst_n = 0;
        #RST_TIME;
        rst_n = 1;
    end

    // Timeout.
    initial begin
        #(10000) $finish;
    end

    // Waves dump.
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

    //////////////////////////////////////////////////////////////////////////////
    // TestBench Logic
    //////////////////////////////////////////////////////////////////////////////
    // Test logic.

    // Control the master lines of the interface
    initial begin
        #RST_TIME;
        @(posedge(clk));

        // Send msgs
        repeat (NUM_OF_MSGS) begin

            // Randomize queue size and data
            std::randomize(queue) with {queue.size() inside {[MIN_SIZE : MAX_SIZE]};};

            // Drive queue
            master_agent.drive_master(queue);

            // Wait random interval between calls
            #($urandom_range(MIN_INTERVAL, MAX_INTERVAL));
        end
    end
endmodule