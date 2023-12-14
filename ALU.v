`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2023 12:02:00 AM
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    input [31:0] imm1,
    input [31:0] imm2,
    input [7:0] opcode,
    
    output reg [31:0] result      
    );

parameter ADD = 7'b000;  //ADD performs the addition of rs1 and rs2. Overflows are ignored and the low XLEN bits of results are written to rd.
parameter SUB = 7'b001; //SUB performs the subtraction of rs1 and rs2. Overflows are ignored and the low XLEN bits of results are written to rd.

parameter AND = 7'b010;
parameter OR = 7'b011;
parameter XOR = 7'b100; //XOR performs bitwise exclusive or on rs1 and 'rs2' and the result is written to 'rd'.

parameter SLL = 7'b101; //SLL perform logical (aka unsigned) left shift on the value in rs1 by the shift amount held in the lower 5 bits of rs2.
parameter SLT = 7'b110; //SLT performs signed compare between rs1 and rs2, writing 1 to rd if rs1 < rs2, 0 otherwise.
parameter SLTU = 7'b111;

parameter SRA = 7'b1000; //SRA perform arithmetic (aka signed) right shift on the value in reg rs1 by the shift amount held in the lower 5 bits of reg rs2.
parameter SRL = 7'b1001; //SRL perform logical (aka unsigned) right shift on the value in rs1 by the shift amount held in the lower 5 bits of rs2.

always@(*)
begin
    case (opcode)
        ADD :         
            result = imm1 + imm2;
        SUB :         
            result = imm1 - imm2;                
        AND :         
            result = imm1 & imm2;
        OR :         
            result = imm1 | imm2; 
        XOR :
            result = imm1 ^ imm2;
        SLL : 
            result = imm1 << (imm2 & 32'b11111); 
        SLTU : begin
                if (imm1 < imm2)
                    result = 1;
                else
                    result = 0;
               end
            
        SLT : begin
                if (({imm1[31], imm1}) < ({imm2[31], imm2}))
                    result = 1;
                else
                    result = 0;
               end
        SRA : result = imm1 >>> imm2;
        SRL : result = imm1 >> imm2;
    endcase

end
endmodule

module REG_FILE(
    input clk, rst, write_enable,//1 = write
    //port 0    
    input [6:0] rs1_add,
    output reg [31:0] rs1,
    //port 1
    input [6:0] rs2_add,
    output reg [31:0] rs2,
    
    //write
    input [6:0] rd_add,
    input [31:0] rd
    );

reg [31:0] mem [31:0];
integer i = 0;

initial 
    begin
        for (i=0; i < 32; i = i + 1)
            mem[i] = 0;
    end

always@ (posedge clk)
    begin
        if (!rst)
            begin
                if (write_enable)
                    mem[rd_add] = rd;
                else
                begin
                    rs1 = mem[rs1_add];
                    rs2 = mem[rs2_add];
                end
            end 
    end   

endmodule
    
module DECODER(
    input [31:0] instruction,
    input RDY_BSY, rst, clk,
    
    //alu
    input [31:0] result,
    output reg [7:0] opcode,
    output reg [31:0] imm1,
    output reg [31:0] imm2,
    
    
    //reg_file
    input [31:0] reg1,
    input [31:0] reg2,   
    output reg [4:0] rs1_add,
    output reg [4:0] rs2_add,
    output reg [4:0] rd_add,
    output reg [31:0] rd
    );

parameter idle = 0;
parameter decode = 1;
parameter read_regfile = 2'b10;
parameter read_alu = 2'b11;

    
reg [3:0] state = idle;



parameter R_TYPE_OP = 7'b0110011;
parameter I_TYPE_OP = 7'b0010011;

parameter ADD = 3'b000;  //ADD performs the addition of rs1 and rs2. Overflows are ignored and the low XLEN bits of results are written to rd.
parameter SUB = 3'b000; //SUB performs the subtraction of rs1 and rs2. Overflows are ignored and the low XLEN bits of results are written to rd.
parameter AND = 3'b111;
parameter OR = 3'b110;
parameter SLL = 3'b001; //SLL perform logical (aka unsigned) left shift on the value in rs1 by the shift amount held in the lower 5 bits of rs2.
parameter SLT = 3'b010; //SLT performs signed compare between rs1 and rs2, writing 1 to rd if rs1 < rs2, 0 otherwise.
parameter SLTU = 3'b011;
parameter SRA = 3'b101; //SRA perform arithmetic (aka signed) right shift on the value in reg rs1 by the shift amount held in the lower 5 bits of reg rs2.
parameter SRL = 3'b101; //SRL perform logical (aka unsigned) right shift on the value in rs1 by the shift amount held in the lower 5 bits of rs2.
parameter XOR = 3'b100; //XOR performs bitwise exclusive or on rs1 and 'rs2' and the result is written to 'rd'.

reg [7:0] opcode_alu;
//reg [6:0] rs1_add_rf;
//reg [6:0] rs2_add_rf; 
reg [6:0] rd_add_rf;
//reg [11:0] imm2_reg;

always@ (posedge clk)
begin
    if (rst)
    begin 
    
    imm1 <= 0;
    imm2 <= 0;
    opcode <= 0;
    rs1_add <= 0;
    rs2_add <= 0;
    state <= idle;
    
    end
    
    if (!rst)
    begin
    case(state)
        idle :  begin 
        
                    if (RDY_BSY) //posedge RDY_BSY//
                        state <= decode;
                end
        
        decode : begin
                            case(instruction[14:12])
                            ADD : begin
                                    if (instruction[31:25] == 0)                                       
                                        opcode_alu <= 7'b000;
                                    if  (instruction[31:25] == 7'b0100000)
                                        opcode_alu <= 7'b001;
                                  end
                            AND : opcode_alu <= 7'b010;
                            OR : opcode_alu <= 7'b011;                            
                            XOR : opcode_alu <= 7'b100; 
                            SLL : opcode_alu <= 7'b101;
                            SLT : opcode_alu <= 7'b110; 
                            SLTU : opcode_alu <= 7'b111; 
                            SRA : opcode_alu <= 7'b1000;
                            SRL : opcode_alu <= 7'b1001;                                                        
                        endcase
                       
                       if (instruction[6:0] == R_TYPE_OP)
                           begin
                            rd_add_rf <= instruction[11:7];
                            rs1_add <= instruction[19:15];
                            rs2_add <= instruction[24:20];    
                           end
                           
                       if (instruction[6:0] == I_TYPE_OP)
                           begin
                            rd_add_rf <= instruction[11:7];
                            rs1_add <= instruction[19:15];
                            imm2 <= instruction[31:20];
                           end
                           
                     state <= read_regfile;  
              end

         read_regfile :
                begin
                        imm1 <= reg1;
                        if (instruction[6:0] == I_TYPE_OP)
                            begin
                            imm2 <= instruction[31:20];
                            end 
                        if (instruction[6:0] == R_TYPE_OP)
                            begin
                            imm2 <= reg2;
                            end 
                        state <= read_alu;                                               
                end 
         read_alu : 
                begin 
                    rd <= result;
                    state <= idle;           
                end
    endcase 
       
    end
   
    
end


    
endmodule       
   