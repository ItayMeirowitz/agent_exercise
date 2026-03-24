import avalon_st_agent_pack::*;

class avalon_st_sequencer;

    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    queue_arr current_arr;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new();
        this.current_arr = {};
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    // Add queue to storage
    function void store_queue(byte_queue queue);
        current_arr.push_back(queue);
    endfunction

    // Get first queue, if there are none, wait until there is.
    task get_first_item(output byte_queue queue);
        wait(current_arr.size() > 0);
        queue = current_arr.pop_front();
    endtask
endclass