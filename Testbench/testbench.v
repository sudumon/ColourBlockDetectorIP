`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2017 12:12:59 AM
// Design Name: 
// Module Name: testbench
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


module testbench(

    );

    
    reg clk;
    reg sof = 0;
    reg eol = 0;
    reg [15:0] counter = 0;
    wire [24:0] x;
    wire [24:0] y;
    wire [24:0] pixel_in;
    
    assign pixel_in = 0;
    
        
    
    fsm f1(
        .clk(clk),
        .pixel_in(pixel_in),
        .sof(sof),
        .eol_ext(eol),
        .x_out(x),
        .y_out(y)
        );
    
    initial
    begin
        clk = 0;
    end
    
    always
    begin
        #5 clk = ~clk;
    end
    
    
    always @ (posedge clk)
    begin
    
        if(counter == 100)
        begin
            sof = 1;
            eol = 0;
            counter = 0;
        end
        else if(counter == 10)
        begin
            sof = 0;
            eol = 1;
            counter = counter + 1;
        end
        else 
        begin
            sof = 0;
            eol = 0;
            counter = counter + 1;
        end
    end
    
endmodule
