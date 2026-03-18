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
    typedef byte byte_arr[$];
    typedef byte_arr queue_byte_arr[$];

    function byte_arr random_byte_queue(int size);
        byte_arr queue;

        repeat(size) begin
            queue.push_back($urandom_range(0, 255)); // random byte
        end

        return queue;
    endfunction

    function byte_arr random_random_byte_queue();
        return random_byte_queue($urandom_range(1, 100));
    endfunction

    function queue_byte_arr random_random_byte_queue_queue(int queues);
        queue_byte_arr queue_queue;
        
        repeat(queues) begin
            queue_queue.push_back((random_random_byte_queue()));
        end

        return queue_queue;
    endfunction

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////
    // Data width.
    localparam int unsigned DATA_WIDTH_IN_BYTES = 4;
    localparam int unsigned QUEUES_AMOUNT = 4;

    byte tb_queues[QUEUES_AMOUNT-1:0][$] = random_random_byte_queue_queue(QUEUES_AMOUNT);
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
    avalon_st_agent#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(MASTER)) agent = new(vif);

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
    	// TODO - Insert TB logic here.
        @(posedge(clk));
        vif.rdy = 1;

        for (int i = 0; i < QUEUES_AMOUNT; i++) begin
            agent.drive(tb_queues[i]);
        end
        @(posedge(clk));
        @(posedge(clk));
        agent.drive(test_queue);
    end
endmodule