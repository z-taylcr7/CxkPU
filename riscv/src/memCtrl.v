`include "riscv/src/definition.v"
//Hello everyone, I'm a self-trained mem Ctrler having been training for two and a half year.
//I can do nothing but:
//                      Chang
//                      Tiao
//                      Rap
//                      Lanqiu
//Now, let's have some music!!!!!

module memCtrl(
    input wire clk,input wire rst,input wire rdy,
    // fetcher
    input wire flag_from_if,
    input wire [`ADDR_TYPE]mem_req_from_if,
    output wire flag_to_if,
    output reg[`INS_TYPE]inst_to_if,

    // lsu
    input wire flag_from_lsu,
    input wire flag_s0l1_from_lsu,//0 store 1 load
        //store
    input wire [`ADDR_TYPE]addr_from_lsu,
    input wire [`INT_TYPE]data_from_lsu,
    input wire [2:0]size_from_lsu,    
        //load
    output wire [`INT_TYPE]data_to_lsu,
    output wire flag_to_lsu,

    // ram
    output wire flag_read0_write1,
    output wire[`INT_TYPE]data_to_ram,
    output wire[`ADDR_TYPE]addr_to_ram,
    input reg[`INT_TYPE]data_from_ram
    
);
parameter 
STATUS_IDLE = 0,
STATUS_FETCH = 1,
STATUS_LOAD = 2,
STATUS_STORE = 3;
reg fetcher_flag;
reg lsb_flag;
reg rob_flag;
reg io_flag;
reg [4:0] stages;
reg [2:0] status;
wire [2:0] buffered_status; // 0 for idle ; 1 for fetcher; 2 for lsb; 3 for rob write; 4 for rob read
wire [`INT_TYPE] buffered_write_data;
wire disable_to_write;
endmodule