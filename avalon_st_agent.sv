import avalon_st_agent_pack::*;

class avalon_st_agent #(parameter DATA_WIDTH_IN_BYTES = 4, parameter OPERATION_MODE = MASTER);

    typedef logic[DATA_WIDTH_IN_BYTES*8-1:0] data_arr;

    virtual avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif;

    function new(virtual avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif);
        this.vif = vif;
    endfunction

    function void shift_left_bytes(ref byte queue[$], int shift);
        int original_size = queue.size();

        if (shift <= 0)
            return;

        // If shift is greater or equal return all zeros
        if (shift >= original_size) begin
            queue.delete();
            repeat (original_size)
                queue.push_back(8'h00);
            return;
        end

        // Pad zeros at the end to align bus
        repeat (shift)
            queue.push_back(8'h00);
    endfunction

    function data_arr pop_word(ref byte queue[$], output int empty);

        data_arr word;
        int inner_empty = 0;
        word = '0;

        for (int i = DATA_WIDTH_IN_BYTES - 1; i >= 0; i--) begin
            if (queue.size() > 0) begin
                word[i*8 +: 8] = queue.pop_front();
            end
            else begin
                word[i*8 +: 8] = 8'h00;
                inner_empty = inner_empty + 1;
            end
        end

        empty = inner_empty;
        return word;
    endfunction

    task drive(byte queue[$]);
        // logic[vif.DATA_WIDTH_IN_BYTES - 1 : 0] word;
        int empty;
        int size;
        int original_size = queue.size();

        while ((size = queue.size()) > 0) begin
            @(posedge vif.clk);
            vif.valid <= 1'b1;

            // SOP EOP conditions
            vif.sop   <= (size == original_size);
            vif.eop   <= (size <= vif.DATA_WIDTH_IN_BYTES);

            // Pop word into data and evaluate empty
            vif.data  <= pop_word(queue, empty);
            vif.empty <= empty;


            // vif.empty <= vif.eop ? vif.DATA_WIDTH_IN_BYTES - size : 0;
            // if (vif.eop) shift_left_bytes(queue, vif.empty);

            // Wait until ready.
            while (!vif.rdy);
        end

        @(posedge vif.clk);
        vif.valid <= 1'b0;
        vif.sop   <= 1'b0;
        vif.eop   <= 1'b0;
        vif.data  <= '0;
        vif.empty <= '0;
    endtask
endclass
