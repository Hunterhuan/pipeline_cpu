module pipemwreg(mwreg,mm2reg,mmo,malu,mrn,clock,resetn,
wwreg,wm2reg,wmo,walu,wrn);

	input mwreg,mm2reg;
	input [31:0] malu,mmo;
	input [4:0] mrn;
	input clock,resetn;
	output wwreg,wm2reg;
	output [31:0] walu,wmo;
	output [4:0] wrn;
	
	reg wwreg,wm2reg;
	reg [31:0] walu,wmo;
	reg [4:0] wrn;
	
	always @(posedge clock or negedge resetn)
	begin
		if(resetn==0)
			begin
				wrn <= 0;
				walu <= 0;
				wmo <= 0;
				wwreg <= 0;
				wm2reg <= 0;
			end
		else 
			begin
				wrn <= mrn;
				walu <= malu;
				wmo <= mmo;
				wwreg <= mwreg;
				wm2reg <= mm2reg;
			end
	end
endmodule
