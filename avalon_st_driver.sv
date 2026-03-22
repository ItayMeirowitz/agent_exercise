import avalon_st_agent_pack::*;

class avalon_st_driver #(parameter int DATA_WIDTH_IN_BYTES = 4, parameter int OPERATION_MODE = MASTER, parameter int READY_P = 100);
    
    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new(virtual avalon_st_if vif);
        this.vif = vif;
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    // Drive master using a byte queue converting it into the avalon_st interface
    task drive_master(byte queue[$]);
        int unsigned size;

        // Pack byte queues into words
        logic[DATA_WIDTH_IN_BYTES*8-1:0] words[$] = {>>{queue}};

        // Calc empty value
        int unsigned empty = (DATA_WIDTH_IN_BYTES - (queue.size() % DATA_WIDTH_IN_BYTES)) % DATA_WIDTH_IN_BYTES;

        // Store SOP and EOP for ease of read.
        logic sop;
        logic eop;

        // Store the original amount of words for SOP
        int unsigned original_size = words.size();

        // Sync to clocking block
        @(vif.master_cb);

        // While there is data to send
        while ((size = words.size()) > 0) begin
            sop = (size == original_size);
            eop = (size == 1);

            // Set valid
            vif.master_cb.valid <= 1'b1;

            // set SOP EOP conditions
            vif.master_cb.sop   <= sop;
            vif.master_cb.eop   <= eop;

            // Pop word into data and evaluate empty
            vif.master_cb.data  <= words.pop_front();
            vif.master_cb.empty <= eop ? empty : 0;

            // Wait for handshake
            @(vif.master_cb iff vif.master_cb.rdy);
        end

        // Set default values
        vif.CLEAR_MASTER_CB();
        @(vif.master_cb);
    endtask

    // Drive slave avalon_st interface ready signal based on the ready probability. 
    task drive_slave();
        int randint;

        // Endless loop controlling ready
        forever begin

            // Generate random number between 1 and 100
            randint = $urandom_range(1, 100);

            // If the number is larger than READY_P lower ready
            vif.slave_cb.rdy <= (randint <= READY_P);
            @(vif.slave_cb);
        end
    endtask

    // Drive function for both slave and master
    task drive(byte queue[$] = {});
        if (OPERATION_MODE == MASTER) begin
            drive_master(queue);
        end else if (OPERATION_MODE == SLAVE) begin
            drive_slave();
        end else begin
            $fatal("Unimplemented drive mode.");
        end
    endtask
endclass
