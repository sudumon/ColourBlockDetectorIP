`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2017 12:07:30 AM
// Design Name: 
// Module Name: fsm
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


module fsm(

    input clk,
    input [23:0] pixel_in,
    input sof,
    input eol_ext,
    output [20:0] x_out,
    output [20:0] y_out

    );




    
    wire [31:0] r_min;
    wire [31:0] r_max;
    wire [31:0] g_min;
    wire [31:0] g_max;
    wire [31:0] b_min;
    wire [31:0] b_max;
    reg [31:0] x;
    reg [31:0] y;
    reg [31:0] x_min;
    reg [31:0] x_max;
    reg [31:0] y_min;
    reg [31:0] y_max;    
    reg [31:0] x_min_f;
    reg [31:0] x_max_f;
    reg [31:0] y_min_f;
    reg [31:0] y_max_f;
    reg is_match;  // 1 if pixel matches user-defined limits
    
    wire valid;
    wire [23:0] pixel;    
    wire [7:0] r;
    wire [7:0] g;
    wire [7:0] b;
    wire p_clk;
    
    wire S_AXI_ARESETN;
    
    assign S_AXI_ARESETN = 1;
    assign valid = 1;
    
    assign r_min = 0;
    assign r_max = 255;
    assign g_min = 0;
    assign g_max = 255;
    assign b_min = 0;
    assign b_max = 255;
    
    assign p_clk = clk;
    assign pixel = pixel_in;
    assign r = pixel[23:16];
    assign b = pixel[15:8];
    assign g = pixel[7:0];
    
    assign x_out = x;
    assign y_out = y;
    
     //pixel is matching limits comb logic
    always@(*)
    begin
        if(g >= g_min && g <= g_max && b >= b_min && b <= b_max && r >= r_min && r <= r_max) 
            is_match = 1'b1;
        else
            is_match = 1'b0;
    end           
    
    
    // ================ eol (eol internal) stabilizing fsm ===================
    // inputs: eol_ext, p_clk, reset
    // outpus: eol
    // func: reducing external eol to go high for one clock
    reg [2:0] esf_ps;
    reg [2:0] esf_ns;
    reg eol;
    
    parameter ESF_RESET  = 3'b001,
              ESF_HIGH = 3'b010,
              ESF_LOW = 3'b100;
         
    // present state logic          
    always@(posedge p_clk)
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            esf_ps <= ESF_RESET; 
        else
            esf_ps <= esf_ns;
    end
    
    // next state logic
    always@(*)
    begin
       case(esf_ps)
        ESF_RESET:
        begin
             if(eol_ext)
                 esf_ns = ESF_HIGH;
             else
                 esf_ns = ESF_RESET;
        end
        ESF_HIGH:
        begin
             if(eol_ext)
                 esf_ns = ESF_LOW;
             else
                 esf_ns = ESF_RESET;  
        end
        ESF_LOW:
        begin
             if(eol_ext)
                 esf_ns = ESF_LOW;
             else
                 esf_ns = ESF_RESET;
        end       
        default:
             esf_ns = ESF_RESET;
        endcase
    end
    
    // logic for eol in current state
    always@(*)
    begin
       case(esf_ps)
       ESF_RESET:
       begin
            eol = 1'b0;
       end
       ESF_HIGH:
       begin
            eol = 1'b1;
       end
       ESF_LOW:
       begin
            eol = 1'b0;
       end   
       default:
       begin
           eol = 1'b0;
       end
       endcase
    end
    
    // ================= end of esf (eol stabilizing fsm) =================
    
    
    //logic for x-y location
    always@(posedge p_clk)
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            x <= 0;
            y <= 0;
        end
        else
        begin        
            if (sof) // || y == (height - 1) )
            begin
                x <= 0;
                y <= 0;
            end
            else
            begin
                if (eol) // (x == (width - 1))
                begin
                    x <= 0;
                    y <= y + 1;
                end
                else if (valid & !eol_ext)
                begin
                    x <= x + 1;
                end  
            end
        end
    end
    
    
        //states 
    reg[5:0] s;
    reg [5:0] ns;
    
    parameter RESET  = 6'b000001,
              NOTHING = 6'b000010,
              DETECTING = 6'b000100,
              DONE_LINE = 6'b001000,
              NOT_DONE = 6'b010000,
              DONE = 6'b100000;
              
    //present state logic          
    always@(posedge p_clk)
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            s <= RESET; 
        else
            s <= ns;
    end
    

    
    //next state logic
    always@(*)
    begin
       case(s)
       RESET:
       begin
            if(is_match)
                ns = DETECTING;
            else
                ns = NOTHING;
       end
       NOTHING:
       begin
            if(sof)
                ns = RESET;
            else if (is_match)
                ns = DETECTING;
            else
                ns = NOTHING;
                
            
       end
       DETECTING:
       begin
            if(sof)
                ns = RESET;
            else if(eol)
                ns = NOT_DONE;
            else if (!is_match)
                ns = DONE_LINE;
            else
                ns = DETECTING;
            
       end   
       DONE_LINE:
       begin
            if(sof)
                ns = RESET;
            else if(eol)
                ns = NOT_DONE;
            else
                ns = DONE_LINE;
       end
       NOT_DONE:
       begin
            if(sof)
                ns = RESET;
            else if(eol)
                ns = DONE;
            else if(is_match)
                ns = DETECTING;
            else
                ns = NOT_DONE;
       end
       DONE:
       begin
            if(sof)
                ns = RESET;
            else
                ns = DONE;
       end       
       default:
            ns = RESET;
       endcase
    end
    
    //logic in current state
    always@(posedge p_clk)
    begin
       case(s)
       RESET:
       begin
    
            x_min <= 32'hffffffff;
            y_min <= 32'hffffffff;    
            x_max <= 0;
            y_max <= 0;

            x_min_f <= x_min;
            x_max_f <= x_max;
            y_min_f <= y_min;
            y_max_f <= y_max;
            
       end
       NOTHING:
       begin
            
       end
       DETECTING:
       begin
            if (x < x_min)
                x_min <= x;
            
            if (y < y_min)
                y_min <= y;
            
            if(x > x_max)
                x_max <= x;
            
            if(y > y_max)
                y_max <= y;
       end   
       DONE_LINE:
       begin
          
       end
       NOT_DONE:
       begin
       
       end
       DONE:
       begin
           x_min_f <= x_min;
           x_max_f <= x_max;
           y_min_f <= y_min;
           y_max_f <= y_max;       
       end
       default:
       begin
       end
       endcase
    end





endmodule
