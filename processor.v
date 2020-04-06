module Instruction_Fetch(input clk,input reset,output [7:0] Instruction_Code,output reg [7:0]PC,input PC_Source,input [7:0]JTA);

wire [7:0]pc_assign;
assign pc_assign = (PC_Source==1)?JTA:PC+1;
always@(posedge clk,negedge reset)
begin
if(reset==0)
PC<=0;
else 
    PC<=pc_assign;
end
Instruction_Memory ABC(PC,reset,Instruction_Code);
endmodule

//*****************************************************************************************************************

module Instruction_Memory(input [7:0] PC,input reset,output [7:0]Instruction_Code);
reg [7:0]Mem[5:0];
assign Instruction_Code ={Mem[PC]};
always@(reset)
begin 
if (reset==0)
begin
Mem[0]=8'b00001010;Mem[1]=8'b01001001;Mem[2]=8'b00010001;Mem[3]=8'b11000001;
Mem[4]=8'b01010011;Mem[5]=8'b00110010;
end
end
endmodule

//*****************************************************************************************************************

module Register_file(
input [2:0] Read_Reg_1,
input [2:0] Read_Reg_2,
input [2:0] Write_Reg_Num,
input [7:0] Write_Data,
output [7:0] Read_Data_1,
output [7:0] Read_Data_2,
input Regwrite
);

reg [7:0] RegMemory [7:0];

initial begin
RegMemory[0] = 8'h00; 
RegMemory[1] = 8'h01;
RegMemory[2] = 8'h02; 
RegMemory[3] = 8'h03; 
RegMemory[4] = 8'h04; 
RegMemory[5] = 8'h05; 
RegMemory[6] = 8'h06; 
RegMemory[7] = 8'h07; 
end

assign Read_Data_1 = RegMemory[Read_Reg_1];
assign Read_Data_2 = RegMemory[Read_Reg_2];

always@(*)
begin
   if(Regwrite==1)
   RegMemory[Write_Reg_Num]=Write_Data;
 
end

endmodule
//*****************************************************************************************************************

module ALU(input [7:0] A,input [7:0] B,input Control_alu,output reg [7:0] Result);
  
  always@(A,B,Control_alu)
  begin 
    
    case (Control_alu)
      
    1'b0 : Result = A + B;
	1'b1 : Result = A << B;  
	 	  
      default : $display("Invalid ALU control signal");
      
    endcase
  end
endmodule
//*****************************************************************************************************************
  
module Control(input [1:0] Op_Code,output reg PC_Source,output reg Alucntrl,output reg alu_source,output reg Regwrite);

initial begin
  PC_Source = 0;
end
always@(Op_Code)
	
	begin
	case(Op_Code)
		2'b00: 
			begin
			alu_source = 1'b0;
			Alucntrl=1'b0;
			PC_Source=1'b0;
			Regwrite=1'b1;
			end		
		2'b01 : 
			begin
			alu_source = 1'b1;
			Alucntrl=1'b1;
			PC_Source=1'b0;
			Regwrite=1'b1;
			end	
		2'b11: 
			 begin 
			PC_Source=1'b1;
			Regwrite=1'b0;
			
			end	
			
		2'b10:     //nop
			begin
			alu_source = 1'b0;
			Alucntrl=1'b0;
			PC_Source=1'b0;
			Regwrite=1'b0;
			end		
		endcase
	end
endmodule
//*****************************************************************************************************************
module forwarding_unit(input [7:0] ID_EX_IC, input [7:0]  EX_WB_IC, output reg [1:0] forward_signal);

wire [1:0] OpCode;
assign OpCode = ID_EX_IC [7:6];
always@(OpCode)
	
	begin
	case(OpCode)
		2'b00: 
			begin 
			if(ID_EX_IC[2:0] ==  EX_WB_IC[5:3])
			forward_signal = 2'b11;
			else 
			forward_signal = 2'b00;
			end		
		2'b01: 
			begin 
			if(ID_EX_IC[5:3] ==  EX_WB_IC[5:3])
			forward_signal = 2'b10;
			else 
			forward_signal = 2'b00;
			end	
			
			
		default : forward_signal = 00;
		endcase
	end
endmodule


//*****************************************************************************************************************

 
 module Pipelined_processor(input clk,input reset);
  
  ///Defining pipeline registers
  //stage 1
  reg [7:0]	IF_ID_PC;
  reg [7:0]	IF_ID_IC;

  //stage 2
  reg [7:0]	 ID_EX_Read_Data_1;
  reg [7:0]	 ID_EX_Read_Data_2;
  reg [7:0]	 ID_EX_IC;  
  reg  ID_EX_alu_source;
  reg  ID_EX_Regwrite;
  reg  ID_EX_Alucntrl;
  
  //stage 3
  reg [7:0]	  EX_WB_IC;
  reg   EX_WB_Regwrite;
  reg [7:0]	EX_WB_AluRes;

wire [7:0] Instruction_Code;
wire [7:0] PC;
wire [7:0] JTA;
wire PC_Source;

wire [7:0] Read_Data_1;
wire [7:0] Read_Data_2;
wire [7:0] Write_Data;

wire Alucntrl;
wire alu_source;
wire Regwrite;
Instruction_Fetch IF_mod(clk,reset,Instruction_Code,PC,PC_Source,JTA);

  always@(posedge clk)
  begin
  if(reset==0)
	begin
		IF_ID_PC<=0;
		IF_ID_IC<=0;
	end
   else
   begin
	IF_ID_PC<=PC+1;
	IF_ID_IC<=Instruction_Code;
  end

  if(PC_Source==1)
  IF_ID_IC<=8'h80;
  end
 
Control control_mod(IF_ID_IC[7:6],PC_Source,Alucntrl,alu_source,Regwrite); 
Register_file reg_mod(IF_ID_IC[2:0],IF_ID_IC[5:3], EX_WB_IC[5:3],Write_Data,Read_Data_1,Read_Data_2, EX_WB_Regwrite);

  always@(posedge clk)
  begin
  if(reset==0)
	begin
  ID_EX_IC<=0;
  ID_EX_Read_Data_1<=0;
  ID_EX_Read_Data_2<=0;
  ID_EX_alu_source<=0;
  ID_EX_Alucntrl<=0;
  ID_EX_Regwrite<=0;
	end
	else
	begin
  ID_EX_IC<=IF_ID_IC;
  ID_EX_Read_Data_1<=Read_Data_1;
  ID_EX_Read_Data_2<=Read_Data_2;
  ID_EX_alu_source<=alu_source;
  ID_EX_Alucntrl<=Alucntrl;
  ID_EX_Regwrite<=Regwrite;
  end
  end  
wire [7:0]Alu_input_1;
wire [7:0]Alu_input_2;
wire [7:0] data_mux;
wire [7:0] sign_extension;
wire [1:0] forward_signal;
wire [7:0] Aluresult;
//sign_extensiontension
assign sign_extension[5:0] =IF_ID_IC[5:0];				
assign sign_extension[7:6] = {2{IF_ID_IC[5]}};
assign  JTA =IF_ID_PC +sign_extension; 

forwarding_unit fwdmod (ID_EX_IC,  EX_WB_IC, forward_signal); 
//multiplexers
assign Alu_input_1 =(forward_signal==2'b10)? EX_WB_AluRes:ID_EX_Read_Data_2 ;
assign data_mux =(forward_signal==2'b11)? EX_WB_AluRes:ID_EX_Read_Data_1 ;
assign Alu_input_2=(ID_EX_alu_source==0)? data_mux:ID_EX_IC[2:0];
  
ALU alu_mod(Alu_input_1,Alu_input_2,ID_EX_Alucntrl,Aluresult);
 always@(posedge clk)
  begin
   if(reset==0)
	begin
   EX_WB_IC<= 0;
   EX_WB_AluRes<=0;
   EX_WB_Regwrite<=0;
	end
	else
	begin
   EX_WB_IC<= ID_EX_IC;
   EX_WB_AluRes<=Aluresult;
   EX_WB_Regwrite<=ID_EX_Regwrite;
   end
  end 
  assign Write_Data =EX_WB_AluRes;   
  endmodule
//*****************************************************************************************************************
  
  
module testbench_pipeline;
 
reg reset_t;
reg clk_t;
Pipelined_processor pipeline_proc_mod(clk_t,reset_t);
initial begin
clk_t=0;
forever #10 clk_t=~clk_t;
end 
initial begin 
reset_t=0;
#6 reset_t=1;
#170 $finish;
end

endmodule
//*****************************************************************************************************************