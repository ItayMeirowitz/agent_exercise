// -----------------------------------------------------------------------------
// File        : avalon_st_driver_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "avalon_st_if.sv"
`include "avalon_st_agent_pack.sv"
`include "avalon_st_sequencer.sv"
`include "avalon_st_monitor.sv"
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

    // Create sequencer
    avalon_st_sequencer sequencer = new();

    // Create monitor
    avalon_st_monitor monitor = new(vif);

    // Create the master and slave agent to control the interface
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(SLAVE),  .VALID_READY_P(SLAVE_RDY_P)   ) slave_agent  = new(vif);
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .OPERATION_MODE(MASTER), .VALID_READY_P(MASTER_VALID_P)) master_agent = new(vif);

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    byte_queue queue;
    queue_arr msgs_to_send;

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
        #(10000) print_report();
        $finish;
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
        // Assign sequencer to master agent
        master_agent.set_sequencer(sequencer);

        #RST_TIME;
        @(posedge(clk));

        // Run driver in separate thread using data from sequencer
        fork
            compare_msgs();
            master_agent.drive_master();
        join_none

        // Send msgs to sequencer
        repeat (NUM_OF_MSGS) begin

            // Randomize queue size and data
            std::randomize(queue) with {
                queue.size() inside {
                    [MIN_SIZE : MAX_SIZE]
                };
                queue.size() % DATA_WIDTH_IN_BYTES == 0 dist {
                    1 := ALIGNED_P,
                    0 := 100 - ALIGNED_P
                };
            };

            // Store queue
            sequencer.store_queue(queue);
            msgs_to_send.push_back(queue);

            // Wait random interval between calls
            #($urandom_range(MIN_INTERVAL, MAX_INTERVAL));
        end
    end
    
    // Compare msgs
    task compare_msgs();
        byte_queue incoming_msg;
        byte_queue monitored_msg;

        // Track monitor msg index
        int i = 0;
        int j = 0;

        // Verify msgs forever
        forever begin
            wait(monitor.msg_queue.size() > i && msgs_to_send.size() > i);

            // Get first item
            incoming_msg  = msgs_to_send[i];
            monitored_msg = monitor.msg_queue[i];

            // Verify each byte
            j = 0;
            while (incoming_msg.size() > j && monitored_msg.size() > j) begin
                if (incoming_msg[j] != monitored_msg[j]) begin
                    $display(incoming_msg);
                    $display(monitored_msg);
                    $fatal("Miscompare");
                end
                j++;
            end

            // Verify both msgs had the same size
            if (incoming_msg.size() != monitored_msg.size()) begin
                $display(incoming_msg);
                $display(monitored_msg);
                $fatal("Msg length miscompare");
            end else begin
                $display("Good msg received %d", i);
            end
            i++;
        end
    endtask

    // Prints amount of msgs from each source
    task print_report();
        $display("Received ENV msgs:");
        $display(msgs_to_send.size());
        $display("Received DUT msgs:");
        $display(monitor.msg_queue.size());
    endtask
endmodule