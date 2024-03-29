`include "/mnt/d/CPU/CxkPU/riscv/src/definition.v"
// `include "D:\CPU\CxkPU\riscv\src\definition.v"
module bp(
    input wire clk,
    input wire rst,
    input wire rdy,
    //with fetcher
    input [7:0] in_fetcher_tag,
    output wire out_fetcher_jump_res,
    
    // from rob commit to modify the table
    input in_rob_bp_res,
    input [7:0] in_rob_tag,
    input in_rob_jump_res

);

    reg [1:0] predictor_table [255:0];
 assign out_fetcher_jump_res = predictor_table[in_fetcher_tag][1];
    integer i;
    always@(posedge clk) begin 
        if(rst) begin 
            for(i=0;i<256;i=i+1) begin 
                predictor_table[i] <= 2'b10;
            end
        end else if(rdy) begin 
            if(in_rob_bp_res) begin 
                if(in_rob_jump_res) begin 
                    predictor_table[in_rob_tag] <= predictor_table[in_rob_tag] + ((predictor_table[in_rob_tag] == 2'b11) ? 0 : 1);
                end else begin 
                    predictor_table[in_rob_tag] <= predictor_table[in_rob_tag] + ((predictor_table[in_rob_tag] == 2'b00) ? 0 : -1);
                end 
            end
           
        end
    end
endmodule