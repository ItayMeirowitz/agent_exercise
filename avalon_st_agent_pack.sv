
// Consts avalon_st_agent_pack
package avalon_st_agent_pack;
    
    // Typedef of byte queue to allow returning it from functions
    typedef byte byte_queue[$];

    // Typedef of array of byte queues returning from functions
    typedef byte_queue queue_arr[$];

    // Different operation modes of the agent
    typedef enum int unsigned { 
        MASTER, 
        SLAVE 
    } operation_modes;
endpackage
