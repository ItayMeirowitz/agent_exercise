import avalon_st_agent_pack::*;

class avalon_st_driver #(parameter int DATA_WIDTH_IN_BYTES = 4, parameter int OPERATION_MODE = MASTER, parameter int VALID_READY_P = 100);
    
    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new(virtual avalon_st_if vif);
        this.vif = vif;
        
        fork
            if (OPERATION_MODE == SLAVE) begin
                drive_slave();
            end    
        join_none
    endfunction

    /*-------------------------------------------------------------------------------
    -- Constraints.
    -------------------------------------------------------------------------------*/
    rand bit rdy_rand;
    rand bit valid_rand;

    // Constraints for rdy and valid.
    constraint rdy_dist {
        rdy_rand dist {
            1 := VALID_READY_P,
            0 := 100 - VALID_READY_P
        };
    }
    constraint valid_dist {
        valid_rand dist {
            1 := VALID_READY_P,
            0 := 100 - VALID_READY_P
        };
    }

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

        // Store the original amount of words for SOP
        int unsigned original_size = words.size();

        // Sync to clocking block
        @(vif.master_cb);

        // While there is data to send
        while ((size = words.size()) > 0) begin

            // Randomize to get valid_rand
            assert(this.randomize());
            if (valid_rand) begin

                // Set valid
                vif.master_cb.valid <= 1'b1;

                // set SOP EOP conditions
                vif.master_cb.sop   <= (size == original_size);
                vif.master_cb.eop   <= (size == 1);

                // Pop word into data and evaluate empty
                vif.master_cb.data  <= words.pop_front();
                vif.master_cb.empty <= (size == 1) ? empty : $urandom();

                // Wait for handshake
                @(vif.master_cb iff vif.master_cb.rdy);
            end else begin
                vif.CLEAR_MASTER_CB();
                @(vif.master_cb iff vif.master_cb.rdy);
            end
        end

        // Set default values
        vif.CLEAR_MASTER_CB();
        @(vif.master_cb);
    endtask

    // Drive slave avalon_st interface ready signal based on the ready probability. 
    task drive_slave();
        int randint;

        // Endless loop controlling ready
        forever @(vif.slave_cb) begin

            // Randomize to get rdy_rand
            assert(this.randomize());
            vif.slave_cb.rdy <= rdy_rand;
        end
    endtask
endclass
