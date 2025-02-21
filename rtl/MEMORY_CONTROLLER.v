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
// Revision:   0.02
// 
//
// Additional Comments: Needs future modifications to support L2 write back
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
parameter DATA_WIDTH = 8;

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
        main_memory[i]= i;       //we can randomly intialize with some other value as well here
    end
end

///////////////////////////////////////////////////////////////////////////

// L2 CACHE DECLARATION//
/////////////////////////////////////////////////////////////////////////
parameter no_of_l2_ways=4;          //No. of ways in the set ...4 as it is 4-way set-associative here
parameter no_of_l2_ways_bits=2;     //No. of bits required to describe the way to which a block belongs =2 as 2^2=4
parameter no_of_l2_blocks=128;      //No. of lines in L2 block ...we can also describe it as the number of sets in L2 Cache
parameter no_of_bytes_l2_block=16;  //No. of bytes in a single line on L2 block=No. of blocks in a single line * No. of bytes in a block =4*4=16
parameter l2_block_bit_size=128;    //The size of L2 block line in bits = NO. of blocks in a singl line * No. of bits in a block=4*16=128
// parameter byte_size=8;              //The no. of bits in a byte
parameter no_of_address_bits=32;       //The number of bits to represent an address
parameter no_of_l2_index_bits=7;        //THe number of index bits to describe a line on L2 Block...Here 7 as 2^7=128
parameter no_of_blkoffset_bits=2;          //The number of bits to describe the byte in a block...2^2=4
parameter no_of_l2_tag_bits=23;             //No. of tag bits = No. of address bits  - No. of index bits - NO. of block offset bits= 32-7-2=23

reg [l2_block_bit_size-1:0]l2_cache_memory[0:no_of_l2_blocks-1];        //An array where each element if of l2_block_bit_size bits..for memory in L2 Cache
reg [(no_of_l2_tag_bits*no_of_l2_ways)-1:0]l2_tag_array[0:no_of_l2_blocks-1];  //The tag array where each element contains no_of_l2_tag_bits*NO_of_l2_ways bits
reg [no_of_l2_ways-1:0]l2_valid[0:no_of_l2_blocks-1];      //Is valid array where each element is of no_of_l2_ways bits
reg [no_of_l2_ways*no_of_l2_ways_bits-1:0]lru[0:no_of_l2_blocks-1];     //LRU array where each element is of no_of_l2_ways*no_of_l2_ways_bits bits
reg [2:0] l2_way_rr; // Added l2_way register

initial 
begin: initialization
    integer i;
    for  (i=0;i<no_of_l2_blocks;i=i+1)
    begin
        l2_valid[i]=0;          //initially the cache is empty
        l2_tag_array[i]=0;         //set tag to some random
        lru[i]=8'b11100100;         //set the lru values to some random permutation of 0, 1, 2, 3 initially
        l2_way_rr = 3'b000; // Initialize round-robin way to 0
    end
end
///////////////////////////////////////////////////////////////////////////////



// L1 CACHE DECLARATION//
/////////////////////////////////////////////////////////////////////////
parameter no_of_l1_blocks=64;        //No. of lines in L1 Cache
parameter no_of_bytes_l1_block=4;     //No. of bytes in a single block
parameter l1_block_bit_size=32;         //size of a L1 Cache block =No. of bytes in a block * byte size
// parameter byte_size=8;                  //No. of bits in a byte
// parameter no_of_address_bits=32;        //the bits in address
parameter no_of_l1_index_bits=6;        //the no. of bits required for indexing as 2^6=64
// parameter no_of_blkoffset_bits=2;       //as there are 4 bytes in a block... to index the bytes in a block
parameter no_of_l1_tag_bits=24;         //No. of bits in tag= No. of address bits - No. of index bits - No. of offset bits=32-6-2=24

reg [l1_block_bit_size-1:0]l1_cache_memory[0:no_of_l1_blocks-1];    //An array of blocks for L1 Cache memory where each element contains No. of l1_block_bit_size bits
reg [no_of_l1_tag_bits-1:0]l1_tag_array[0:no_of_l1_blocks-1];  //Tag array for L1 Cache memory where each element contains no_of_tag_bits bits
reg l1_valid[0:no_of_l1_blocks-1];      //The valid array for L1 Cache containing 1 if it is valid or 0 if invalid, valid means if there is some block stored at some location in L1 Cache...initially as Cache is empty...all postions are invalid
reg l1_dirty[0:no_of_l1_blocks-1];      //The dirty array for L1 Cache containing 1 if it is dirty or 0 if clean, dirty means if the block is modified or not...initially as Cache is empty...all postions are clean


initial 
begin: initialization_l1           
    integer i;
    for  (i=0;i<no_of_l1_blocks;i=i+1)
    begin
        l1_valid[i] = 1'b0;   //initially as the cache is empty...all the locations on the Cache are invalid
        l1_tag_array[i] = 0;
        l1_dirty[i] = 0;  //set tag to 0...we can set tag to some other random value as well
    end
end
///////////////////////////////////////////////////////////////////////////////

reg [2:0] current_state, next_state;
reg [1:0] l2_way;
reg hit_1, hit_2;
reg [no_of_l1_index_bits - 1:0] l1_cache_index; // Added l1_cache_index register
reg [no_of_l2_index_bits - 1:0] l2_cache_index; // Added l1_cache_index register

// State encoding
parameter IDLE = 3'b000, FETCH = 3'b001, UPDATE = 3'b010, MISS = 3'b011, MISS_WAIT = 3'b100;



// DATA READ, WRITE LOGIC
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        current_state <= IDLE;  
        data_out <= 0;
    end else begin
        current_state <= next_state;

        case (current_state)

            FETCH: begin
                if (hit_1) begin
                    $display("L1 HIT! L1_FETCH:address = %h, address_tag = %h, l1_tag_array[%h] = %h",address, address[ADDRESS_WIDTH-1:(no_of_l1_index_bits + no_of_blkoffset_bits)], l1_cache_index, l1_tag_array[l1_cache_index]);
                    $display("");
                    l1_cache_index <= address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]; // Calculate cache index
                    case (address[no_of_blkoffset_bits - 1 : 0]) // Byte select
                        2'b11: data_out <= l1_cache_memory[l1_cache_index][31:24];
                        2'b10: data_out <= l1_cache_memory[l1_cache_index][23:16];
                        2'b01: data_out <= l1_cache_memory[l1_cache_index][15:8];
                        2'b00: data_out <= l1_cache_memory[l1_cache_index][7:0];
                    endcase
                end else if (hit_2) begin
                    l2_cache_index <= address[(no_of_l2_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]; // Calculate cache index 
                    case(l2_way)
                        2'b00 : begin 
                            case (address[no_of_blkoffset_bits - 1 : 0]) // Byte select
                                2'b11: data_out <= l2_cache_memory[l2_cache_index][31:24];
                                2'b10: data_out <= l2_cache_memory[l2_cache_index][23:16];
                                2'b01: data_out <= l2_cache_memory[l2_cache_index][15:8];
                                2'b00: data_out <= l2_cache_memory[l2_cache_index][7:0];
                            endcase  
                        end

                        2'b01 : begin 
                            case (address[no_of_blkoffset_bits - 1 : 0]) // Byte select
                                2'b11: data_out <= l2_cache_memory[l2_cache_index][63:56];
                                2'b10: data_out <= l2_cache_memory[l2_cache_index][55:48];
                                2'b01: data_out <= l2_cache_memory[l2_cache_index][47:40];
                                2'b00: data_out <= l2_cache_memory[l2_cache_index][39:32];
                            endcase  
                        end

                        2'b10 : begin 
                            case (address[no_of_blkoffset_bits - 1 : 0]) // Byte select
                                2'b11: data_out <= l2_cache_memory[l2_cache_index][95:88];
                                2'b10: data_out <= l2_cache_memory[l2_cache_index][87:80];
                                2'b01: data_out <= l2_cache_memory[l2_cache_index][79:72];
                                2'b00: data_out <= l2_cache_memory[l2_cache_index][71:64];
                            endcase  
                        end

                        2'b11 : begin 
                            case (address[no_of_blkoffset_bits - 1 : 0]) // Byte select
                                2'b11: data_out <= l2_cache_memory[l2_cache_index][127:120];
                                2'b10: data_out <= l2_cache_memory[l2_cache_index][119:112];
                                2'b01: data_out <= l2_cache_memory[l2_cache_index][111:104];
                                2'b00: data_out <= l2_cache_memory[l2_cache_index][103:96];
                            endcase  
                        end
                    endcase  
                    $display("L2 HIT! L2_FETCH:address = %h, address_tag = %h, l2_cache_index = %h ",address, address[ADDRESS_WIDTH-1:(no_of_l2_index_bits + no_of_blkoffset_bits)], l2_cache_index);
                    $display("way_3 tag = %h, way_2 tag = %h, way_1 tag = %h, way_0 tag = %h", l2_tag_array[l2_cache_index][91:69], l2_tag_array[l2_cache_index][68:46], l2_tag_array[l2_cache_index][45:23], l2_tag_array[l2_cache_index][22:0]);
                    $display("way_3 data = %h, way_2 data = %h, way_1 data = %h, way_0 data = %h", l2_cache_memory[l2_cache_index][127:96], l2_cache_memory[l2_cache_index][95:64], l2_cache_memory[l2_cache_index][63:32], l2_cache_memory[l2_cache_index][31:0]);
                    $display("way_3 valid = %h, way_2 valid = %h, way_1 valid = %h, way_0 valid = %h", l2_valid[l2_cache_index][3], l2_valid[l2_cache_index][2], l2_valid[l2_cache_index][1], l2_valid[l2_cache_index][0]);
                    $display("");
                end
            end

            MISS: begin
                l1_cache_index <= address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits];

                if (l1_dirty[l1_cache_index]) begin
                    // Write back to main memory (IMPORTANT: Use reconstructed address)
                    main_memory[ {l1_tag_array[l1_cache_index], l1_cache_index, 2'b00} / (no_of_bytes_l1_block) ] <= l1_cache_memory[l1_cache_index];  //Reconstructed address
                    l1_dirty[l1_cache_index] <= 1'b0; // Clear dirty bit AFTER write-back
                    $display("MISS: Write Back to Main Memory Address = %h, Data = %h", {l1_tag_array[l1_cache_index], l1_cache_index, 2'b00} / (no_of_bytes_l1_block), l1_cache_memory[l1_cache_index]);
                    $display("");
                   // Write to L2 (Write-Through)
                    case(l2_way_rr)
                            2'b00 : begin 
                                l2_cache_memory[l2_cache_index][31 :0] <= l1_cache_memory[l1_cache_index];
                                l2_tag_array[l2_cache_index][22:0] <= l1_tag_array[l1_cache_index][23:1]; // Shift and assign
                                l2_valid[l2_cache_index][0] <= 1'b1;
                            end

                            2'b01 : begin 
                                l2_cache_memory[l2_cache_index][63:32] <= l1_cache_memory[l1_cache_index];
                                l2_tag_array[l2_cache_index][45:23] <= l1_tag_array[l1_cache_index][23:1];
                                l2_valid[l2_cache_index][1] <= 1'b1; 
                            end

                            2'b10 : begin 
                                l2_cache_memory[l2_cache_index][95:64] <= l1_cache_memory[l1_cache_index];
                                l2_tag_array[l2_cache_index][68:46] <= l1_tag_array[l1_cache_index][23:1];
                                l2_valid[l2_cache_index][2] <= 1'b1;  
                            end

                            2'b11 : begin 
                                l2_cache_memory[l2_cache_index][127:96] <= l1_cache_memory[l1_cache_index];
                                l2_tag_array[l2_cache_index][91:69] <= l1_tag_array[l1_cache_index][23:1];
                                l2_valid[l2_cache_index][3] <= 1'b1;  
                            end
                    endcase
                end

                // Fetch new block from main memory (Use the requested address)
                $display("MISS: Accessing main_memory at address: %h, data: %h", address / (no_of_bytes_l1_block), main_memory[address / (no_of_bytes_l1_block)]); //Crucial!
                $display("");
                l1_cache_memory[l1_cache_index] <= main_memory[address / (no_of_bytes_l1_block)];
                l1_tag_array[l1_cache_index] <= address[ADDRESS_WIDTH - 1 : (no_of_l1_index_bits + no_of_blkoffset_bits)];
                l1_valid[l1_cache_index] <= 1'b1;
                l1_dirty[l1_cache_index] <= 1'b0;

                // Write to L2 (Write-Through)
                case(l2_way_rr)
                        2'b00 : begin 
                         //   $display("way_0 MISS: l2_cache_memory[%h][31 :0] = %h", main_memory[address / (no_of_bytes_l1_block)], l2_cache_memory[l2_cache_index][31:0]);
                          //  $display("MISS: l2_tag_array[%h][22:0] = %h", l2_cache_index, address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)]);
                          //  $display("");
                             l2_cache_memory[l2_cache_index][31 :0] <= main_memory[address / (no_of_bytes_l1_block)];
                             l2_tag_array[l2_cache_index][22:0] <= address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)];
                             l2_valid[l2_cache_index][0] <= 1'b1;
                        end

                        2'b01 : begin 
                          //  $display("way_1 MISS: l2_cache_memory[%h][63 :32] = %h", main_memory[address / (no_of_bytes_l1_block)], l2_cache_memory[l2_cache_index][63:32]);
                          //  $display("MISS: l2_tag_array[%h][45:23] = %h", l2_cache_index, address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)]);
                          //  $display("");
                            l2_cache_memory[l2_cache_index][63:32] <= main_memory[address / (no_of_bytes_l1_block)];
                            l2_tag_array[l2_cache_index][45:23] <= address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)];
                            l2_valid[l2_cache_index][1] <= 1'b1; 
                        end

                        2'b10 : begin 
                          //  $display("way_2 MISS: l2_cache_memory[%h][95:64] = %h", main_memory[address / (no_of_bytes_l1_block)], l2_cache_memory[l2_cache_index][95:64]);
                          //  $display("MISS: l2_tag_array[%h][68:46] = %h", l2_cache_index, address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)]);
                          //  $display("");
                            l2_cache_memory[l2_cache_index][95:64] <= main_memory[address / (no_of_bytes_l1_block)];
                            l2_tag_array[l2_cache_index][68:46] <= address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)];
                            l2_valid[l2_cache_index][2] <= 1'b1;  
                        end

                        2'b11 : begin 
                           // $display("way_3 MISS: l2_cache_memory[%h][127:96] = %h", main_memory[address / (no_of_bytes_l1_block)], l2_cache_memory[l2_cache_index][127:96]);
                           // $display("MISS: l2_tag_array[%h][91:69] = %h", l2_cache_index, address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)]);
                          //  $display("");
                            l2_cache_memory[l2_cache_index][127:96] <= main_memory[address / (no_of_bytes_l1_block)];
                            l2_tag_array[l2_cache_index][91:69] <= address[ADDRESS_WIDTH - 1 : (no_of_l2_index_bits + no_of_blkoffset_bits)];
                            l2_valid[l2_cache_index][3] <= 1'b1;  
                        end
                endcase
                l2_way_rr <= (l2_way_rr + 1) % no_of_l2_ways; // Increment round-robin counter               
            end

            MISS_WAIT: begin
                l1_cache_index <= address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits];
                case (address[no_of_blkoffset_bits - 1 : 0])
                    2'b00: data_out <= l1_cache_memory[l1_cache_index][7:0];
                    2'b01: data_out <= l1_cache_memory[l1_cache_index][15:8];
                    2'b10: data_out <= l1_cache_memory[l1_cache_index][23:16];
                    2'b11: data_out <= l1_cache_memory[l1_cache_index][31:24];
                endcase
                $display("MISS_WAIT: l1_cache_memory[%h] = %h", l1_cache_index, l1_cache_memory[l1_cache_index]); // Check the entire block
                $display("MISS_WAIT: l1_tag_array[%h] = %h", l1_cache_index, l1_tag_array[l1_cache_index]);
                //$display("");
                $display("MISS_WAIT: l2_cache_memory[%h] = %h", l2_cache_index, l2_cache_memory[l2_cache_index]);
                $display("MISS_WAIT: l2_tag_array[%h] = %h", l2_cache_index, l2_tag_array[l2_cache_index]);
                 $display("");
            end

            UPDATE: begin
                case (address[no_of_blkoffset_bits - 1 : 0])
                  2'b11: begin
                    l1_cache_memory[l1_cache_index][31:24] <= data_in[7:0];  // Update byte in cache
                  //  main_memory[address / (no_of_bytes_l1_block)][31:24] <= data_in[7:0]; // Update byte in main memory
                  end
                  2'b10: begin
                    l1_cache_memory[l1_cache_index][23:16] <= data_in[7:0];
                  //  main_memory[address / (no_of_bytes_l1_block)][23:16] <= data_in[7:0];
                  end
                  2'b01: begin
                    l1_cache_memory[l1_cache_index][15:8] <= data_in[7:0];
                  //  main_memory[address / (no_of_bytes_l1_block)][15:8] <= data_in[7:0];
                  end
                  2'b00: begin
                    l1_cache_memory[l1_cache_index][7:0] <= data_in[7:0];
                  //  main_memory[address / (no_of_bytes_l1_block)][7:0] <= data_in[7:0];
                  end
                endcase
                l1_tag_array[l1_cache_index] <= address[ADDRESS_WIDTH - 1 : (no_of_l1_index_bits + no_of_blkoffset_bits)];
                l1_valid[l1_cache_index] <= 1'b1;
                l1_dirty[l1_cache_index] <= 1'b1;
                $display("*UPDATE:address = %h, address_tag = %h, l1_tag_array[%h] = %h",address, address[ADDRESS_WIDTH-1:(no_of_l1_index_bits + no_of_blkoffset_bits)], l1_cache_index, l1_tag_array[l1_cache_index]);
                $display("");
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
            hit_2 = 0;
            Wait = 0;
            l2_way = 0;
            if (enable) begin
                if (~rw) begin
                    next_state = FETCH;
                    l1_cache_index = address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits];
                end else begin
                    next_state = UPDATE;
                    l1_cache_index = address[(no_of_l1_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits];
                end
            end else begin
                next_state = IDLE;
            end
        end

        FETCH: begin
                    Wait = 1;
                  //  $display("L1_FETCH:address = %h, address_tag = %h, l1_tag_array[%h] = %h",address, address[ADDRESS_WIDTH-1:(no_of_l1_index_bits + no_of_blkoffset_bits)], l1_cache_index, l1_tag_array[l1_cache_index]);
                    if (l1_valid[l1_cache_index] && (address[ADDRESS_WIDTH-1:(no_of_l1_index_bits + no_of_blkoffset_bits)] == l1_tag_array[l1_cache_index])) begin
                        hit_1 = 1;
                        hit_2 = 0;
                        next_state = IDLE;
                    end else if (l2_valid[l2_cache_index][3] && address[ADDRESS_WIDTH-1:(no_of_l2_index_bits + no_of_blkoffset_bits)] == l2_tag_array[l2_cache_index][91:69]) begin
                        hit_2 = 1;
                        hit_1 = 0;
                        next_state = IDLE;
                        l2_way = 2'b11;
                    end else if (l2_valid[l2_cache_index][2] && address[ADDRESS_WIDTH-1:(no_of_l2_index_bits + no_of_blkoffset_bits)] == l2_tag_array[l2_cache_index][68:46]) begin
                        hit_2 = 1;
                        hit_1 = 0;
                        next_state = IDLE;
                        l2_way = 2'b10;
                    end else if (l2_valid[l2_cache_index][1] && address[ADDRESS_WIDTH-1:(no_of_l2_index_bits + no_of_blkoffset_bits)] == l2_tag_array[l2_cache_index][45:23]) begin
                        hit_2 = 1;
                        hit_1 = 0;
                        next_state = IDLE;
                        l2_way = 2'b01;
                    end else if (l2_valid[l2_cache_index][0] && address[ADDRESS_WIDTH-1:(no_of_l2_index_bits + no_of_blkoffset_bits)] == l2_tag_array[l2_cache_index][22:0]) begin
                        hit_2 = 1;
                        hit_1 = 0;
                        next_state = IDLE;
                        l2_way = 2'b00;
                    end else begin // No L1 or L2 hit
                        hit_1 = 0;
                        hit_2 = 0;
                        next_state = MISS;
                    end

                    // Moved display statements here:
                    l2_cache_index = address[(no_of_l2_index_bits + no_of_blkoffset_bits - 1) : no_of_blkoffset_bits]; // Calculate l2_cache_index
                   // $display("L2_FETCH:address = %h, address_tag = %h, l2_cache_index = %h ",address, address[ADDRESS_WIDTH-1:(no_of_l2_index_bits + no_of_blkoffset_bits)], l2_cache_index);
                   // $display("way_3 tag = %h, way_2 tag = %h, way_1 tag = %h, way_0 tag = %h", l2_tag_array[l2_cache_index][91:69], l2_tag_array[l2_cache_index][68:46], l2_tag_array[l2_cache_index][45:23], l2_tag_array[l2_cache_index][22:0]);
                   // $display("way_3 data = %h, way_2 data = %h, way_1 data = %h, way_0 data = %h", l2_cache_memory[l2_cache_index][127:96], l2_cache_memory[l2_cache_index][95:64], l2_cache_memory[l2_cache_index][63:32], l2_cache_memory[l2_cache_index][31:0]);
                   // $display("way_3 valid = %h, way_2 valid = %h, way_1 valid = %h, way_0 valid = %h", l2_valid[l2_cache_index][3], l2_valid[l2_cache_index][2], l2_valid[l2_cache_index][1], l2_valid[l2_cache_index][0]);

                end
        MISS: begin
            Wait = 1;
            next_state = MISS_WAIT;
        end

        MISS_WAIT: begin
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



