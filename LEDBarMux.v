/********************************************************************
*   FILE:   LEDBarMux.v      Ver 0.1         Oct. 12, 2022          *
*                                                                   *
*       SBC LEDs multiplexer used for debugging busses              *
*       Switches 5 & 4 determin multiplexer signal OUT to SBC LEDs  *
*       5 & 4 = 00 = UP UP = Z80 CPU Data OUT bus to LEDs           *
*       5 & 4 = 01 = UP DN = Z80 CPU Data IN bus to LEDs            *
*       5 & 4 = 10 = DN UP OR 5 & 4 = 11 = DN DN = OUT port 256 (FF)*
*   NOTE:  The LEDoutData is inverted since the LEDs are ON if      *
*           the associated Data bit is LOW, NOT HIGH, Keep this in  *
*            mind if using the SBC LEDs driver lines to "scope"     *
*            internal FPGA signals.                                 *
*   TFOX, N4TLF  Oct. 12, 2022   You are free to use it             *
*       however you like.  No warranty expressed or implied         *
********************************************************************/

module LedBarMux
    (
    input [7:0] cpuDO,          // Z80 CPU Data OUTPUT bus
    input [7:0] cpuDI,          // Z80 CPU Data INPUT bus
    input [7:0] portFFDO,       // Out Port 255 (FF hex) data bus
    input [1:0]	sw,             // Switch inputs to determine signal
    input       pll0_100MHz,     // Faster clock for always block
    output reg [7:0] LEDoutData // MUX output to drive the SBC LEDs
    );
    
always @(posedge pll0_100MHz) begin
    if (sw == 2'b0)             // if switches are both UP...
        LEDoutData = ~cpuDO;   // we want to look at CPU Data OUT bus
    else if (sw == 2'b01)       // if switches are (5 4) UP DOWN...
        LEDoutData = ~cpuDI;   // we want to look at CPU Data IN bus
    else
        LEDoutData = ~portFFDO;  // otherwise, display OUT port FF
    end
    
endmodule
