import avalon_st_agent_pack::*;

class avalon_st_agent #(parameter int DATA_WIDTH_IN_BYTES = 4, parameter int OPERATION_MODE = MASTER, parameter int READY_P = 100);

    virtual avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif;

    function new(virtual avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif);
        this.vif = vif;
    endfunction

    function automatic logic[DATA_WIDTH_IN_BYTES*8-1:0] pop_word(ref byte queue[$], output int empty);
        logic[DATA_WIDTH_IN_BYTES*8-1:0] word;
        int inner_empty = 0;

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

        // return and set empty
        empty = inner_empty;
        return word;
    endfunction

    task drive_master(byte queue[$]);
        int empty;
        int size;
        int original_size = queue.size();

        // While there is data to send
        while ((size = queue.size()) > 0) begin

            // Set valid
            vif.valid <= 1'b1;

            // set SOP EOP conditions
            vif.sop   <= (size == original_size);
            vif.eop   <= (size <= DATA_WIDTH_IN_BYTES);

            // Pop word into data and evaluate empty
            vif.data  <= pop_word(queue, empty);
            vif.empty <= empty;

            // Wait until ready.
            do @(posedge vif.clk); while (!vif.rdy);
        end

        // Set default values
        vif.valid <= 1'b0;
        vif.sop   <= 1'b0;
        vif.eop   <= 1'b0;
        vif.data  <= '0;
        vif.empty <= '0;
        @(posedge vif.clk);
    endtask

    task drive_slave();
        int randint;

        // Endless loop controlling ready
        forever begin
            @(posedge vif.clk);

            // Generate random number between 1 and 100
            randint = $urandom_range(1, 100);

            // If the number is larger than READY_P lower ready
            vif.rdy <= (randint <= READY_P);
        end
    endtask

    // Drive function for both slave and master
    task drive(byte queue[$] = {});
        if (OPERATION_MODE == MASTER) begin
            drive_master(queue);
        end else if (OPERATION_MODE == SLAVE) begin
            drive_slave();
        end else begin
            $fatal("Unimplemented mode.");
        end
    endtask
endclass
