///////////////////////////////////////////////////////////////
//
// Company: Abacus Semiconductor Corporation
// Engineer:  Rohit Vippagunta
//
// Copyright (C) 2020-2025 Abacus Semiconductor Corporation
//
// This file and all derived works are confidential property of 
// Abacus Semiconductor Corporation
// 
// Create Date:   2025-02-14 
// Design Name:   MEMORY_CONTROLLER
// Module Name:   MEMORY_CONTROLLER
// Project Name:  MEMORY_CONTROLLER with L1 Cache
// Target Device:Target Device: (FPGA: AMD/Xilinx Virtex UltraScale+) (ASIC: TSMC 16nm)
// Tool versions: all
// Description:   Memory controller that interfaces with main memory and L1 Cache
//
// Dependencies:  None
//
// Revision:   0.01  Initial version
// 
//
// Additional Comments: Needs future modifications to support L2 Cache
//
//
///////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module MEMORY_CONTROLLER(
    

    input wire clk, reset_n, enable, rw,
    input wire [ADDRESS_WIDTH - 1 : 0] address,
    input wire [DATA_WIDTH - 1 : 0] data_in,
    output reg [DATA_WIDTH - 1 : 0] data_out,
    output reg Wait 
);

parameter ADDRESS_WIDTH = 32;
parameter DATA_WIDTH = 32;

//MAIN MEMORY DECLARATION//
//////////////////////////////////////////////////////////////////////
parameter no_of_main_memory_blocks=16384; //2^14 No. of lines in main memory
parameter main_memory_block_size=32;        //No. of bits in a single line = No. of blocks in a line * no. of bits in a block =1*32=32
parameter no_of_bytes_main_memory_block=4;  //No. of bytes in a single given line on main memory ...No. of blocks in a single line * no. of bytes in a block = 1*4=4
parameter byte_size=8;          //No. of bits in a byte =8
parameter main_memory_byte_size=65536; //no_of_main_memory_blocks*no_of_bytes_main_memory_block

reg [main_memory_block_size-1:0]main_memory[0:no_of_main_memory_blocks-1];
initial 
begin: initialization_main_memory
    integer i;
    for (i=0;i<no_of_main_memory_blocks;i=i+1)
    begin
        main_memory[i]=i;       //we can randomly intialize with some other value as well here
    end
end

///////////////////////////////////////////////////////////////////////////



// L1 CACHE DECLARATION//
/////////////////////////////////////////////////////////////////////////
parameter no_of_l1_blocks=64;        //No. of lines in L1 Cache
parameter no_of_bytes_l1_block=4;     //No. of bytes in a single block
parameter l1_block_bit_size=32;         //size of a L1 Cache block =No. of bytes in a block * byte size
// parameter byte_size=8;                  //No. of bits in a byte
parameter no_of_address_bits=32;        //the bits in address
parameter no_of_l1_index_bits=6;        //the no. of bits required for indexing as 2^6=64
parameter no_of_blkoffset_bits=2;       //as there are 4 bytes in a block... to index the bytes in a block
parameter no_of_l1_tag_bits=24;         //No. of bits in tag= No. of address bits - No. of index bits - No. of offset bits=32-6-2=24

reg [l1_block_bit_size-1:0]l1_cache_memory[0:no_of_l1_blocks-1];    //An array of blocks for L1 Cache memory where each element contains No. of l1_block_bit_size bits
reg [no_of_l1_tag_bits-1:0]l1_tag_array[0:no_of_l1_blocks-1];  //Tag array for L1 Cache memory where each element contains no_of_tag_bits bits
reg l1_valid[0:no_of_l1_blocks-1];      //The valid array for L1 Cache containing 1 if it is valid or 0 if invalid
                                        //valid means if there is some block stored at some location in L1 Cache...initially as Cache is empty...all postions are invalid

initial 
begin: initialization_l1           
    integer i;
    for  (i=0;i<no_of_l1_blocks;i=i+1)
    begin
        l1_valid[i]=1'b0;   //initially as the cache is empty...all the locations on the Cache are invalid
        l1_tag_array[i]=0;  //set tag to 0...we can set tag to some other random value as well
    end
end
///////////////////////////////////////////////////////////////////////////////

reg [1:0] current_state, next_state;

reg hit_1;

// State encoding
parameter IDLE = 2'b00, FETCH = 2'b01, UPDATE = 2'b10, MISS = 2'b11;

// DATA READ, WRITE, AND STATE TRANSITION LOGIC
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        current_state <= IDLE;
        data_out <= 0;
    end else begin
        current_state <= next_state;

        case (current_state)
            FETCH: begin
                if (hit_1) begin
                    data_out <= l1_cache_memory[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]];
                end
            end

            MISS: begin
                data_out <= main_memory[address];
                l1_cache_memory[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]] <= main_memory[address];
                l1_tag_array[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]] <= address[ADDRESS_WIDTH-1:(no_of_l1_index_bits + no_of_blkoffset_bits)];
                l1_valid[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]] <= 1'b1;
            end

            UPDATE: begin
                l1_cache_memory[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]] <= data_in;
                main_memory[address] <= data_in;
                l1_valid[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]] <= 1'b1;
            end

            default: begin
                data_out <= 0; 
            end
        endcase
    end
end

// NEXT STATE LOGIC
always @ (*) begin
    case (current_state)
        IDLE: begin
            hit_1 = 0;
            Wait = 0;
            if (enable) begin
                if (~rw) begin
                    next_state = FETCH;
                end else begin
                    next_state = UPDATE;
                end
            end else begin
                next_state = IDLE;
            end
        end

        FETCH: begin
            Wait = 1;
            if (l1_valid[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]] &&
                address[ADDRESS_WIDTH-1:(no_of_l1_index_bits + no_of_blkoffset_bits)] == 
                l1_tag_array[address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]]) begin
                hit_1 = 1;
                next_state = IDLE;
            end else begin
                hit_1 = 0;
                next_state = MISS;
            end
        end

        MISS: begin
            Wait = 1;
            next_state = IDLE;
        end

        UPDATE: begin
            Wait = 1;
            next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule



