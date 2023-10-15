///////////////////////////////////////////////////////////////////////////////
//
// Project Name:  Hydra 
// Module Name:   vrf
// Designer:      Rehan Ejaz
// Description:   Fully parametrized vector register file. Multiple read ports
//                and write ports (all individual single-wide ports). Number
//                of register and datapath width is also parameterized. 
///////////////////////////////////////////////////////////////////////////////

module vrf 
#(
    parameter NUM_WR_PORTS = 8,              //Number of Write ports
    parameter NUM_RD_PORTS = 8,              //Number of Read  ports
    parameter NUM_REG      = 32,             //Number of registers
    parameter DATA_SIZE    = 2048,           //Vector datapath width
    localparam ADDRESS     = $clog2(NUM_REG) //Address port width
) (
    input  logic clk,
    input  logic arst_n,
    input  logic [ADDRESS-1:0      ] wr_addr [NUM_WR_PORTS-1:0], //Write address
    input  logic [DATA_SIZE-1:0    ] wr_data [NUM_WR_PORTS-1:0], //Write data
    input  logic                     wr_en   [NUM_WR_PORTS-1:0], //Write enable
    input  logic [(DATA_SIZE/8)-1:0] wr_strb [NUM_WR_PORTS-1:0], //Write strobe
    input  logic [ADDRESS-1:0      ] rd_addr [NUM_RD_PORTS-1:0], //Read address
    output logic [DATA_SIZE-1:0    ] rd_data [NUM_RD_PORTS-1:0]  //Read data
);
    //////////////////////////////////////////////////////////////////////////////
    // Logic Signals                                        
    /////////////////////////////////////////////////////////////////////////////
                      
    logic [NUM_REG-1:0      ] w_en;                             //Register enable for write
    logic [DATA_SIZE-1:0    ] win_wr_data  [ NUM_REG-1:0     ]; //Winner write data to write in register
    logic [(DATA_SIZE/8)-1:0] win_wr_strb  [ NUM_REG-1:0     ]; //Winner write strobe from multiple strobe ports.
    logic [DATA_SIZE-1:0    ] register     [ NUM_REG-1:0     ]; //Number of register depend upon the NUM_REG parameter.  
    logic [NUM_REG-1:0      ] decoded_addr [ NUM_WR_PORTS-1:0]; //Decoded address that will used to create the register enable.
    logic [NUM_WR_PORTS-1:0 ] addr_dec_sel [ NUM_REG-1:0     ]; //Address decode select is used to select the winner write data.
    logic [NUM_REG-1:0      ] match_found;                      //Winner data enable for write

    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////
    //            ADDRESS DECODER LOGIC
    ///////////////////////////////////////////////////
    //It decode write address that will used for register enable value.
    generate
    for (genvar i = 0; i < NUM_WR_PORTS; i++) begin
        address_decoder #( .NUM_REG(NUM_REG))
            u_address_decoder(
                .address     ( wr_addr[i]      ),
                .wr_en       ( wr_en[i]        ),
                .decoded_addr( decoded_addr[i]));
    end
    endgenerate

    ///////////////////////////////////////////////////
    //             WRITE DATA SELECT
    ///////////////////////////////////////////////////
    //Selecting specific decoded address bits for address decode select w.r.t-
    //number of register and number of write ports.
    generate
        for(genvar i = 0; i < NUM_REG; i++)
            for(genvar j = 0; j < NUM_WR_PORTS; j++)
                assign addr_dec_sel[i][j] = decoded_addr[j][i];
    endgenerate
    
    //This module will select the write data and strb for each register-
    //write from multiple write data and strb from parameterized write ports.
    generate
        for (genvar i = 0; i < NUM_REG; i++) begin
            wr_data_sel # (
                .NUM_WR_PORTS( NUM_WR_PORTS   ),
                .NUM_RD_PORTS( NUM_RD_PORTS   ),
                .DATA_SIZE   ( DATA_SIZE      )
            ) u_wr_data_sel(
                .wr_data     ( wr_data        ),
                .addr_dec_sel( addr_dec_sel[i]),
                .wr_strb     ( wr_strb        ),
                .wr_en       ( wr_en          ),
                .win_wr_data ( win_wr_data[i] ),
                .win_wr_strb ( win_wr_strb[i] ),
                .match_found ( match_found[i] )
            );
        end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////
   
    ////////////////////////////////////////////////////
    //             REGISTER WRITE LOGIC
    ////////////////////////////////////////////////////
  
    //Perfoming logical OR operation with decode addresses for generating write- 
    //enable value for the registers
    integer g;
    always_comb begin
        w_en = 0; // Initialize w_en to 0
        for (g = 0; g < NUM_WR_PORTS; g++) begin
            w_en = w_en | decoded_addr[g]; // Perform logical OR operation
        end 
    end
    //Register write opertation w.r.t register enable and match found value.
    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            for (int i=0; i<NUM_REG; i++) begin
                register[i] <= 'b0;
            end
        end
        else begin
            for (int k=0; k<NUM_REG; k++)
            begin
                if (w_en[k] && match_found[k])
                begin
                    for(int j = 0; j < DATA_SIZE/8; j++)
                    begin
                        // Byte enable
                        if(win_wr_strb[k][j])
                        begin
                            register[k][(8*(j+1))-1 -:8] <= win_wr_data[k][(8*(j+1))-1 -: 8];
                        end
                    end
                end
            end
        end 
    end

    ////////////////////////////////////////////////////
    //            REGISTER READ LOGIC
    ////////////////////////////////////////////////////

    //Fully combinational Read. Since, no read enable.
    generate
        for (genvar r = 0; r < NUM_RD_PORTS; r++) begin
            assign rd_data[r] = register[rd_addr[r]];
        end
    endgenerate
 endmodule

