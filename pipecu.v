module pipecu(op, func, ewreg, ern, em2reg, z, rs, rt, dwmem, dwreg, dregrt, dm2reg, daluc, dshift,
              daluimm, pcsource, djal, dsext,wpcir);
   input  [5:0] op,func;
   input        z,ewreg,em2reg;
	input [4:0] rs,rt,ern;
   output       wpcir,dwreg,dregrt,djal,dm2reg,dshift,daluimm,dsext,dwmem;
   output [3:0] daluc;
   output [1:0] pcsource;
   wire r_type = ~|op;
   wire i_add = r_type & func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //100000
   wire i_sub = r_type & func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] & ~func[0];          //100010
      

   
   wire i_and =  r_type & func[5] & ~func[4] & ~func[3] & func[2] & 
                ~func[1] & ~func[0]; //100100
   wire i_or  =  r_type & func[5] & ~func[4] & ~func[3] & func[2] & 
                ~func[1] & func[0]; //100101

   wire i_xor =  r_type & func[5] & ~func[4] & ~func[3] & func[2] & 
                func[1] & ~func[0]; //100110
   wire i_sll =  r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &
                ~func[1] & ~func[0]; //000000
   wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &
                func[1] & ~func[0]; //000010
   wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &
                func[1] & func[0]; //000011
   wire i_jr  = r_type & ~func[5] & ~func[4] & func[3] & ~func[2] &
                ~func[1] & ~func[0]; //001000
  
   
   wire i_addi = ~op[5] & ~op[4] &  op[3] & ~op[2] & ~op[1] & ~op[0]; //001000
   wire i_andi = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & ~op[0]; //001100
   
   wire i_ori  = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & op[0]; //001101
   wire i_xori = ~op[5] & ~op[4] &  op[3] &  op[2] & op[1] & ~op[0]; //001110
   wire i_lw   = op[5] & ~op[4] &  ~op[3] &  ~op[2] & op[1] & op[0]; //100011
   wire i_sw   = op[5] & ~op[4] &  op[3] &  ~op[2] & op[1] & op[0]; //101011
   wire i_beq  = ~op[5] & ~op[4] &  ~op[3] & op[2] & ~op[1] & ~op[0]; //000100
   wire i_bne  = ~op[5] & ~op[4] &  ~op[3] & op[2] & ~op[1] & op[0]; //000101
   wire i_lui  = ~op[5] & ~op[4] &  op[3] & op[2] & op[1] & op[0]; //001111
   wire i_j    = ~op[5] & ~op[4] &  ~op[3] & ~op[2] & op[1] & ~op[0]; //000010
   wire i_jal  = ~op[5] & ~op[4] &  ~op[3] & ~op[2] & op[1] & op[0]; //000011
   
  
   assign pcsource[1] = i_jr | i_j | i_jal;
   assign pcsource[0] = ( i_beq & z ) | (i_bne & ~z) | i_j | i_jal ;
   
   assign dwreg = (i_add | i_sub | i_and | i_or   | i_xor  |
                 i_sll | i_srl | i_sra | i_addi | i_andi |
                 i_ori | i_xori | i_lw | i_lui  | i_jal) & wpcir;
   
	wire i_rs = i_add | i_sub | i_and | i_or | i_xor | i_jr | i_addi | i_andi | i_ori |
			i_xori | i_lw | i_sw | i_beq | i_bne;
	wire i_rt = i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_sra | i_sw |
			i_beq | i_bne;
			
	 assign wpcir = ~(ewreg & em2reg & (ern != 0) & (i_rs & (ern == rs) | 
											    i_rt & (ern == rt)));
   
   assign daluc[3] = i_sra;
   assign daluc[2] = i_or | i_ori | i_lui | i_srl | i_sra | i_sub;
   assign daluc[1] = i_beq | i_bne | i_xor | i_xori | i_lui | i_sll | i_srl | i_sra;
   assign daluc[0] = i_and | i_andi | i_or | i_ori | i_sll | i_srl | i_sra;
   assign dshift   = i_sll | i_srl | i_sra ;

   assign daluimm  = i_addi | i_andi | i_ori | i_xori | i_lw | i_sw; 
   assign dsext    = i_addi | i_lw | i_sw | i_beq | i_bne;
   assign dwmem    = i_sw & wpcir;
   assign dm2reg   = i_lw;
   assign dregrt   = i_addi | i_andi | i_ori | i_xori | i_lw | i_lui;
   assign djal     = i_jal;

endmodule