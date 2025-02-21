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
// Module Name:   tb_MEMORY_CONTROLLER
// Project Name:  MEMORY_CONTROLLER with L1 Cache
// Target Device:Target Device: (FPGA: AMD/Xilinx Virtex UltraScale+) (ASIC: TSMC 16nm)
// Tool versions: all
// Description:   Testbench to simulate Memory controller 
//
// Dependencies:  None
//
// Revision:   0.02
// 
//
// Additional Comments: Needs future modifications to support L2 Cache write back
//
//
///////////////////////////////////////////////////////////////


`include "MEMORY_CONTROLLER.v"

module tb_MEMORY_CONTROLLER;    

reg clk, reset_n, enable, rw;
reg [31:0] address;
reg [7:0] data_in;
wire [7:0] data_out;

// Instantiate the Unit Under Test (UUT)

MEMORY_CONTROLLER uut (
    .clk(clk), 
    .reset_n(reset_n), 
    .enable(enable), 
    .rw(rw), 
    .address(address), 
    .data_in(data_in), 
    .data_out(data_out)
);

initial begin
    // Initialize Inputs
    clk = 1;
    reset_n = 0;
    enable = 0;
    rw = 0;
    address = 0;
    data_in = 0;

    // Wait for global reset
    #10;
    reset_n = 1;

    // write operation (write on L1 cache)
    enable = 1;
    rw = 1; // Write mode
    address = 32'h000040_10;
    data_in = 8'hAA;
    #10;
    enable = 0;
    //data_in = 0;
   // address = 32'h00000000;
    #30;

  // Read Hit (Read from L1 cache)
    #10;
    enable = 1;
    data_in = 0;
    rw = 0; // Read mode
    address = 32'h000040_10;
    #10;
    enable = 0;
    //address = 32'h00000000;
     #30;

  // Read Miss  (read from main memory)
  	#10;
    enable = 1;
    rw = 0; // Read mode
    address = 32'h000010_00;
    #10;
    enable = 0;
     #30;

  // Read Hit (Read from L1 cache)
    #10;
    enable = 1;
    data_in = 0;
    rw = 0; // Read mode
    address = 32'h000040_10;
    #10;
    enable = 0;
     #30;

    // Read Hit  (previously read from main memory now read from L1 cache)
  	#10;
    enable = 1;
    rw = 0; // Read mode
    address = 32'h0001000;
    #10;
    enable = 0;
      #30;

    // read miss (replacement of dirty L1 cache block)
    #10;
    enable = 1;
    rw = 0; // Write mode
    address = 32'h00008010;
    //data_in = 8'hBB;
    #10;
    enable = 0;
    //data_in = 0;
    #30;

    // Read miss (Read from main memory)
    #10;
    enable = 1;
    data_in = 0;
    rw = 0; // Read mode
    address = 32'h00004010;
    #10;
    enable = 0;
    #30;

     // read miss (replacement of dirty L1 cache block)
    #10;
    enable = 1;
    rw = 0; // Write mode
    address = 32'h00008010;
    //data_in = 8'hBB;
    #10;
    enable = 0;
    //data_in = 0;
    #30;

    // Finish simulation
    #40;
    $finish;
end
  

// Clock generation
always #5 clk = ~clk;
  
   initial begin
        $dumpfile("tb_MEMORY_CONTROLLER.vcd");
        $dumpvars(0, tb_MEMORY_CONTROLLER);
    end

endmodule
