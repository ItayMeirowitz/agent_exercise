import avalon_st_agent_pack::*;

class avalon_st_driver #(parameter int DATA_WIDTH_IN_BYTES = 4, parameter int OPERATION_MODE = MASTER, parameter int VALID_READY_P = 100);
    
    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;
    avalon_st_sequencer sequencer;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new(virtual avalon_st_if vif, avalon_st_sequencer sequencer = null);
        this.vif = vif;
        this.sequencer = sequencer;
        
        // Start separate thread to drive slave lines (without halting the software)
        fork
            if (OPERATION_MODE == SLAVE) begin
                drive_slave();
            end
        join_none
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    // Generate random bit based on the probability
    function bit rand_with_prob();
        std::randomize(rand_with_prob) with {
            rand_with_prob dist {
                1 := VALID_READY_P,
                0 := 100 - VALID_READY_P
            };
        };
    endfunction

    // Generate and assign random values for the vif with valid = 0.
    function void randomize_interface();
        
        // Always non-valid
        vif.master_cb.valid <= 1'b0;

        // set SOP EOP conditions
        vif.master_cb.sop <= $urandom();
        vif.master_cb.eop <= $urandom();

        // Pop word into data and evaluate empty
        vif.master_cb.data  <= $urandom();
        vif.master_cb.empty <= $urandom();
    endfunction

    // Drive master using a byte queue converting it into the avalon_st interface
    task drive_master(byte_queue queue);
        int unsigned size;

        // Pack byte queues into words
        bit[DATA_WIDTH_IN_BYTES*8-1:0] words[$] = {>>{queue}};

        // Calc empty value
        int unsigned empty = (DATA_WIDTH_IN_BYTES - (queue.size() % DATA_WIDTH_IN_BYTES)) % DATA_WIDTH_IN_BYTES;

        // Store the original amount of words for SOP
        int unsigned original_size = words.size();

        // Sync to clocking block
        @(vif.master_cb);

        // While there is data to send
        while ((size = words.size()) > 0) begin
            if (rand_with_prob()) begin

                // Set valid
                vif.master_cb.valid <= 1'b1;

                // set SOP EOP conditions
                vif.master_cb.sop <= (size == original_size);
                vif.master_cb.eop <= (size == 1);

                // Pop word into data and evaluate empty
                vif.master_cb.data  <= words.pop_front();
                vif.master_cb.empty <= (size == 1) ? empty : $urandom();

                // Wait for handshake
                @(vif.master_cb iff vif.master_cb.rdy);
            end else begin

                // Generate random invalid interface
                randomize_interface();
                @(vif.master_cb);
            end
        end

        // Set default values
        vif.CLEAR_MASTER_CB();
    endtask

    task drive_msgs();
        byte_queue current_queue;

        forever begin
            this.sequencer.get_queue(current_queue);
            drive_master(current_queue);
        end
    endtask

    // Drive slave avalon_st interface ready signal based on the ready probability. 
    task drive_slave();

        // Endless loop controlling ready
        forever @(vif.slave_cb) begin

            // Randomize to get rdy_rand
            vif.slave_cb.rdy <= rand_with_prob();
        end
    endtask
endclass
