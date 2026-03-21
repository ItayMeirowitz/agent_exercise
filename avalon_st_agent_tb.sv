// -----------------------------------------------------------------------------
// File        : avalon_st_driver_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

// TODO - Add includes here!
`include "avalon_st_if.sv"
`include "avalon_st_agent_pack.sv"
`include "avalon_st_driver.sv"

import avalon_st_agent_pack::*;

module tb ();

    // Typedef of byte queue to allow returning it from functions
    typedef byte byte_queue[$];

    // Typedef of array of byte queues returning from functions
    typedef byte_queue queue_arr[$];

    // Generate and return a random byte queue of specific length - size
    function byte_queue random_bytes_gen(int size);
        byte_queue queue = {};

        // Generate random byte size times.
        repeat(size) begin
            queue.push_back($urandom_range(0, 255));
        end

        // Return final queue
        return queue;
    endfunction

    // Generate and return a random byte queue of random length between min and max.
    function byte_queue random_queue_gen(int min = 1, int max = 100);
        return random_bytes_gen($urandom_range(min, max));
    endfunction

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////
    localparam int unsigned RST_TIME = 20;
    localparam int unsigned CLK_TOGGLE = 5;
    localparam int unsigned TEST_AMOUNT = 10;

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

    // TODO - Declare your classes here.
    // Create the master and slave agent to control the interface
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(MASTER))              master_agent = new(vif);
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(SLAVE), .READY_P(50)) slave_agent = new(vif);

    byte arr1[$] = {
        8'h00, 8'h00, 8'h00, 8'h01, 8'h00, 8'h00, 8'h00, 8'h02, 8'h00, 8'h00, 
        8'h00, 8'h03, 8'h00, 8'h00, 8'h00, 8'h04, 8'h00, 8'h00, 8'h00, 8'h05, 8'h67
    };

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
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

    // Control the slave lines of the interface
    initial begin
        #RST_TIME;
        @(posedge(clk));
        slave_agent.drive();
    end

    // Control the master lines of the interface
    initial begin
    	// TODO - Insert TB logic here.
        #RST_TIME;
        @(posedge(clk));

        repeat (TEST_AMOUNT) begin
            // master_agent.drive(random_bytes_gen(21));
            master_agent.drive(arr1);
            wait_clocks($urandom_range(1, 20));
            // repeat(10) @(posedge(clk));
        end
    end

    task automatic wait_clocks(int unsigned num_cycles);
        repeat (num_cycles) @(posedge(clk));
    endtask
endmodule