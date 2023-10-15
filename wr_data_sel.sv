////////////////////////////////////////////////////////////////////////////////
//
// Project Name: eGPU
// Module Name:   wr_data_sel
// Designer:      Rehan Ejaz
// Description:   Select write data and write strobe from multiple write 
//                port and send the winner write data and winner write 
//                strobe to the register file.
///////////////////////////////////////////////////////////////////////////////

module wr_data_sel 
#(
    parameter NUM_WR_PORTS = 8,   //Input ports
    parameter NUM_RD_PORTS = 8,   //Output ports
    parameter DATA_SIZE    = 2048 //Vector datapath width
)(

    input  logic [DATA_SIZE-1:0    ] wr_data     [NUM_WR_PORTS-1:0], //Write data value from write ports (parameterized write ports)
    input  logic [NUM_WR_PORTS-1:0 ] addr_dec_sel,                   //Address decode generated in module addr_dec
    input  logic                     wr_en       [NUM_WR_PORTS-1:0], //Write enable
    input  logic [(DATA_SIZE/8)-1:0] wr_strb     [NUM_WR_PORTS-1:0], //Write strobe
    output logic [DATA_SIZE-1:0    ] win_wr_data,                    //Winner write data from multiple data ports.
    output logic                     match_found,                    //Winner data valid
    output logic [(DATA_SIZE/8)-1:0] win_wr_strb                     //Winner write srtobe from multiple strobe ports.

);
    //Selecting the winner data and winner strobe from-
    //multiple write ports w.r.t enable and specific-
    //bits of decoded address value.
    always_comb begin
        for (int i = 0; i < NUM_WR_PORTS; i = i + 1) begin
            if (addr_dec_sel[i] && wr_en[i] ) begin
                win_wr_data = wr_data[i];
                win_wr_strb = wr_strb[i];
                match_found = 'd1; //if any match found, signal will be high.
                break;
            end
            else begin 
                win_wr_data = 'd0;
                match_found = 'd0;
            end
        end
    end
						  
endmodule
