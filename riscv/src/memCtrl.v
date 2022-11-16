`include "riscv/src/definition.v"
`include "riscv/src/common/fifo/fifo.v"
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
    output reg flag_to_if,
    output reg[`INS_TYPE]inst_to_if,

    // lsu
    input wire flag_from_lsu,
    input wire flag_load_from_lsu,//0 store 1 load
        //store
    input wire [`ADDR_TYPE]addr_from_lsu,
    input wire [`INT_TYPE]data_from_lsu,
    input wire [2:0]size_from_lsu,    
        //load
    output wire [`INT_TYPE]data_to_lsu,
    output reg flag_to_lsu,

    // ram
    output reg flag_to_ram,
    output wire flag_write,
    output reg[`DATA_TYPE]data_to_ram,
    output reg[`ADDR_TYPE]addr_to_ram,
    input wire[`INT_TYPE]data_from_ram
    
);
parameter 
STATUS_IDLE = 0,
STATUS_FETCH = 1,
STATUS_LOAD = 2,
STATUS_STORE = 3;

reg fetcher_flag;
reg lsb_flag;
reg load_flag;
reg store_flag;
reg [`STATUS_TYPE] status;
wire [`STATUS_TYPE] buffered_status; // 0 for idle ; 1 for fetcher; 2 for lsb

reg[`ADDR_TYPE] start_addr;
reg [`INS_TYPE] size;
wire [`MEMPORT_TYPE] buffered_write_data;
wire disable_to_write;
wire wb_is_full;
wire wb_is_empty;


assign buffered_status = (fetcher_flag == `TRUE) ? STATUS_FETCH :
                        (lsb_flag == `FALSE) ? STATUS_IDLE : 
                        (load_flag == `TRUE) ? STATUS_LOAD : STATUS_STORE;



always @(posedge clk ) begin
    if(rst)begin
      flag_to_if<=`FALSE;
      flag_to_ram<=`FALSE;

      flag_to_lsu<=`FALSE;
      status <= 0;
      start_addr<=0;
      size<=0;

    end
    else if(rdy) begin
        flag_to_if<=`FALSE;
        flag_to_lsu<=`FALSE;
        flag_to_ram<=`FALSE;
        data_to_ram<=`ZERO_WORD;
        addr_to_ram<=addr_to_ram+1;
        
        if(status!=STATUS_IDLE||flag_from_if)begin
          
        end
    end
end
endmodule