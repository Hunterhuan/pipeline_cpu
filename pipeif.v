module pipeif( pcsource,pc,bpc,da,jpc,npc,pc4,ins,rom_clk );
	input [31:0] pc, bpc, da, jpc;
	input [1:0] pcsource;
	input rom_clk;
	output [31:0] npc, pc4, ins;
	
	wire [31:0] npc, pc4, ins;
	lpm_rom_irom irom(pc[7:2], rom_clk, ins);

	assign pc4 = pc + 32'h4;

	mux4x32 new_pc(pc4,bpc,da,jpc,pcsource,npc);
endmodule
