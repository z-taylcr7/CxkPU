//`include "/mnt/d/CPU/CxkPU/riscv/src/definition.v"

`include "D:\CPU\CxkPU\riscv\src\definition.v"
module decoder (
    input clk,input rst,input rdy,

    // From Fetcher
    input [`DATA_TYPE] in_fetcher_inst,
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

    // ask registers to update value type
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
    output out_rob_jump_flag,
    output reg [`DATA_TYPE] out_rob_dest, // need to distinguish register name from memory address
    output reg [`OPENUM_TYPE] out_rob_op,

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
    output reg [`ROB_POS_TYPE] out_lsb_rob_tag, //use this == lsb to check whether it is send to lsb
    output reg [`OPENUM_TYPE] out_lsb_op,
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
    assign func3 = in_fetcher_inst[14:12];
    assign func7 = in_fetcher_inst[31:25];
    assign rd = in_fetcher_inst[11:7];

    assign out_reg_tag1 = in_fetcher_inst[19:15];
    assign out_reg_tag2 = in_fetcher_inst[24:20];
    assign out_rob_fetch_tag1 = in_reg_robtag1;
    assign out_rob_fetch_tag2 = in_reg_robtag2;
    assign out_reg_rob_tag = in_rob_freetag;
    assign out_pc = in_fetcher_pc;
    assign out_rob_jump_flag = in_fetcher_jump_flag;


//data can come from rob or regfile, or just get tags
    wire [`DATA_TYPE] value1; wire [`DATA_TYPE] value2; wire[`ROB_POS_TYPE] tag1;wire [`ROB_POS_TYPE] tag2;
    assign value1 = (in_reg_busy1 == `FALSE) ? in_reg_value1 : (in_rob_fetch_ready1 == `TRUE) ? in_rob_fetch_value1 : `ZERO_WORD;
    assign tag1 = (in_reg_busy1 == `FALSE) ? `ZERO_ROB : (in_rob_fetch_ready1 == `TRUE) ? `ZERO_ROB : in_reg_robtag1;
    assign value2 = (in_reg_busy2 == `FALSE) ? in_reg_value2 : (in_rob_fetch_ready2 == `TRUE) ? in_rob_fetch_value2 : `ZERO_WORD;
    assign tag2 = (in_reg_busy2 == `FALSE) ? `ZERO_ROB : (in_rob_fetch_ready2 == `TRUE) ? `ZERO_ROB : in_reg_robtag2;

    always @(*) begin
        out_rob_dest = `ZERO_REG;
        out_rob_op = `OPENUM_NOP;
        out_rs_rob_tag = `ZERO_ROB;
        out_rs_op = `OPENUM_NOP;
        out_rs_imm = `ZERO_WORD;
        out_lsb_op = `OPENUM_NOP;
        out_lsb_imm = `ZERO_WORD;
        out_lsb_rob_tag = `ZERO_ROB;
        out_reg_dest = `ZERO_REG;
        out_rs_value1 = `ZERO_WORD;
        out_rs_tag1 = `ZERO_ROB;
        out_rs_value2 = `ZERO_WORD;
        out_rs_tag2 = `ZERO_ROB;
        out_lsb_value1 = `ZERO_WORD;
        out_lsb_tag1 = `ZERO_ROB;
        out_lsb_value2 = `ZERO_WORD;
        out_lsb_tag2 = `ZERO_ROB;

        if((~rst) && rdy) begin 
            
            case (opcode)
                `OPCODE_LUI:begin
                  out_rob_dest = {27'b0,rd[4:0]};
                  out_rs_rob_tag = in_rob_freetag;
                  out_rs_op = `OPENUM_LUI;
                  out_rs_imm = {in_fetcher_inst[31:12],12'b0};
                  out_reg_dest = rd;
                end
                `OPCODE_AUIPC:begin
                  out_rob_op = `OPENUM_AUIPC;
                  out_rob_dest = {27'b0,rd[4:0]};
                  out_rs_rob_tag = in_rob_freetag;
                  out_rs_op = `OPENUM_AUIPC;
                  out_rs_imm = {in_fetcher_inst[31:12],12'b0};
                  out_reg_dest = rd;
                end
                `OPCODE_JAL:begin 
                    out_rob_op = `OPENUM_JAL;
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_rs_op = `OPENUM_JAL;
                    out_reg_dest = rd;
                end
                `OPCODE_JALR:begin 
                    out_rob_op = `OPENUM_JALR;
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_rs_op = `OPENUM_JALR;
                    out_rs_value1 = value1;
                    out_rs_tag1 = tag1;
                    out_rs_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:20]};
                    out_reg_dest = rd;
                end
                `OPCODE_BR:begin 
                    out_rs_rob_tag = in_rob_freetag;
                    out_rs_value1 = value1;
                    out_rs_tag1 = tag1;
                    out_rs_value2 = value2;
                    out_rs_tag2 = tag2;
                    out_rs_imm = {{20{in_fetcher_inst[31]}},in_fetcher_inst[7],in_fetcher_inst[30:25],in_fetcher_inst[11:8], 1'b0};
                    case(func3) 
                        `FUNC3_BEQ:begin    out_rs_op = `OPENUM_BEQ;     end
                        `FUNC3_BNE:begin    out_rs_op = `OPENUM_BNE;      end
                        `FUNC3_BLT:begin    out_rs_op = `OPENUM_BLT;     end
                        `FUNC3_BGE:begin    out_rs_op = `OPENUM_BGE;     end
                        `FUNC3_BLTU:begin    out_rs_op = `OPENUM_BLTU;     end
                        `FUNC3_BGEU:begin    out_rs_op = `OPENUM_BGEU;     end
                    endcase
                    out_rob_op=out_rs_op;
                end
                
                `OPCODE_S:begin
                    out_lsb_rob_tag = in_rob_freetag;
                    out_lsb_value1 = value1;
                    out_lsb_tag1 = tag1;
                    out_lsb_value2 = value2;
                    out_lsb_tag2 = tag2;
                    out_lsb_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:25],in_fetcher_inst[11:7]};
                    case(func3) 
                        `FUNC3_SB:begin    out_lsb_op = `OPENUM_SB;    end
                        `FUNC3_SH:begin    out_lsb_op = `OPENUM_SH;   end
                        `FUNC3_SW:begin    out_lsb_op = `OPENUM_SW;    end
                    endcase
                    out_rob_op=out_lsb_op;
                end
                `OPCODE_L:begin 
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_lsb_rob_tag = in_rob_freetag;
                    out_lsb_value1 = value1;
                    out_lsb_tag1 = tag1;
                    out_lsb_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:20]};
                    out_reg_dest = rd;
                    case(func3) 
                        `FUNC3_LB:begin    out_lsb_op = `OPENUM_LB;     end
                        `FUNC3_LBU:begin    out_lsb_op = `OPENUM_LBU;    end
                        `FUNC3_LH:begin    out_lsb_op = `OPENUM_LH;      end
                        `FUNC3_LHU:begin    out_lsb_op = `OPENUM_LHU;    end
                        `FUNC3_LW:begin    out_lsb_op = `OPENUM_LW;      end
                    endcase
                    out_rob_op=out_lsb_op;
                end
                `OPCODE_ARITHI:begin 
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_rs_value1 = value1;
                    out_rs_tag1 = tag1;
                    out_rs_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:20]};
                    out_reg_dest = rd;
                    case(func3) 
                        `FUNC3_ADDI:begin    out_rs_op = `OPENUM_ADDI;    end
                        `FUNC3_SLTI:begin    out_rs_op = `OPENUM_SLTI;     end
                        `FUNC3_SLTIU:begin    out_rs_op = `OPENUM_SLTIU;    end
                        `FUNC3_XORI:begin    out_rs_op = `OPENUM_XORI;     end
                        `FUNC3_ORI:begin    out_rs_op = `OPENUM_ORI;      end
                        `FUNC3_ANDI:begin    out_rs_op = `OPENUM_ANDI;     end
                        `FUNC3_SLLI:begin 
                            out_rs_op = `OPENUM_SLLI;
                            out_rs_imm = {26'b0,in_fetcher_inst[25:20]};
                        end
                        `FUNC3_SRLI:begin 
                            out_rs_imm = {26'b0,in_fetcher_inst[25:20]};
                            case(func7)
                                `FUNC7_NORM:begin out_rs_op = `OPENUM_SRLI;  end
                                `FUNC7_SPEC:begin out_rs_op = `OPENUM_SRAI;  end
                            endcase
                        end
                    endcase
                    out_rob_op=out_rs_op;
                end
                `OPCODE_ARITH:begin 
                    out_rs_value1 = value1;
                    out_rs_tag1 = tag1;
                    out_rs_value2 = value2;
                    out_rs_tag2 = tag2;
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_reg_dest = rd;
                    case(func3)
                        `FUNC3_ADD:begin 
                            case(func7)
                                `FUNC7_NORM:begin out_rs_op = `OPENUM_ADD; end
                                `FUNC7_SPEC:begin out_rs_op = `OPENUM_SUB; end
                            endcase
                        end
                        `FUNC3_SLL:begin out_rs_op = `OPENUM_SLL; end
                        `FUNC3_SLT:begin out_rs_op = `OPENUM_SLT; end
                        `FUNC3_SLTU:begin out_rs_op = `OPENUM_SLTU; end
                        `FUNC3_XOR:begin out_rs_op = `OPENUM_XOR; end
                        `FUNC3_SRL:begin 
                            case (func7)
                                `FUNC7_NORM: 
                                out_rs_op = `OPENUM_SRL; 
                                default: 
                                out_rs_op = `OPENUM_SRA; 
                            endcase
                        end
                        `FUNC3_OR:begin out_rs_op = `OPENUM_OR; end
                        `FUNC3_AND:begin out_rs_op = `OPENUM_AND;  end
                        out_rob_op=out_rs_op;
                    endcase
                end
            endcase
        end
    end
    endmodule