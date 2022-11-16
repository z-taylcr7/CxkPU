`include "riscv/src/definition.v"
module Fetcher(
    input wire clk,
    //rst is currently false!
    input wire rst,
    input wire rdy,

    // to decoder
    output reg [`INS_TYPE] inst_to_dec,
    output reg [`ADDR_TYPE] pc_to_dec,
    output reg predicted_jump_to_dec,
    output reg flag_to_dec,

    // cache full 
    input wire cache_full,

    // to memctrl
    output reg [`ADDR_TYPE] pc_to_mc,
    output reg flag_to_mc,
    output reg drop_flag_to_mc,
    // from memctrl
    input wire flag_from_mc,
    input wire [`INS_TYPE] inst_from_mc,
    
    // predictor
    output wire [`ADDR_TYPE] query_pc_to_pdc,
    output wire [`INS_TYPE] query_inst_to_pdc,
    input wire predicted_jump_flag_from_pdc
);
    parameter BUSY_STATUS=1,IDLE_STATUS=0;
    reg[0:0]status;
    reg[`ADDR_TYPE]pc,pc_mem;

    `define ICACHE_SIZE 256
    `define INDEX_RANGE 9:2
    `define TAG_RANGE 31:10
    reg [`ICACHE_SIZE-1:0] valid ;
    reg [`TAG_RANGE] tag_store [`ICACHE_SIZE-1:0];
    reg [`INS_TYPE]data_store[`ICACHE_SIZE-1:0] ;

    wire hit=(valid[pc[`INDEX_RANGE]])&&(tag_store[pc[`INDEX_RANGE]]==pc[`TAG_RANGE]);
    wire [`INS_TYPE] res_inst = (hit) ? data_store[pc[`INDEX_RANGE]] : `ZERO_WORD;

    assign query_pc_to_pdc = pc;
    assign query_inst_to_pdc = res_inst;
    integer i;
always @(posedge clk ) begin
    if (rst)begin
        flag_to_dec <= `FALSE;       
        flag_to_mc <= `FALSE; 
        drop_flag_to_mc <= `FALSE;

        pc <= `ZERO_ADDR;
        pc_mem <= `ZERO_ADDR;

        status <= IDLE_STATUS;
        pc_to_mc <= `ZERO_ADDR;
        pc_to_dec <= `ZERO_ADDR;
        inst_to_dec <= `ZERO_WORD;      
        
        for (i = 0; i < `ICACHE_SIZE; i=i+4) begin
            valid[i] <= `FALSE;
            tag_store[i] <= `ZERO_ADDR;
            data_store[i] <= `ZERO_WORD;
            valid[i+1] <= `FALSE;
            tag_store[i+1] <= `ZERO_ADDR;
            data_store[i+1] <= `ZERO_WORD;
            valid[i+2] <= `FALSE;
            tag_store[i+2] <= `ZERO_ADDR;
            data_store[i+2] <= `ZERO_WORD;
            valid[i+3] <= `FALSE;
            tag_store[i+3] <= `ZERO_ADDR;
            data_store[i+3] <= `ZERO_WORD;
        end
    end
    else if  (rdy) begin
        //todo: rob rollback
        
        //inst in directly from hit 
        if (hit && cache_full == `FALSE) 
            begin
            pc_to_dec <= pc;
            pc <= pc + `NEXT_PC;
            inst_to_dec <= res_inst;
            flag_to_dec <= `TRUE;
            end
        else flag_to_dec<=`FALSE;
        drop_flag_to_mc <= `FALSE;
        flag_to_mc <= `FALSE;

        //work if idle and ready
        if (status == IDLE_STATUS) begin
            flag_to_mc <= `TRUE;
            pc_to_mc <= pc_mem;
            status <= BUSY_STATUS;
        end
        else begin
            if (flag_from_mc) begin
                //put into I-Cache
                pc_mem <= ((pc_mem == pc) ? pc_mem + `NEXT_PC : pc);
                tag_store[pc_mem[`INDEX_RANGE]] <= pc_mem[`TAG_RANGE];
                data_store[pc_mem[`INDEX_RANGE]] <= inst_from_mc;

                valid[pc_mem[`INDEX_RANGE]] <= `TRUE;
                status <= IDLE_STATUS;
            end
        end 
    end
end
endmodule 