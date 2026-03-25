import avalon_st_agent_pack::*;

class avalon_st_monitor #(parameter int DATA_WIDTH_IN_BYTES = 4);
    
    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;
    queue_arr msg_queue;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new(virtual avalon_st_if vif);
        this.vif = vif;        
        
        // Start separate thread to monitor (without halting the software)
        fork
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
                received_queue.delete();
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
            if (vif.monitor_cb.sop) in_packet = 1'b1;
            if (vif.monitor_cb.eop) in_packet = 1'b0;
        end
    endtask
endclass
