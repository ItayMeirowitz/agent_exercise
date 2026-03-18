// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

// TODO - Add includes here!
`include "avalon_st_if.sv"
`include "avalon_st_agent_pack.sv"
`include "avalon_st_agent.sv"

import avalon_st_agent_pack::*;

module tb ();

    // Typedef of byte queue to allow returning it from functions
    typedef byte byte_queue[$];

    // Typedef of array of byte queues returning from functions
    typedef byte_queue queue_arr[$];

    function byte_queue random_bytes_gen(int size);
        byte_queue queue;

        // Generate random byte size times.
        repeat(size) begin
            queue.push_back($urandom_range(0, 255));
        end

        // Return final queue
        return queue;
    endfunction

    function byte_queue random_queue_gen(int min = 1, int max = 100);
        return random_bytes_gen($urandom_range(min, max));
    endfunction

    function queue_arr multiple_queues_gen(int amount);
        queue_arr queues;
        
        // Generate queue amount times.
        repeat(amount) begin
            queues.push_back((random_queue_gen()));
        end

        // Return queues queue
        return queues;
    endfunction

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////
    // Data width.
    localparam int unsigned DATA_WIDTH_IN_BYTES = 4;
    localparam int unsigned QUEUES_AMOUNT = 4;

    byte tb_queues[QUEUES_AMOUNT][$] = multiple_queues_gen(QUEUES_AMOUNT);
    byte test_queue[8:0] = {8'h12,8'h12,8'h12,8'h12,8'h12,8'h12,8'h43,8'h65,8'h98};

    //////////////////////////////////////////////////////////////////////////////
    // Declarations.
    //////////////////////////////////////////////////////////////////////////////
    // Clock and reset.
    bit clk;
    bit rst_n;

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));

    // TODO - Declare your classes here.
    avalon_st_agent#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(MASTER)) master_agent = new(vif);
    avalon_st_agent#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(SLAVE), .READY_P(50)) slave_agent = new(vif);

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    // Generate clock.
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Initialize reset signal.
    initial begin
        rst_n = 0;
        #20;
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

    initial begin
        #20;
        @(posedge(clk));
        slave_agent.drive();
    end

    initial begin
        #20;
    	// TODO - Insert TB logic here.
        @(posedge(clk));

        for (int i = 0; i < QUEUES_AMOUNT; i++) begin
            master_agent.drive(tb_queues[i]);
        end
        @(posedge(clk));
        @(posedge(clk));
        master_agent.drive(test_queue);
    end
endmodule