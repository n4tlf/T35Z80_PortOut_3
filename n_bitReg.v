/************************************************************************
*   FILE:   n_bitReg.v     TFOX    Oct. 12, 2022   Ver. 0.1        		*
*           Default size is an eight bit egister, with load and clear   *
*   TFOX, N4TLF  Oct. 12, 2022   You are free to use it                 *
*       however you like.  No warranty expressed or implied             *
************************************************************************/

module n_bitReg
#(
    parameter N = 8)            // default size is eight bits
    (input  load,               // out = in as long as LOAD is high
     input  clock,              // Clock input is used to check status
     input  clr,                // pos edge clear will set output to zero
     input  [N-1:0] inData,     // register Data input
     output reg [N-1:0] regOut  // register data output
     );
     
always @(posedge clock or posedge clr) begin
    if(clr == 1)                // if clear is set to one...
        regOut <= 0;            // clear register output to zero
    else if(load == 1)          // if load is high...
        regOut <= inData;       // just have Data OUT = Data IN
	end
        
endmodule

