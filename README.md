# 《5段流水CPU设计》实验报告

姓名：韩冰

学号：516030910523

***

## 1.实验目的

1. 理解计算机指令流水线的协调工作原理，初步掌握流水线的设计和实现原理。
2. 深刻理解流水线寄存器在流水线实现中所起的重要作用。    
3. 理解和掌握流水段的划分、设计原理及其实现方法原理。    
4. 掌握运算器、寄存器堆、存储器、控制器在流水工作方式下，有别于实验一的设计和实现方法。
5. 掌握流水方式下，通过 I/O 端口与外部设备进行信息交互的方法。

## 2.实验内容

1. 采用 Verilog 在 quartusⅡ中实现基本的具有 20 条 MIPS 指令的 5 段流水 CPU 设计。    
2. 利用实验提供的标准测试程序代码，完成仿真测试。    
3. 采用 I/O 统一编址方式，即将输入输出的 I/O 地址空间，作为数据存取空间 的一部分，实现 CPU 与外部设备的输入输出端口设计。实验中可采用高端地址。
4. 利用设计的 I/O 端口，通过 lw 指令，输入 DE2 实验板上的按键等输入设备 信息。即将外部设备状态，读到 CPU 内部寄存器。
5. 利用设计的 I/O 端口，通过 sw 指令，输出对 DE2 实验板上的 LED 灯等输出 设备的控制信号（或数据信息）。即将对外部设备的控制数据，从 CPU 内部 的寄存器，写入到外部设备的相应控制寄存器（或可直接连接至外部设备的控制输入信号）。
6. 利用自己编写的程序代码，在自己设计的 CPU 上，实现对板载输入开关或 按键的状态输入，并将判别或处理结果，利用板载 LED 灯或 7 段 LED 数码 管显示出来。
7. 例如，将一路 4bit 二进制输入与另一路 4bit 二进制输入相加，利用两组分别 2 个 LED 数码管以 10 进制形式显示“被加数”和“加数”，另外一组 LED 数码管以 10 进制形式显示“和”等。（具体任务形式不做严格规定，同学可 自由创意）。
8. 在实验报告中，汇报自己的设计思想和方法；并以汇编语言的形式，提供采用以上自行设计的指令集的作品应用功能的程序设计代码，并提供程序主要流程图。

## 3.设计分析

​	本实验要求设计一个5段流水线CPU，对CPU进行顶层设计，然后分别实现IF、ID、EX、MEM、WB等几个阶段和之间的寄存器模块。尤其注意的应该是多个模块之间控制信号的赋值使用。实现该CPU部分简单指令，并对其进行仿真，最后设计I/O端口，使用该CPU进行一个简单的功能实现。

​	流水线CPU的核心是将单周期CPU分为5个可以独立运行的段，从而通过并行加速CPU，该功能也是主要依赖于流水线寄存器实现，在之前单周期CPU设计的基础上，加入时钟驱动的5个流水线寄存器模块即可实现。单周期中寄存器模块、指令内存模块、数据内存模块、各类复用器基本都不需要修改。

​	但流水线CPU的困难还包括大量的冒险，MIPS指令集需要考虑数据冒险和控制冒险。查阅资料后，我决定在本次实验中采用转发旁路的方法解决数据冒险。对于控制冒险，我则是采用所有的分支都未跳转处理，然后转移延迟的方法来减少流水线的转移代价。

​	最后是对I/O进行设计。I/O根据实验指导书第3个实验，设计sc_datamen.v模块，进行I/O设计，最后设计程序，用汇编语言实现，生成mif文件，使CPU能够输出运算结果。

CPU设计主要参考图如下：![Alt text](https://github.com/Hunterhuan/pipeline_cpu/raw/master/Screenshots/1.png)

## 4.程序设计

### 1.顶层模块

按照上图，我们来完成顶层模块的设计。

顶层模块pipelined_computer.v 包括控制信号变量的定义，产生时钟信号，调用IF、ID、EX、MEM、WB阶段的模块和各个模块之间的寄存器模块。还有I/O模块和display模块。在这个module中尤其要注意各种变量的输入输出。不能混淆，每个变量名都有自己的含义。

模块功能在注释中已经给出。

```verilog
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
	
    //产生时钟信号
	reg clock;
	always @(posedge mem_clock)
	begin
		clock <= ~clock;
	end
    extend in0(mem_clock,in_port0, inp0); //拓展为32位
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
```

### 2.底层模块

我在底层模块中主要展示在单周期CPU基础上的添加设计。

#### 1.IF/ID寄存器模块

​	该寄存器主要存在于IF/ID阶段，主要存储后阶段要用到的信号，IF阶段获取到的instruction，还有PC+4后的pc4，把变量标记为output，供其他module使用。

​	还有一点要注意的是wpcir变量，这个是控制流水线阻塞的信号。如果发生不能避免的冒险，通过该信号阻塞赋值即可。在控制单元模块的介绍中会给出该信号的详解。

```verilog
module pipeir( pc4,ins,wpcir,clock,resetn,dpc4,inst );
	input [31:0] pc4, ins;
	input wpcir;
	input clock,resetn;
    output [31:0] dpc4, inst;//ir寄存器中存储的数据
	reg [31:0] dpc4, inst;
    always @(posedge clock)//根据时钟信号
	begin
        if(resetn == 0)//如果是重置信号，那么全置位0.
		begin
			dpc4 <= 0;
			inst <= 0;
		end
		else 
		begin
            if(wpcir)//如果没有阻塞，那么就更新pc4，和instruction
			begin
				dpc4 <= pc4;
				inst <= ins;
			end
		end
	end
endmodule
```

#### 2.pipe_id模块

​	在ID阶段，CPU进行译码操作和取操作数的操作。译码是将instruction翻译成相应的操作，产生相应的控制信号。取操作数则是将要用到的数字从寄存器存储器中取出来，供下阶段计算使用。

​	之前说了解决数据冒险主要依靠转发旁路来实现。在ID阶段，要决定将什么操作数送入alu中进行计算，所以转发旁路就要在这里进行操作，将其他的数据转发过来。原理图如图所示：

![Alt text](https://github.com/Hunterhuan/pipeline_cpu/raw/master/Screenshots/2.png)

![Alt text](https://github.com/Hunterhuan/pipeline_cpu/raw/master/Screenshots/3.png)

```verilog
//该代码是转发控制单元。转发控制单元用来比较后几个阶段（EXE，和MEM）的目标寄存器值和rs、rt的值，若相同，则选择后几个阶段储存的alu输出值或memory输出值，作为ID阶段寄存器堆的输出。
//fwda，fwdb则是控制哪个数据被送入寄存器堆的判断信号。
always @ (ewreg or mwreg or ern or mrn or em2reg or mm2reg or rs or rt)
	begin
		fwda = 2'b00; //正常的话就是把instruction的直接送入alu
		if (ewreg & (ern != 0) & (ern == rs) & ~em2reg)
		begin
			fwda = 2'b01; //将之前指令的alu阶段的输出送入alu
		end
		else
		begin
			if (mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg) 
			begin
				fwda = 2'b10;
			end
			else 
			begin
				if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg)
				begin
					fwda = 2'b11; //将之前指令的memory的输出送入alu
				end
			end
		end
		
		fwdb = 2'b00;
		if (ewreg & (ern != 0) & (ern == rt) & ~em2reg)
		begin
			fwdb = 2'b01; //同上
		end
		else
		begin
			if (mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg) 
			begin
				fwdb = 2'b10; // 同上
			end
			else 
			begin
				if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg)
				begin
					fwdb = 2'b11; //同上
				end
			end
		end
	end
```
#### 3.pipe_cu模块

control unit是处理冒险的关键。

处理控制冒险。

```verilog
//冒险控制单元用来检测MEM阶段前存储的要写入的寄存器的地址，与rs与rt的值进行比较，若相等，则发生了冒险，通过将wpcir置零，不写PC和IR，从而插入一个周期的空指令。来阻塞流水线，达到解决数据冒险的效果。
//实现代码如下：
wire i_rs = i_add | i_sub | i_and | i_or | i_xor | i_jr | i_addi | i_andi | i_ori |
			i_xori | i_lw | i_sw | i_beq | i_bne;
wire i_rt = i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_sra | i_sw |
			i_beq | i_bne;
assign wpcir = ~(ewreg & em2reg & (ern != 0) & (i_rs & (ern == rs) | 
											    i_rt & (ern == rt)));

//处理控制冒险，在ID阶段比较寄存器堆的2个输出值，提前判断分支是否发生，不必在EXE阶段再进行比较，减少了一个周期时间的浪费。同时，在分支指令（beq,bne,j,jr,jal等）的下一条插入一条必定执行的指令，以由空指令带来的浪费。
//相关代码如下:

wire z = ~|(da^db);//判断是否要发生。
assign pcsource[1] = i_jr | i_j | i_jal;
assign pcsource[0] = ( i_beq & z ) | (i_bne & ~z) | i_j | i_jal ;
```
#### 4.ID/EXE寄存器模块

流水线寄存器模块主要是寄存了IF和ID阶段产生的，并且在后续阶段要用到的数据。

```verilog
//在该流水线寄存器中，主要寄存的就是ID阶段产生的控制信号
//eg: clock，重置信号，pc值，jal跳转信号，aluimm，shift移位信号.....
module pipedereg ( dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,drn,
                   dshift,djal,dpc4,clock,resetn,ewreg,em2reg,ewmem,
                   ealuc,ealuimm,ea,eb,eimm,ern0,eshift,ejal,epc4 );

   input         dwreg,dm2reg,dwmem,djal,daluimm,dshift;
   input  [31:0] dpc4,da,db,dimm ;
   input  [3:0]  daluc;
   input  [4:0]  drn;
   input         clock,resetn;
   wire          clock,resetn;
   output        ewreg,em2reg,ewmem,ejal,ealuimm,eshift;
   output [31:0] epc4,ea,eb,eimm ;
   output [3:0]  ealuc;
   output [4:0]  ern0;
   reg           ewreg,em2reg,ewmem,ejal,ealuimm,eshift;
   reg    [31:0] epc4,ea,eb,eimm ;	
   reg    [3:0]  ealuc;
   reg    [4:0]  ern0;

   always @ (negedge resetn or posedge clock)
       if (resetn == 0) //如果重置键，那么就全置零。
         begin
            epc4       <= 32'b0;ea         <= 32'b0;
            eb         <= 32'b0;eimm       <= 32'b0; 
            ealuc      <=  4'b0;ern0       <=  5'b0;
            ewreg      <=  1'b0;em2reg     <=  1'b0;
            ewmem      <=  1'b0;ejal       <=  1'b0;
            ealuimm    <=  1'b0;eshift     <=  1'b0;
         end 
      else               //否则，就将信号储存在寄存器中
         begin 
            epc4       <=  dpc4;ea         <=  da;
            eb         <=  db;eimm       <=  dimm;
            ealuc[3:0] <=  daluc[3:0];ern0       <=  drn;
            ewreg      <=  dwreg;em2reg     <=  dm2reg;
            ewmem      <=  dwmem;ejal       <=  djal;
            ealuimm    <=  daluimm;eshift     <=  dshift;
         end
endmodule
```
#### 5.流水线寄存器模块

```verilog
//剩余流水线寄存器模块原理几乎相同，不再介绍
```



## 5.实验结果

1. 首先完成编程后，在ModelSim中进行仿真。

可以观察到，每个信号的周期比，clock:mem_clk=1:1，信号相反，每个周期中，PC进行一次更新，instruction进行一次更新。仿真结果正确，开始进行I/O设计。

2. 我设计的I/O的思路：我实现的是一个计算器（具有加减功能），利用10个开关，第一个为1时计算器处于运行状态，第二个（1为减法，0为加法），后面每4个是二进制操作数的输入，表示二进制数，最后的结果在显像管中显示出来。

我的汇编语言mif文件设计如下：

```
DEPTH = 32;           % Memory depth and width are required %
WIDTH = 32;           % Enter a decimal number %
ADDRESS_RADIX = HEX;  % Address and value radixes are optional %
DATA_RADIX = HEX;     % Enter BIN, DEC, HEX, or OCT; unless %
                      % otherwise specified, radixes = HEX %
CONTENT
BEGIN
[0..1F] : 00000000;   % Range--Every address from 0 to 1F = 00000000 %

 0 : 20010080;        % (00)       addi $1, $0, 128 #  %
 1 : 20020084;        % (04)       addi $2, $0, 132 #  %
 2 : 20030088;        % (08)       addi $3, $0, 136 #  %
 3 : 200400c0;        % (0c)       addi $4, $0, 192 #  %
 4 : 200500c4;        % (10)       addi $5, $0, 196 #  %
 5 : 200600c8;        % (14)       addi $6, $0, 200 #  %
 7 : 20070000;        % (1c)       addi $7, $0, 0   #  %
 8 : 20080000;        % (20)       addi $8, $0, 0   #  %
 9 : 20090000;        % (24)       addi $9, $0, 0   #  %
 A : 8c870000;        % (28)       lw $7, 0($4)     #  %
 B : 8ca80000;        % (2c)       lw $8, 0($5)     #  %
 C : 8cc90000;        % (30)       lw $9, 0($6)     #  %
 D : 11200002;        % (34)       beq $9, $0, Else #  %
 E : 00e85022;        % (38)       sub $10,$7,$8    #  %
 F : 0c000012;        % (3c)       jal Exit         #  %
11 : 00e85020;        % (44)       add $10,$7,$8    #  %
13 : ac270000;        % (4c)       sw $7,0($1)      #  %
14 : ac480000;        % (50)       sw $8,0($2)      #  %
15 : ac6a0000;        % (54)       sw $10,0($3)     #  %
16 : 08000006;        % (58)       j loop           #  %
END ;
```

​	其中lw \$9, 0(\$6) 和 beq \$9, \$0, 0 是数据冒险，beq \$9, \$0, 0 和 sub \$10, \$7, \$8 是控制冒险，经经测试，并没有出现问题。说明冒险成功解决。

​	这是一个始终在运行的循环，首先是从寄存器中读入操作数和操作类型，beq条件分支，判断是加法还是减法，然后运算后存到寄存器中。流程图如下：

![Alt text](https://github.com/Hunterhuan/pipeline_cpu/raw/master/Screenshots/4.png)

## 6.心得体会

​	在这次实验中，复习并巩固了5段流水线CPU的相关知识，并加强了对verilog语言的理解。通过翻阅课本、课件，对单周期CPU各部件的功能和相互连接尤其是控制单元更加熟悉。

​	这是用verilog语言完成的第三次作业，在单周期CPU的基础上进行流水线CPU的设计，还是觉得很困难的。与之前的实验梯度还是很大的，对modelsim等软件使用不是很熟练的情况下，完成本实验还是极其困难的。

​	我在这次实验中也遇到了很多的问题，verilog的仿真遇到各种各样的错误，代码也出现各种error，幸运的是也都查到了错误原因，吸取经验，及时纠正。这次实验难点就在于冒险的处理，以及流水线信号的管理，在实现过程中主要参考之前的课件，还有相关的参考读物，反复实验也解决了这些问题。

​	这次实验让我对CPU整体运行流程有了更清晰的认识，对上个实验单周期中的具体细节也有了更深的了解。其次，对verilog语言的调试和仿真也有了进一步的认识。能力得到了提升！

​	很感谢老师和助教的解答和帮助，让我们能够顺利的完成这次实验并得到能力的提升！
