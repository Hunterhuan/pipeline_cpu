module pipeemreg( ewreg,em2reg,ewmem,ealu,eb,ern,clock,resetn,
mwreg,mm2reg,mwmem,malu,mb,mrn);


	input ewreg,em2reg,ewmem,clock,resetn;
	input [4:0] ern;
	input [31:0] ealu,eb;
	output mwreg,mm2reg,mwmem;
	output [31:0] malu,mb;
	output[4:0] mrn;

	reg [4:0] mrn;
	reg [31:0] malu, mb;
	reg mwmem, mm2reg, mwreg;

	always @(posedge clock or negedge resetn)
	begin
		if(resetn==0)
			begin
				mrn <= 0;
				malu <= 0;
				mb <= 0;
				mwmem <= 0;
				mm2reg <= 0;
				mwreg <= 0;
			end
		else 
			begin
				mrn <= ern;
				malu <= ealu; 
				mb <= eb;
				mwmem <= ewmem;
				mm2reg <= em2reg;
				mwreg <= ewreg;
			end
	end
endmodule
