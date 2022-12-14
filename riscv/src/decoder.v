`include "riscv/src/definition.v"
`include "riscv/src/decodeunit.v"
module decoder (
     input clk,input rst,input rdy,

    // From Fetcher
    input [`INS_TYPE] in_fetcher_inst,
    input [`DATA_TYPE] in_fetcher_pc,
    input in_fetcher_jump_flag,

    // ask register for source operand status
    output [`REG_POS_TYPE] out_reg_tag1,
    input [`DATA_TYPE] in_reg_value1,
    input [`ROB_POS_TYPE] in_reg_robtag1,
    input in_reg_busy1,

    output [`REG_POS_TYPE] out_reg_tag2,
    input [`DATA_TYPE] in_reg_value2,
    input [`ROB_POS_TYPE] in_reg_robtag2,
    input in_reg_busy2,

    // ask registers to update value
    output reg [`REG_POS_TYPE] out_reg_dest,  //use this == zero to check whether it is send to register
    output [`ROB_POS_TYPE] out_reg_rob_tag,

    // Get free rob entry tag
    input [`ROB_POS_TYPE] in_rob_freetag,

    // ask rob for source operand value
    output [`ROB_POS_TYPE] out_rob_fetch_tag1,
    input [`DATA_TYPE] in_rob_fetch_value1,
    input in_rob_fetch_ready1,
    output [`ROB_POS_TYPE] out_rob_fetch_tag2,
    input [`DATA_TYPE] in_rob_fetch_value2,
    input in_rob_fetch_ready2,

    // ask rob to store entry
    output reg [`DATA_TYPE] out_rob_dest,
    output reg [`OPENUM_TYPE] out_rob_op,
    output reg out_rob_jump_flag,

    // ask rs to store entry
    output reg [`ROB_POS_TYPE] out_rs_rob_tag, //use this == zero to check whether it is send to rs
    output reg [`OPENUM_TYPE] out_rs_op,
    output reg [`DATA_TYPE] out_rs_value1,
    output reg [`DATA_TYPE] out_rs_value2,
    output reg [`ROB_POS_TYPE] out_rs_tag1,
    output reg [`ROB_POS_TYPE] out_rs_tag2,
    output reg [`DATA_TYPE] out_rs_imm,
    // for rs and rob
    output [`DATA_TYPE] out_pc,

    // ask lsb to store entry
    output reg [`ROB_POS_TYPE] out_lsb_rob_tag, 
    output reg [`OPENUM_TYPE] out_lsb_op,//use this \in lsb to check whether it is send to lsb
    output reg [`DATA_TYPE] out_lsb_value1,
    output reg [`DATA_TYPE] out_lsb_value2,
    output reg [`ROB_POS_TYPE] out_lsb_tag1,
    output reg [`ROB_POS_TYPE] out_lsb_tag2,
    output reg [`DATA_TYPE] out_lsb_imm
);
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] func3; 
    wire [6:0] func7;
   
    assign opcode = in_fetcher_inst[`OPCODE_RANGE];
    assign funct3 = in_fetcher_inst[`FUNC3_RANGE];
    assign funct7 = in_fetcher_inst[`FUNC7_RANGE];
    assign rd = in_fetcher_inst[`RD_RANGE];
    assign out_reg_tag1 = in_fetcher_inst[`RS1_RANGE];
    assign out_reg_tag2 = in_fetcher_inst[`RS2_RANGE];
    assign out_rob_fetch_tag1 = in_reg_robtag1;
    assign out_rob_fetch_tag2 = in_reg_robtag2;
    assign out_reg_rob_tag = in_rob_freetag;
    assign out_pc = in_fetcher_pc;
    wire [`DATA_TYPE] value1; 
    wire [`DATA_TYPE] value2; 
    wire [`ROB_POS_TYPE] tag1;
    wire [`ROB_POS_TYPE] tag2;

    assign in_reg_rs1 = in_dcd_rs1;
    assign in_reg_rs2 = in_dcd_rs2;
    assign value1 = (in_reg_busy1 == `FALSE) ? in_reg_value1 : (in_rob_fetch_ready1 == `TRUE) ? in_rob_fetch_value1 : `ZERO_WORD;
    assign tag1 = (in_reg_busy1 == `FALSE) ? `ZERO_ROB : (in_rob_fetch_ready1 == `TRUE) ? `ZERO_ROB : in_reg_robtag1;
    assign value2 = (in_reg_busy2 == `FALSE) ? in_reg_value2 : (in_rob_fetch_ready2 == `TRUE) ? in_rob_fetch_value2 : `ZERO_WORD;
    assign tag2 = (in_reg_busy2 == `FALSE) ? `ZERO_ROB : (in_rob_fetch_ready2 == `TRUE) ? `ZERO_ROB : in_reg_robtag2;
    
    
    wire [`OPENUM_TYPE] in_dcd_openum;
    wire [`REG_POS_TYPE] in_dcd_rd;
    wire [`REG_POS_TYPE] in_dcd_rs1;
    wire [`REG_POS_TYPE] in_dcd_rs2;
    wire [`DATA_TYPE] in_dcd_imm;
    wire in_dcd_is_jump, in_dcd_is_store;
    decodeunit dcd (
        .inst(in_fetcher_inst),
        .openum(in_dcd_openum),
        .rd(in_dcd_rd),
        .rs1(in_dcd_rs1),
        .rs2(in_dcd_rs2),
        .imm(in_dcd_imm),
        .is_jump(in_dcd_is_jump),
        .is_store(in_dcd_is_store)
    );
        
always @(posedge clk) begin
    
    out_lsb_op = `OPENUM_NOP;
    out_lsb_imm = `ZERO_WORD;
    out_lsb_rob_tag = `ZERO_ROB;
    out_reg_dest = `ZERO_REG;
    out_rob_dest = `ZERO_REG;
    out_rob_op = `OPENUM_NOP;
    out_rs_rob_tag = `ZERO_ROB;
    out_rs_op = `OPENUM_NOP;
    out_rs_imm = `ZERO_WORD;
    out_rs_value1 = `ZERO_WORD;
    out_rs_tag1 = `ZERO_ROB;
    out_rs_value2 = `ZERO_WORD;
    out_rs_tag2 = `ZERO_ROB;
    out_lsb_value1 = `ZERO_WORD;
    out_lsb_tag1 = `ZERO_ROB;
    out_lsb_value2 = `ZERO_WORD;
    out_lsb_tag2 = `ZERO_ROB;
    out_rob_jump_flag= in_fetcher_jump_flag;

    if (rst == `TRUE || rdy == `FALSE || in_dcd_openum == `OPENUM_NOP)begin
    end else begin
       
       out_rs_op=in_dcd_openum;
       out_rs_value1=value1;
       out_rs_tag1=tag1;
       out_rs_value2=value2;
       out_rs_tag2=tag2;
       out_rs_imm=in_dcd_imm; 
       
       out_lsb_op=in_dcd_openum;
       out_lsb_value1=value1;
       out_lsb_tag1=tag1;
       out_lsb_value2=value2;
       out_lsb_tag2=tag2;
       out_lsb_imm=in_dcd_imm;

       out_rob_jump_flag=in_dcd_is_jump;
       out_rob_dest=in_dcd_rd;
       out_rob_op=in_dcd_openum;

       out_reg_dest=in_dcd_rd;

    end
end
endmodule