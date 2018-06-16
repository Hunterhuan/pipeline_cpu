/////////////////////////////////////////////////////////////
//                                                         //
// School of Software of SJTU                              //
// anthor by Hanbing                                       //
//                                                         //
/////////////////////////////////////////////////////////////

module pipelined_computer (resetn,mem_clock, in_port0,in_port1,in_port2,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	//定义顶层模块pipelined_computer，作为工程文件的顶层入口，如图1-1建立工程时指定。
	input resetn, mem_clock;
	//定义整个计算机module和外界交互的输入信号，包括复位信号resetn、时钟信号clock、
	//以及一个和clock同频率但反相的mem_clock信号。mem_clock用于指令同步ROM和
	//数据同步RAM使用，其波形需要有别于实验一。
	//这些信号可以用作仿真验证时的输出观察信号。

	input [3:0] in_port0,in_port1; //两个input，input两个操作数
	input in_port2; //input操作类型，用于beq分支指令
	output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5; //output为LED灯的显示参数

	//模块用于仿真输出的观察信号。缺省为wire型。
	wire [31:0] bpc,jpc,npc,pc4,ins, inst;
	//模块间互联传递数据或控制信息的信号线,均为32位宽信号。IF取指令阶段。
	wire [31:0] dpc4,da,db,dimm;
	//模块间互联传递数据或控制信息的信号线,均为32位宽信号。ID指令译码阶段。
	wire [31:0] epc4,ea,eb,eimm;
	//模块间互联传递数据或控制信息的信号线,均为32位宽信号。EXE指令运算阶段。
	wire [31:0] mb,mmo;
	//模块间互联传递数据或控制信息的信号线,均为32位宽信号。MEM访问数据阶段。
	wire [31:0] wmo,wdi;
	//模块间互联传递数据或控制信息的信号线,均为32位宽信号。WB回写寄存器阶段。
	wire [4:0] drn,ern0,ern,mrn,wrn;
	//模块间互联，通过流水线寄存器传递结果寄存器号的信号线，寄存器号（32个）为5bit。
	wire [3:0] daluc,ealuc;
	//ID阶段向EXE阶段通过流水线寄存器传递的aluc控制信号，4bit。
	wire [1:0] pcsource;
	//CU模块向IF阶段模块传递的PC选择信号，2bit。
	wire wpcir;
	// CU模块发出的控制流水线停顿的控制信号，使PC和IF/ID流水线寄存器保持不变。
	wire dwreg,dm2reg,dwmem,daluimm,dshift,djal; // id stage
	// ID阶段产生，需往后续流水级传播的信号。
	wire ewreg,em2reg,ewmem,ealuimm,eshift,ejal; // exe stage
	//来自于ID/EXE流水线寄存器，EXE阶段使用，或需要往后续流水级传播的信号。
	wire mwreg,mm2reg,mwmem; // mem stage
	//来自于EXE/MEM流水线寄存器，MEM阶段使用，或需要往后续流水级传播的信号。
	
	wire wwreg,wm2reg; // wb stage
	//来自于MEM/WB流水线寄存器，WB阶段使用的信号。

	wire [31:0] pc, ealu, malu, walu;
	
	wire [31:0] inp0,inp1,inp2,out_port0,out_port1,out_port2;
	wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	
	reg clock;
	always @(posedge mem_clock)
	begin
		clock <= ~clock;
	end
	extend in0(mem_clock,in_port0, inp0);
	extend in1(mem_clock,in_port1, inp1);
	extend in2(mem_clock,in_port2, inp2);
	
	
	
	pipepc prog_cnt ( npc,wpcir,clock,resetn,pc );
	//程序计数器模块，是最前面一级IF流水段的输入。
	pipeif if_stage ( pcsource,pc,bpc,da,jpc,npc,pc4,ins,mem_clock ); // IF stage
	//IF取指令模块，注意其中包含的指令同步ROM存储器的同步信号，
	//即输入给该模块的mem_clock信号，模块内定义为rom_clk。// 注意mem_clock。
	//实验中可采用系统clock的反相信号作为mem_clock（亦即rom_clock）,
	//即留给信号半个节拍的传输时间。
	pipeir inst_reg ( pc4,ins,wpcir,clock,resetn,dpc4,inst ); // IF/ID流水线寄存器
	//IF/ID流水线寄存器模块，起承接IF阶段和ID阶段的流水任务。
	//在clock上升沿时，将IF阶段需传递给ID阶段的信息，锁存在IF/ID流水线寄存器
	//中，并呈现在ID阶段。
	pipeid id_stage (mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,
	wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
	bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
	daluimm,da,db,dimm,drn,dshift,djal ); // ID stage
	//ID指令译码模块。注意其中包含控制器CU、寄存器堆、及多个多路器等。
	//其中的寄存器堆，会在系统clock的下沿进行寄存器写入，也就是给信号从WB阶段
	//传输过来留有半个clock的延迟时间，亦即确保信号稳定。
	//该阶段CU产生的、要传播到流水线后级的信号较多。
	pipedereg de_reg ( dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,drn,dshift,
	djal,dpc4,clock,resetn,ewreg,em2reg,ewmem,ealuc,ealuimm,
	ea,eb,eimm,ern0,eshift,ejal,epc4 ); // ID/EXE流水线寄存器
	//ID/EXE流水线寄存器模块，起承接ID阶段和EXE阶段的流水任务。
	//在clock上升沿时，将ID阶段需传递给EXE阶段的信息，锁存在ID/EXE流水线
	//寄存器中，并呈现在EXE阶段。
	pipeexe exe_stage ( ealuc,ealuimm,ea,eb,eimm,eshift,ern0,epc4,ejal,ern,ealu ); // EXE stage
	//EXE运算模块。其中包含ALU及多个多路器等。
	pipeemreg em_reg ( ewreg,em2reg,ewmem,ealu,eb,ern,clock,resetn,
	mwreg,mm2reg,mwmem,malu,mb,mrn); 
	// EXE/MEM流水线寄存器
	//EXE/MEM流水线寄存器模块，起承接EXE阶段和MEM阶段的流水任务。
	//在clock上升沿时，将EXE阶段需传递给MEM阶段的信息，锁存在EXE/MEM
	//流水线寄存器中，并呈现在MEM阶段。
	pipemem mem_stage ( mwmem,malu,mb,clock,mem_clock,inp0,inp1,inp2,resetn,out_port0,out_port1,out_port2,mmo);// MEM stage
	//MEM数据存取模块。其中包含对数据同步RAM的读写访问。// 注意mem_clock。
	//输入给该同步RAM的mem_clock信号，模块内定义为ram_clk。
	//实验中可采用系统clock的反相信号作为mem_clock信号（亦即ram_clk）,
	//即留给信号半个节拍的传输时间，然后在mem_clock上沿时，读输出、或写输入。
	pipemwreg mw_reg ( mwreg,mm2reg,mmo,malu,mrn,clock,resetn,
	wwreg,wm2reg,wmo,walu,wrn); // MEM/WB流水线寄存器
	//MEM/WB流水线寄存器模块，起承接MEM阶段和WB阶段的流水任务。
	//在clock上升沿时，将MEM阶段需传递给WB阶段的信息，锁存在MEM/WB
	//流水线寄存器中，并呈现在WB阶段。
	mux2x32 wb_stage ( walu,wmo,wm2reg,wdi ); // WB stage
	//WB写回阶段模块。事实上，从设计原理图上可以看出，该阶段的逻辑功能部件只
	//包含一个多路器，所以可以仅用一个多路器的实例即可实现该部分。
	//当然，如果专门写一个完整的模块也是很好的。

	//display module， 将输出的数字转化为LED的参数
	sc_display show(mem_clock, out_port0, out_port1, out_port2, HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	
endmodule

//将input拓展为32位数据
module extend(clk,in_port, inp);

	input clk;
	input [3:0] in_port;
	output reg [31:0] inp;
	always @(posedge clk)
	begin
		inp <= {28'b0, in_port};
	end

endmodule

//display module， 将输出的数字转化为LED的参数
module sc_display(clock, out_port0, out_port1, out_port2, hex0,hex1,hex2,hex3,hex4,hex5);
input clock;
input [31:0] out_port0, out_port1,out_port2;
output [6:0] hex0,hex1,hex2,hex3,hex4,hex5;

reg [31:0] num0, num1, num2, num3, num4, num5;

always @(posedge clock)
begin
	if(out_port0<10)
	begin
		num0 = 0;
		num1 = out_port0;
	end
	else
	begin
		num0 = 1;
		num1 = out_port0-10;
	end

	if(out_port1<10)
	begin
		num2 = 0;
		num3 = out_port1;
	end
	else
	begin
		num2 = 1;
		num3 = out_port1-10;
	end
	num4 = out_port2/10;
	num5 = out_port2 - num4*10;
end
//调用LED显示
sevenseg display_0_high (num0, hex0);
sevenseg display_0_low (num1, hex1);
sevenseg display_1_high (num2, hex4);
sevenseg display_1_low (num3, hex5);
sevenseg display_2_high (num4, hex2);
sevenseg display_2_low (num5, hex3);
endmodule