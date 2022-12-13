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
    input wire [`ADDR_TYPE]addr_from_if,
    output reg flag_to_if,

    // lsb
    input wire flag_from_lsb,
    input wire flag_load_from_lsb,//0 store 1 load
        //store
    input wire [`ADDR_TYPE]addr_from_lsb,
    input wire [`INT_TYPE]data_from_lsb,
    input wire [2:0]size_from_lsb,    
        //load
    output reg [`INT_TYPE]data_to_lsb,
    output reg flag_to_lsb,

    //rob
    input wire flag_from_rob,
    input wire flag_load_from_rob,//0 store 1 load
        //store
    input wire [`ADDR_TYPE]addr_from_rob,
    input wire [`INT_TYPE]data_from_rob,
    input wire [2:0]size_from_rob,    
        //load
    output reg [`INT_TYPE]data_to_rob,
    output reg flag_to_rob,
    

    // ram
    output reg flag_to_ram,
    output reg flag_write_from_ram,
    output reg[`MEMPORT_TYPE]data_to_ram,
    output reg[`ADDR_TYPE]addr_to_ram,
    input wire[`MEMPORT_TYPE]data_from_ram,

    //cdb
    output reg[`DATA_TYPE]data_bus
    
);
parameter IDLE = 0,FETCHER_READ = 1,LSB_READ = 2,ROB_WRITE = 3,IO_READ = 4;
reg fetcher_flag;
reg lsb_flag;
reg rob_flag;
reg io_flag;
reg [`STATUS_TYPE] status;
wire [`STATUS_TYPE] buffered_status; // 0 for idle ; 1 for fetcher; 2 for lsb
reg[5:0] stages;
reg[`ADDR_TYPE] start_addr;
reg [`INS_TYPE] size;
wire [`MEMPORT_TYPE] buffered_write_data;
wire disable_to_write;
wire wb_is_full;
wire wb_is_empty;



//fifo write buffer
reg [`WB_TAG] head;
reg [`WB_TAG] tail;
reg [`DATA_TYPE] wb_data [(`BUFFER_SIZE-1):0];
reg [`DATA_TYPE] wb_addr [(`BUFFER_SIZE-1):0];
reg [5:0] wb_size [(`BUFFER_SIZE-1):0];
wire [`WB_TAG] nextPtr = (tail + 1) % (`BUFFER_SIZE);
wire [`WB_TAG] nowPtr = (head + 1) % (`BUFFER_SIZE);
assign wb_is_empty = (head == tail) ? `TRUE : `FALSE;
assign wb_is_full = (nextPtr == head) ? `TRUE : `FALSE;
assign disable_to_write = (wb_addr[nowPtr][17:16] == 2'b11);

    assign buffered_status = (io_flag == `TRUE) ? IO_READ :
                                (wb_is_empty == `FALSE) ? ROB_WRITE : 
                                    (lsb_flag == `TRUE) ? LSB_READ : 
                                        (fetcher_flag == `TRUE) ? FETCHER_READ : IDLE;

    assign buffered_write_data =    (stages == 0) ? 0 :
                                    (stages == 1) ? wb_data[nowPtr][7:0] :
                                    (stages == 2) ? wb_data[nowPtr][15:8] : 
                                    (stages == 3) ? wb_data[nowPtr][23:16] : wb_data[nowPtr][31:24];

always @(posedge clk) begin
    if(rst)begin
      flag_to_if<=`FALSE;
      flag_to_ram<=`FALSE;
      flag_to_lsb<=`FALSE;
      data_to_lsb=`ZERO_WORD;
      data_to_ram=`ZERO_WORD;
      addr_to_ram=`ZERO_ADDR;
      status <= IDLE;
      stages <= 1;
      head <= 0;
      tail <= 0;
      io_flag <= `FALSE;
      rob_flag<=`FALSE;
      lsb_flag<=`FALSE;
      fetcher_flag<=`FALSE;
      start_addr<=0;
      size<=0;
      flag_write_from_ram<=0;

    end else if(rdy) begin
        flag_to_if<=`FALSE;
        flag_to_lsb<=`FALSE;
        flag_to_ram<=`FALSE;
        data_to_ram<=`ZERO_WORD;      
        flag_write_from_ram<=0;
        //wb suck in commits from rob
        if(rob_flag==`TRUE||flag_from_rob==`TRUE)begin
           if(wb_is_full == `FALSE) begin 
                    rob_flag <= `FALSE;
                    flag_to_rob <= `TRUE;
                    wb_addr[nextPtr] <= addr_from_rob;
                    wb_data[nextPtr] <= data_from_rob;
                    wb_size[nextPtr] <= size_from_rob;
                    tail <= nextPtr;
                end 
            else begin 
                    rob_flag <= `TRUE; 
                end
        end
        addr_to_ram=addr_to_ram+1;
        stages=stages+1;
        case (status)
            IO_READ: 
                if(stages==1)begin addr_to_ram<=`ZERO_ADDR; end
                else if(stages==2)begin
                  // io read
                  io_flag<=`FALSE;
                  data_to_ram<=data_from_ram;

                  //reset status 
                  
                  stages<=1;
                  status<=IDLE;
                  flag_to_rob=`TRUE;

                end
            LSB_READ:
                case (size_from_lsb)
                    1:
                        begin 
                            addr_to_ram<= addr_from_lsb;
                            data_bus <= data_from_ram;
                            stages=1;
                            lsb_flag=`FALSE;
                            flag_to_lsb=`TRUE;
                            if(wb_is_empty==`FALSE)begin
                              status <= ROB_WRITE;
                              data_to_ram <=`ZERO_WORD;
                              
                            end else if (fetcher_flag==`TRUE) begin
                              status<=FETCHER_READ;
                              addr_to_ram<=addr_from_if;
                            end else begin
                              status<=IDLE;
                            
                            end
                            
                        end
                    2:begin
                      data_bus<=data_from_ram;
                      case(stages) 
                                // 1: begin out_ram_addr <= in_lsb_addr;end 
                                2: begin data_bus[7:0] <= data_from_ram; end
                                3: begin 
                                    data_bus <= {data_bus,data_bus[7:0]}; 
                                    stages <= 1;
                                    lsb_flag <= `FALSE;
                                    flag_to_lsb <= `TRUE;
                                    if(wb_is_empty == `FALSE) begin
                                        status <= ROB_WRITE; 
                                        addr_to_ram <= `ZERO_WORD;
                                    end else if(fetcher_flag == `TRUE) begin
                                        status <= FETCHER_READ;
                                        addr_to_ram <= addr_from_if;
                                    end else begin 
                                        status <= IDLE; 
                                    end
                                end
                            endcase
                    end
                    4:begin 
                            case(stages) 
                                
                                2: begin data_bus[7:0] <= data_from_ram; end
                                3: begin data_bus[15:8] <= data_from_ram; end
                                4: begin data_bus[23:16] <= data_from_ram; end 
                                5: begin 
                                    data_bus[31:24] <= data_from_ram;
                                    stages <= 1;
                                    lsb_flag <= `FALSE;
                                    flag_to_lsb <= `TRUE;

                                    if(wb_is_empty == `FALSE) begin
                                        status <= ROB_WRITE; 
                                        addr_to_ram <= `ZERO_WORD;
                                    end else if(fetcher_flag == `TRUE) begin
                                        status <= FETCHER_READ;
                                        addr_to_ram <= addr_from_if;
                                    end else begin status <= IDLE; end
                                end 
                            endcase
                        end
                endcase
            FETCHER_READ:begin
                 case(stages) 
                        2: begin data_bus[7:0] <= data_from_ram; end
                        3: begin data_bus[15:8] <= data_from_ram; end
                        4: begin data_bus[23:16] <= data_from_ram; end 
                        5: begin 
                            data_bus[31:24] <= data_from_ram;
                            stages <= 1;
                            fetcher_flag <= `FALSE;
                            flag_to_if <= `TRUE;

                            if(wb_is_empty == `FALSE) begin
                                status <= ROB_WRITE; 
                                addr_to_ram <= `ZERO_ADDR;
                            end else if(fetcher_flag == `TRUE) begin
                                status <= FETCHER_READ;
                                addr_to_ram <= addr_from_if;
                            end else begin status <= IDLE; end
                        end 
                    endcase
              
            end
            ROB_WRITE:
                if(disable_to_write==`TRUE)begin
                  data_to_ram<=1;
                  addr_to_ram<=`ZERO_ADDR;
                  stages<=1;

                end else begin
                  flag_write_from_ram<=0;
                  //commit from WBuffer
                  
                  if(stages==1)begin 
                    addr_to_ram<=wb_addr[nowPtr];
                  end
                  data_to_ram<=buffered_write_data;
                  if(stages==wb_size[nowPtr])begin
                     head <= nowPtr;
                            stages <= 1;
                            if(nowPtr == tail) begin 
                                status <= IDLE;
                            end  
                            else begin 
                                status <= ROB_WRITE;
                            end
                  end
                end
            IDLE: begin 
                    stages <= 1;
                    status <= buffered_status;
                    addr_to_ram <=  (buffered_status == IO_READ) ? `RAM_IO_PORT :
                                            (buffered_status == ROB_WRITE) ? `ZERO_ADDR : 
                                                (buffered_status == LSB_READ) ? addr_from_lsb:
                                                    (buffered_status == FETCHER_READ) ? addr_from_if : `ZERO_ADDR;
                end
        endcase
    end
end
endmodule