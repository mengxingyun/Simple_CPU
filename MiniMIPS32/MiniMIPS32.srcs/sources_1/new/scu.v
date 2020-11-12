`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/05 10:32:10
// Design Name: 
// Module Name: scu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module scu(
    input wire                    cpu_rst_n,
    input wire                    stallreq_id,//“Î¬Î‘›Õ£–≈∫≈
    input wire                    stallreq_exe, //÷¥––‘›Õ£–≈∫≈
    
    output wire [`STALL_BUS]       stall

    );
    assign stall = (cpu_rst_n == `RST_ENABLE) ? 4'b0000 : 
                   (stallreq_exe == `STOP) ? 4'b1111 : 
                   (stallreq_id == `STOP) ? 4'b0111 : 4'b0000;
endmodule
