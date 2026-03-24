import avalon_st_agent_pack::*;

class avalon_st_monitor #(parameter int DATA_WIDTH_IN_BYTES = 4);
    
    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new(virtual avalon_st_if vif);
        this.vif = vif;        
        
        // Start separate thread to monitor (without halting the software)
        fork
            monitor_invalid_interface();
            monitor_msgs();
        join_none
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    // Drive master using a byte queue converting it into the avalon_st interface
    task monitor_msg(output byte_queue queue);
    
        // Received words queue
        byte_queue word_received;
        byte_queue received_queue = {};
    
        // Is the monitor in a packet?
        bit in_packet = 1'b0;

        // Error tracking vars
        bit eop_received  = 1'b0;
        bit invalid_input = 1'b0;

        // Listen to transactions
        do begin

            // Sync to clocking block
            @(vif.monitor_cb);

            // Check if transaction occurred
            if (vif.monitor_cb.rdy && vif.monitor_cb.valid) begin
                
                // Check eop and sop
                if (vif.monitor_cb.sop) begin
                    in_packet = 1'b1;
                end
                if (vif.monitor_cb.eop) begin
                    eop_received = 1'b1;
                end

                // Pack received word.
                word_received = {>>$size(byte){vif.monitor_cb.data}};

                // Push word into queue, and apply empty only at EOP
                if (eop_received) begin
                    received_queue = {
                        received_queue,
                        word_received[0 : word_received.size() - vif.monitor_cb.empty - 1]
                    }; 
                end else begin
                    // received_queue.push_back(word_received); 
                    received_queue = {
                        received_queue,
                        word_received
                    };
                end
            end
        end while (!(in_packet && eop_received));

        // Set output to queue
        queue = received_queue;
    endtask

    // Check for invalid avalon st interface
    task monitor_invalid_interface();
        forever begin

            // Sync to clocking block
            @(vif.monitor_cb);

            // Check for valid out of packet (also checks multiple EOPs)
            if (!in_packet && vif.monitor_cb.valid && !vif.monitor_cb.sop) begin
                $fatal("Valid out of packet");
                invalid_input = 1'b1;
            end

            // Check for multiple SOPs (without proceeding EOP)
            if (in_packet && vif.monitor_cb.valid && vif.monitor_cb.sop) begin
                $fatal("Multiple SOPs");
                invalid_input = 1'b1;
            end

            // Check if empty is in valid range
            if (vif.monitor_cb.valid && (vif.monitor_cb.empty >= DATA_WIDTH_IN_BYTES)) begin
                $fatal("BAD empty value");
                invalid_input = 1'b1;
            end
        end
    endtask

    task monitor_msgs();
        byte_queue queue;

        forever begin
            monitor_msg(queue);

            $display($time);
            $display("Found packet:");
            $display(queue);
            $display(queue.size());
        end
    endtask
endclass
