/********************************************************************
*   FILE:   cpuDIMux.v      Ver 0.1         Oct. 12, 2022           *
*                                                                   *
*   This function selects which device's DATA OUT goes into the Z80 *
*   CPU DATA INPUT bus at any given time. It uses the device's      *
*   select line to enable that device's DATA OUT signals            *
*   The Efinix FPGAs do NOT have internal tri-state buffering       *
*   capabilities, so this is especially important to prevent        *
*   clashing of signals of the Z80 DATA INPUT bus.                  *
*   TFOX, N4TLF  Oct. 12, 2022   You are free to use it             *
*       however you like.  No warranty expressed or implied         *
********************************************************************/

module cpUDIMux
    (
    input [7:0] romData,    // Project 3 only uses the ROM data
    input   rom_cs,         // use ROM CS to enable ROM Data to CPU Data IN
    input   pll0_100MHz,    // faster clock for always triggering
    output reg [7:0] outData  // MUX Data OUT to CPU Data IN bus
    );

always @(posedge pll0_100MHz) begin
    if (rom_cs)                 // IF ROM Chip Select is active
        outData = romData;     // send ROM data to temporary reg
    else
        outData = 8'h00;        // otherwise execute a NOP for now
    end                         // whenever not reading from ROM
    
endmodule
