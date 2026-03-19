import avalon_st_agent_pack::*;

class avalon_st_agent #(parameter int DATA_WIDTH_IN_BYTES = 4, parameter int OPERATION_MODE = MASTER, parameter int READY_P = 100);

    // Create vif to manipulate
    virtual avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif;

    // Constructor to assign vif.
    function new(virtual avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif);
        this.vif = vif;
    endfunction

    // Pops a word (DATA_WIDTH_IN_BYTES wide) from the queue and returns it, if the queue becomes empty
    // returns zeros and outputs the calculated empty value.
    function automatic logic[DATA_WIDTH_IN_BYTES*8-1:0] pop_word(ref byte queue[$], output int empty);
        int inner_empty = 0;
        logic[DATA_WIDTH_IN_BYTES*8-1:0] word;

        // Set each byte of the word to the popped byte / empty (0's)
        for (int i = DATA_WIDTH_IN_BYTES - 1; i >= 0; i--) begin
            if (queue.size() > 0) begin
                word[i*8 +: 8] = queue.pop_front();
            end

            // Pad empty bytes and calc the empty value
            else begin
                word[i*8 +: 8] = 8'h00;
                inner_empty = inner_empty + 1;
            end
        end

        // return word and set empty
        empty = inner_empty;
        return word;
    endfunction

    // Drive master using a byte queue converting it into the avalon_st interface
    task drive_master(byte queue[$]);
        int size;
        int empty;
        int original_size = queue.size();

        // While there is data to send
        while ((size = queue.size()) > 0) begin

            // Set valid
            vif.master_cb.valid <= 1'b1;

            // set SOP EOP conditions
            vif.master_cb.sop   <= (size == original_size);
            vif.master_cb.eop   <= (size <= DATA_WIDTH_IN_BYTES);

            // Pop word into data and evaluate empty
            vif.master_cb.data  <= pop_word(queue, empty);
            vif.master_cb.empty <= empty;

            // Wait until ready.
            @(vif.master_cb);
            wait(vif.master_cb.rdy);
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
