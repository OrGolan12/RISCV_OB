`timescale 1 ns/1 ns                // time-unit = 1 ns, precision = 1ns
`include "alu.v"

//  Step-1: iverilog -o alu  .\alu_tb.v
//  Step-2: vvp alu
//  Step-3: gtkwave alu.vcd

module ALUTest;
  localparam ms = 1e6;
  localparam us = 1e3;
  localparam numIterations = 32;

  integer i;

  reg  [7:0]   alu_opcode;   // ALU opcode   
  reg  [31:0]  alu_imm1;     // ALU immediacls 
  reg  [31:0]  alu_imm2;     // ALU immediate-2
  wire [31:0]  alu_result;   // ALU Result

  // Our device under test
  ALU DUT(alu_opcode, alu_imm1, alu_imm2, alu_result);

  initial 
    begin
      $dumpvars(0, ALUTest);
      $display("alu_tb: Start");
      alu_opcode = 0;
      alu_imm1 = 0;
      alu_imm2 = 0;
    
      // Test operation ADD
      #10
      alu_opcode = 7'b000;//DUT.ADD;
      for (i = 0; i < numIterations; i=i+1)
        begin
          alu_imm1 = i ; //$random;
          alu_imm2 = i ; //$random;
          #10
          if (alu_result != (alu_imm1 + alu_imm2)) $error("Expected O to be %d but got %d.", (alu_imm1 + alu_imm2), alu_result);
        end

    #100
    $display("alu_tb: End");
    $finish;

  end
endmodule