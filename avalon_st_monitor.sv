import avalon_st_agent_pack::*;

class avalon_st_monitor #(parameter int DATA_WIDTH_IN_BYTES = 4);
    
    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;
    queue_arr msg_queue;
    queue_arr incoming_msgs;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new(virtual avalon_st_if vif);
        this.vif = vif;        
        
        // Start separate thread to monitor (without halting the software)
        fork
            compare_msgs();
            monitor_msgs();
            monitor_invalid_interface();
        join_none
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    // Drive master using a byte queue converting it into the avalon_st interface
    task monitor_msgs();

        // Received words queue
        byte_queue word_received;
        byte_queue received_queue = {};

        // Listen to transactions
        forever @(vif.monitor_cb iff (vif.monitor_cb.valid && vif.monitor_cb.rdy)) begin

            // Pack received word.
            word_received = {>>$size(byte){vif.monitor_cb.data}};

            // Receive data
            if (vif.monitor_cb.eop) begin

                // Add word and apply empty
                received_queue = {
                    received_queue,
                    word_received[0 : word_received.size() - vif.monitor_cb.empty - 1]
                };

                // Add packet to queue
                this.msg_queue.push_back(received_queue);

                // Reset queue
                received_queue = {};
            end else begin

                // Add word
                received_queue = {
                    received_queue,
                    word_received
                };
            end
        end
    endtask

    // Check for invalid avalon st interface
    task monitor_invalid_interface();
        bit in_packet = 1'b0;

        forever @(vif.monitor_cb iff (vif.monitor_cb.valid && vif.monitor_cb.rdy)) begin
            // Check for valid out of packet (also checks multiple EOPs)
            if (!in_packet && !vif.monitor_cb.sop) begin
                $fatal("Valid out of packet");
            end

            // Check for multiple SOPs (without proceeding EOP)
            if (in_packet && vif.monitor_cb.sop) begin
                $fatal("Multiple SOPs");
            end

            // Check if empty is in valid range
            if (vif.monitor_cb.empty >= DATA_WIDTH_IN_BYTES && vif.monitor_cb.eop) begin
                $fatal("BAD empty value");
            end

            // Check sop & eop to track issues
            if (vif.monitor_cb.sop) begin
                in_packet = 1'b1;
            end
            if (vif.monitor_cb.eop) begin
                in_packet = 1'b0;
            end
        end
    endtask

    // Add queue to incoming msgs
    function void store_queue(byte_queue queue);
        incoming_msgs.push_back(queue);
    endfunction

    // Compare msgs
    task compare_msgs();
        byte_queue incoming_msg;
        byte_queue monitored_msg;

        // Track monitor msg index
        int i = 0;

        // Verify msgs forever
        forever begin
            wait(this.msg_queue.size() > i && this.incoming_msgs.size() > i);

            // Get first item
            incoming_msg  = this.incoming_msgs[i];
            monitored_msg = this.msg_queue[i];

            // Verify each byte
            while (incoming_msg.size() > 0 && monitored_msg.size() > 0) begin
                if (incoming_msg.pop_front() != monitored_msg.pop_front()) begin
                    $fatal("Miscompare");
                end
            end

            // Verify both msgs had the same size
            if (incoming_msg.size() > 0 || monitored_msg.size() > 0) begin
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
        $display(incoming_msgs.size());
        $display("Received DUT msgs:");
        $display(msg_queue.size());
    endtask
endclass
