///////////////////////////////////////////////////////////////////////////////
//
// Project Name: 
// Module Name:   address_decoder
// Designer:      Rehan Ejaz
// Description:   Address decoder module that decode the write address
//                and this decoded address will used for enabling register.
///////////////////////////////////////////////////////////////////////////////

module address_decoder #(
     parameter NUM_REG = 32 
)(    

     input  logic [$clog2(NUM_REG)-1:0] address,     //Write address value.
     input  logic                       wr_en,       //Write enable.
     output logic [NUM_REG-1:0]         decoded_addr //Decoded address
);
     
    //////////////////////////////////////////////////////////////////////////////
    //                      LOGIC SIGNALS                                        
    /////////////////////////////////////////////////////////////////////////////

     logic [NUM_REG-1:0] decoded_value = 1; 
    
    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////
    
    //Decoding address from write address in the basis of write enable.
    assign decoded_addr
        = (wr_en) ? decoded_value << address
                  : 1 >> decoded_value ;

endmodule
