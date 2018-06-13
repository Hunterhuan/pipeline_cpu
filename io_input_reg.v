module io_input_reg (addr,io_clk,io_read_data,in_port0,in_port1,in_port2);
input [31:0] addr;
input io_clk;
input [31:0] in_port0,in_port1,in_port2;
output [31:0] io_read_data;
reg [31:0] in_reg0; // input port0
reg [31:0] in_reg1; // input port1
reg [31:0] in_reg2;
wire [31:0] io_read_data;
io_input_mux io_input_mux2x32(in_reg0,in_reg1,in_reg2,addr[7:2],io_read_data);
always @(posedge io_clk)
begin
	in_reg0 <= in_port0; // 输入端口在io_clk上升沿时进行数据锁存
	in_reg1 <= in_port1; // 输入端口在io_clk上升沿时进行数据锁存
	in_reg2 <= in_port2; // 输入端口在io_clk上升沿时进行数据锁存
	// more ports，可根据需要设计更多的输入端口。
end
endmodule
