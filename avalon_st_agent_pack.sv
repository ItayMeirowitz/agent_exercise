
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

    // Time controls
    localparam int unsigned RST_TIME = 20;
    localparam int unsigned CLK_TOGGLE = 5;

    // Amount of test queues
    localparam int unsigned NUM_OF_MSGS = 10;
    localparam int unsigned MASTER_VALID_P = 50;
    localparam int unsigned SLAVE_RDY_P = 50;

    // Clks between packets sent
    localparam int unsigned MIN_INTERVAL = 0;
    localparam int unsigned MAX_INTERVAL = 500;

    // Queue sizes
    localparam int unsigned MIN_SIZE = 1; 
    localparam int unsigned MAX_SIZE = 100; 
endpackage
