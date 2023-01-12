`include "/mnt/d/CPU/CxkPU/riscv/src/definition.v"

// `include "D:\CPU\CxkPU\riscv\src\definition.v"

module decoder (
    input clk,input rst,input rdy,
    // from fetcher
    input [`DATA_TYPE] in_fetcher_inst,
    input [`DATA_TYPE] in_fetcher_pc,
    input in_fetcher_jump_flag,

    output [`REG_POS_TYPE] out_reg_tag1,
    input [`DATA_TYPE] in_reg_value1,
    input [`ROB_POS_TYPE] in_reg_robtag1,
    input in_reg_busy1,

    output [`REG_POS_TYPE] out_reg_tag2,
    input [`DATA_TYPE] in_reg_value2,
    input [`ROB_POS_TYPE] in_reg_robtag2,
    input in_reg_busy2,

    output reg [`REG_POS_TYPE] out_reg_dest, 
    output [`ROB_POS_TYPE] out_reg_rob_tag,

    
    input [`ROB_POS_TYPE] in_rob_freetag,// Get allocated free rob tag

    // ask rob for value
    output [`ROB_POS_TYPE] out_rob_fetch_tag1,
    input [`DATA_TYPE] in_rob_fetch_value1,
    input in_rob_fetch_ready1,
    output [`ROB_POS_TYPE] out_rob_fetch_tag2,
    input [`DATA_TYPE] in_rob_fetch_value2,
    input in_rob_fetch_ready2,

    // ask rob 
    output reg [`DATA_TYPE] out_rob_dest, 
    output reg [`OPENUM_TYPE] out_rob_op,
    output out_rob_jump_flag,

    // ask rs 
    output reg [`ROB_POS_TYPE] out_rs_rob_tag, 
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
    output reg [`OPENUM_TYPE] out_lsb_op,
    output reg [`DATA_TYPE] out_lsb_value1,
    output reg [`DATA_TYPE] out_lsb_value2,
    output reg [`ROB_POS_TYPE] out_lsb_tag1,
    output reg [`ROB_POS_TYPE] out_lsb_tag2,
    output reg [`DATA_TYPE] out_lsb_imm

);
    
    wire [6:0] opcode;
    wire [4:0]  rd;
    wire [2:0] funct3; 
    wire [6:0] funct7;
    
    
    assign opcode = in_fetcher_inst[`OPCODE_RANGE];
    assign funct3 = in_fetcher_inst[14:12];
    assign funct7 = in_fetcher_inst[31:25];
    assign rd = in_fetcher_inst[11:7];

    assign out_reg_tag1 = in_fetcher_inst[19:15];
    assign out_reg_tag2 = in_fetcher_inst[24:20];
    assign out_rob_fetch_tag1 = in_reg_robtag1;
    assign out_rob_fetch_tag2 = in_reg_robtag2;
    assign out_reg_rob_tag = in_rob_freetag;
    assign out_pc = in_fetcher_pc;
    assign out_rob_jump_flag = in_fetcher_jump_flag;



    //quick matcher to ROB commits
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

        if(rst == `FALSE && rdy == `TRUE) begin 
            case (opcode)
                `OPCODE_LUI:begin
                  out_rob_op = `OPENUM_LUI;
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
                    case(funct3) 
                        `FUNC3_BEQ:begin    
                            out_rs_op = `OPENUM_BEQ;     
                            out_rob_op = `OPENUM_BEQ; 
                        end
                        `FUNC3_BNE:begin    
                            out_rs_op = `OPENUM_BNE;    
                             out_rob_op = `OPENUM_BNE; 
                        end
                        `FUNC3_BLT:begin    
                            out_rs_op = `OPENUM_BLT;     
                            out_rob_op = `OPENUM_BLT;
                         end
                        `FUNC3_BGE:begin    
                            out_rs_op = `OPENUM_BGE;     
                            out_rob_op = `OPENUM_BGE; 
                        end
                        `FUNC3_BLTU:begin    
                            out_rs_op = `OPENUM_BLTU;    
                            out_rob_op = `OPENUM_BLTU;
                        end
                        `FUNC3_BGEU:begin    
                            out_rs_op = `OPENUM_BGEU;    
                            out_rob_op = `OPENUM_BGEU; 
                        end
                    endcase
                end
                `OPCODE_L:begin 
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_lsb_rob_tag = in_rob_freetag;
                    out_lsb_value1 = value1;
                    out_lsb_tag1 = tag1;
                    out_lsb_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:20]};
                    out_reg_dest = rd;
                    case(funct3) 
                        `FUNC3_LB:begin    out_lsb_op = `OPENUM_LB;     out_rob_op = `OPENUM_LB; end
                        `FUNC3_LH:begin    out_lsb_op = `OPENUM_LH;     out_rob_op = `OPENUM_LH; end
                        `FUNC3_LW:begin    out_lsb_op = `OPENUM_LW;     out_rob_op = `OPENUM_LW; end
                        `FUNC3_LBU:begin    out_lsb_op = `OPENUM_LBU;    out_rob_op = `OPENUM_LBU; end
                        `FUNC3_LHU:begin    out_lsb_op = `OPENUM_LHU;    out_rob_op = `OPENUM_LHU; end
                    endcase
                end
                `OPCODE_S:begin
                    out_lsb_rob_tag = in_rob_freetag;
                    out_lsb_value1 = value1;
                    out_lsb_tag1 = tag1;
                    out_lsb_value2 = value2;
                    out_lsb_tag2 = tag2;
                    out_lsb_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:25],in_fetcher_inst[11:7]};
                    case(funct3) 
                        `FUNC3_SB:begin    out_lsb_op = `OPENUM_SB;    out_rob_op = `OPENUM_SB; end
                        `FUNC3_SH:begin    out_lsb_op = `OPENUM_SH;    out_rob_op = `OPENUM_SH; end
                        `FUNC3_SW:begin    out_lsb_op = `OPENUM_SW;    out_rob_op = `OPENUM_SW; end
                    endcase
                end
                `OPCODE_ARITHI:begin 
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_rs_value1 = value1;
                    out_rs_tag1 = tag1;
                    out_rs_imm = {{21{in_fetcher_inst[31]}},in_fetcher_inst[30:20]};
                    out_reg_dest = rd;
                    case(funct3) 
                        `FUNC3_ADDI:begin    
                            out_rs_op = `OPENUM_ADDI;    
                            out_rob_op = `OPENUM_ADDI; 
                        end
                        `FUNC3_SLTI:begin    
                            out_rs_op = `OPENUM_SLTI;    
                            out_rob_op = `OPENUM_SLTI; 
                        end
                        `FUNC3_SLTIU:begin    
                            out_rs_op = `OPENUM_SLTIU;   
                            out_rob_op = `OPENUM_SLTIU; 
                        end
                        `FUNC3_XORI:begin    
                            out_rs_op = `OPENUM_XORI;    
                            out_rob_op = `OPENUM_XORI; 
                        end
                        `FUNC3_ORI:begin    
                            out_rs_op = `OPENUM_ORI;    
                             out_rob_op = `OPENUM_ORI; 
                        end
                        `FUNC3_ANDI:begin    
                            out_rs_op = `OPENUM_ANDI;    
                            out_rob_op = `OPENUM_ANDI;
                         end
                        `FUNC3_SLLI:begin 
                            out_rs_op = `OPENUM_SLLI;
                            out_rob_op = `OPENUM_SLLI;
                            out_rs_imm = {26'b0,in_fetcher_inst[25:20]};
                        end
                        `FUNC3_SRLI:begin 
                            out_rs_imm = {26'b0,in_fetcher_inst[25:20]};
                            case(funct7)
                                `FUNC7_NORM:begin out_rs_op = `OPENUM_SRLI; out_rob_op = `OPENUM_SRLI; end
                                `FUNC7_SPEC:begin out_rs_op = `OPENUM_SRAI; out_rob_op = `OPENUM_SRAI; end
                            endcase
                        end
                    endcase
                end
                `OPCODE_ARITH:begin 
                    out_rs_value1 = value1;
                    out_rs_tag1 = tag1;
                    out_rs_value2 = value2;
                    out_rs_tag2 = tag2;
                    out_rob_dest = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_reg_dest = rd;
                    case(funct3)
                        `FUNC3_ADD:begin 
                            case(funct7)
                                `FUNC7_NORM:begin 
                                    out_rs_op = `OPENUM_ADD; 
                                    out_rob_op = `OPENUM_ADD; 
                                end
                                `FUNC7_SPEC:begin 
                                    out_rs_op = `OPENUM_SUB; 
                                    out_rob_op = `OPENUM_SUB; 
                                end
                            endcase
                        end
                        `FUNC3_SLL:begin out_rs_op = `OPENUM_SLL; out_rob_op = `OPENUM_SLL; end
                        `FUNC3_SLT:begin out_rs_op = `OPENUM_SLT; out_rob_op = `OPENUM_SLT; end
                        `FUNC3_SLTU:begin out_rs_op = `OPENUM_SLTU; out_rob_op = `OPENUM_SLTU; end
                        `FUNC3_XOR:begin out_rs_op = `OPENUM_XOR; out_rob_op = `OPENUM_XOR; end
                        `FUNC3_SRL:begin 
                            case(funct7)
                                `FUNC7_NORM:begin 
                                    out_rs_op = `OPENUM_SRL;
                                     out_rob_op = `OPENUM_SRL; 
                                end
                                `FUNC7_SPEC:begin 
                                    out_rs_op = `OPENUM_SRA; 
                                    out_rob_op = `OPENUM_SRA; 
                                end
                            endcase
                        end
                        `FUNC3_OR:begin out_rs_op = `OPENUM_OR; out_rob_op = `OPENUM_OR; end
                        `FUNC3_AND:begin out_rs_op = `OPENUM_AND; out_rob_op = `OPENUM_AND; end
                    endcase
                end
            endcase
        end
    end
    endmodule