`include "/mnt/d/AAAAAAAA_pers.files/大二 上/System Arch/CxkPU/riscv/src/definition.v"
module Fetcher(
    input wire clk,
    //rst is currently false
    input wire rst,
    input wire rdy,

    // to decoder
    output reg [`INS_TYPE] inst_to_dec,
    output reg [`ADDR_TYPE] pc_to_dec,
    output reg [`ADDR_TYPE] rollback_pc_to_dec,
    output reg predicted_jump_to_dec,
    output reg ok_flag_to_dec,

    // cache full 
    input wire global_full,


    

    // port with memctrl
    // to memctrl
    output reg [`ADDR_TYPE] pc_to_mc,
    output reg ena_to_mc,
    output reg drop_flag_to_mc,
    // from memctrl
    input wire ok_flag_from_mc,
    input wire [`INS_TYPE] inst_from_mc,
    
    // with predictor
    output wire [`ADDR_TYPE] query_pc_to_pdc,
    output wire [`INS_TYPE] query_inst_to_pdc,
    input wire predicted_jump_from_pdc,
    input wire [`ADDR_TYPE] predicted_imm_from_pdc
);
    parameter FETCH_STATUS=1,STALL_STATUS=0;
    reg[0:0]status;
    reg[`ADDR_TYPE]pc,pc_mem;

`define ICACHE_SIZE 256
`define INDEX_RANGE 9:2
`define TAG_RANGE 31:10
reg [`ICACHE_SIZE-1:0] valid ;
reg [`TAG_RANGE] tag_store [`ICACHE_SIZE-1:0];
reg [`INS_TYPE]data_store[`ICACHE_SIZE-1:0] ;

wire hit=(valid[pc[`INDEX_RANGE]])&&(tag_store[pc[`INDEX_RANGE]]==pc[`TAG_RANGE]);
wire [`INS_TYPE] returned_inst = (hit) ? data_store[pc[`INDEX_RANGE]] : `ZERO_WORD;
assign query_pc_to_pdc = pc;
assign query_inst_to_pdc = returned_inst;

always @(posedge clk ) begin
    if rdy begin
      if (hit && global_full == `FALSE) begin
            // submit the inst to id
            pc_to_dec <= pc;

            //predicted_jump_to_dec <= predicted_jump_from_pdc;
            pc <= pc + `NEXT_PC;
            inst_to_dec <= returned_inst;
            ok_flag_to_dec <= `TRUE;
        end
        else begin
          ok_flag_to_dec<=`FALSE;

        end
        drop_flag_to_mc <= `FALSE;
        ena_to_mc <= `FALSE;

        if (status == STALL_STATUS) begin
            ena_to_mc <= `TRUE;
            pc_to_mc <= mem_pc;
            status <= FETCH_STATUS;
        end
        else begin
            // memctrl ok
            if (ok_flag_from_mc) begin
                // put into icache
                mem_pc <= ((mem_pc == pc) ? mem_pc + `NEXT_PC : pc);
                status <= STATUS_IDLE;
                valid[mem_pc[`INDEX_RANGE]] <= `TRUE;
                tag_store[mem_pc[`INDEX_RANGE]] <= mem_pc[`TAG_RANGE];
                data_store[mem_pc[`INDEX_RANGE]] <= inst_from_mc;
            end
        end 
    end
end
endmodule 