/********************************************************************************
*   Clock speed INPUT Multiplexer.      Version 0.2     T.FOX                   *
*   This module selects which clock is sent to the rest of the logic, based     *
*       on DIP switches 7 and 6.  DN DN (11) selects the fastest 2MHz clock     *
*   Note that the Z80 core is actually driven after a divide-by-five of this    *
*       clock inside the microcomputer.vhdl block.  So 2MHz actually drives     *
*       the Z80 coreat 400kHz, while all logic external to the Z80 core         * 
*       runs at 2MHz                                                            * 
*   TFOX, N4TLF  Oct. 12, 2022   You are free to use it                         *
*       however you like.  No warranty expressed or implied                     *
********************************************************************************/

module  ClockMux(
    input           MHz2,           // 2MHz clock to logic if SW 7,6 = 11 (DN DN)
    input           MHz1,           // 1MHz clock to logic if SW 7,6 = 01 (UP DN)
    input           KHz31,          // 31kHz clock to logic if SW 7,6 = 10 (DN UP)
    input           Hz250,          // 250Hz clock to ogic if SW 7,6 = 00 (UP UP)
    input           pll0_100MHz,    // fast clock for always block
    input   [1:0]   sw,             // Switches 7 & 6 input
    output  reg    cpuclk           // selected clock output to logic
    );

always @(posedge pll0_100MHz) begin
    if (sw == 2'b11)                // if both DOWN, output clock is 2MHz
        cpuclk = MHz2;
    else if (sw == 2'b01)           // if UP DOWN, output clock is 1MHz
        cpuclk = MHz1;
    else if (sw == 2'b10)           // if DOWN UP, output clock is approx 31kHz
        cpuclk = KHz31;
    else                            // otherwise, use a very slow 250Hz
        cpuclk = Hz250;
    end
    
endmodule
    
