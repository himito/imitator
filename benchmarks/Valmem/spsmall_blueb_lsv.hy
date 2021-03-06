--tptp

var
s,
x_q_0,
x_net27,
x_wela,
x_net13a,
x_net45,
x_d_int,
x_en_latchd,
x_en_latchwen,
x_wen_h,
x_d_h		:clock;

qD,qW,qwa,qQ		: discrete;

d_up_q_0,d_dn_q_0,
d_up_net27,d_dn_net27,
d_up_d_inta,d_dn_d_inta,
d_up_wela,d_dn_wela,
d_up_net45a,d_dn_net45a,
d_up_net13a,d_dn_net13a,
d_up_net45,d_dn_net45,
d_up_d_int,d_dn_d_int,
d_up_en_latchd,d_dn_en_latchd,
d_up_en_latchwen,d_dn_en_latchwen,
d_up_wen_h,d_dn_wen_h,
d_up_d_h,d_dn_d_h,

tHI, tLO, tsetupd, tsetupwen		:parameter;



automaton abs_net27	-- ######### ABSTRACTION MANUELLE DE net27 #########
	    		-- ######### et incorporation de retard_q0 #########
			-- ######### ce qui supprime l'autom. ret_q_0 ######
synclabs: down_wela, up_wela,
	    down_d_inta, up_d_inta,
 	    down_net27, up_net27;
initially init_abs_net27;

loc  init_abs_net27 : while True wait {}
	 when True sync up_d_inta goto A_abs_net27;
 	 when True sync down_wela goto C_abs_net27;
 	 when True sync up_wela goto init_abs_net27;
 	 when True sync down_d_inta goto init_abs_net27;

loc  A_abs_net27 : while True wait {}
	 when True sync down_wela do {x_net27'=0} goto B_abs_net27;
	 when True sync up_wela goto A_abs_net27;
 	 when True sync up_d_inta goto A_abs_net27;
	 when True sync down_d_inta goto C_abs_net27;

loc  B_abs_net27 : while x_net27 <= d_up_net27 + d_up_q_0 wait {}
	 when True sync down_wela  goto B_abs_net27;
	 when True sync up_wela goto C_abs_net27;
 	 when True sync up_d_inta goto C_abs_net27;
	 when True sync down_d_inta goto B_abs_net27;
	 when x_net27 = d_up_net27+ d_up_q_0 --sync up_net27
	      	      do {qQ' = s} goto C_abs_net27;

loc  C_abs_net27 : while True wait{}
       when True sync down_wela goto C_abs_net27;
       when True sync up_wela goto C_abs_net27;     
       when True sync down_d_inta goto C_abs_net27;     
       when True sync up_d_inta goto C_abs_net27;

end -- not_net27

automaton f2_wela		-- wela <= net45a or net13a
synclabs: up_net45a, down_net45a,
      up_net13a, down_net13a,
      up_wela, down_wela;


initially e_01_1_wela;

loc  e_00_0_wela : while True wait {}
	 when True sync up_net45a  do {x_wela'=0} goto e_01_X_wela;
	 when True sync up_net13a  do {x_wela'=0} goto e_10_X_wela;
	 when True sync down_net45a  do {} goto e_00_0_wela;
	 when True sync down_net13a  do {} goto e_00_0_wela;
loc  e_01_1_wela : while True wait {}
	 when True sync down_net45a  do {x_wela'=0} goto e_00_X_wela;
	 when True sync up_net13a  do {x_wela'=0} goto e_11_X_wela;
	 when True sync up_net45a  do {} goto e_01_1_wela;
	 when True sync down_net13a  do {} goto e_01_1_wela;
loc  e_10_1_wela : while True wait {}
	 when True sync up_net45a  do {x_wela'=0} goto e_11_X_wela;
	 when True sync down_net13a  do {x_wela'=0} goto e_00_X_wela;
	 when True sync down_net45a  do {} goto e_10_1_wela;
	 when True sync up_net13a  do {} goto e_10_1_wela;
loc  e_11_1_wela : while True wait {}
	 when True sync down_net45a  do {x_wela'=0} goto e_10_X_wela;
	 when True sync down_net13a  do {x_wela'=0} goto e_01_X_wela;
	 when True sync up_net45a  do {} goto e_11_1_wela;
	 when True sync up_net13a  do {} goto e_11_1_wela;
loc  e_00_X_wela: while x_wela <= d_dn_wela wait {}
	 when True sync up_net45a do {x_wela'=0} goto e_01_X_wela;
	 when True sync up_net13a do {x_wela'=0} goto e_10_X_wela;
	 when True sync down_net45a do {} goto e_00_X_wela;
	 when True sync down_net13a do {} goto e_00_X_wela;
	 when x_wela = d_dn_wela sync down_wela 
	      	       do {qwa'=s} goto e_00_0_wela;
loc  e_01_X_wela: while x_wela <= d_up_wela wait {}
	 when True sync down_net45a do {x_wela'=0} goto e_00_X_wela;
	 when True sync up_net13a do {x_wela'=0} goto e_11_X_wela;
	 when True sync up_net45a do {} goto e_01_X_wela;
	 when True sync down_net13a do {} goto e_01_X_wela;
	 when x_wela = d_up_wela sync up_wela 
	      	       do {} goto e_01_1_wela;
loc  e_10_X_wela: while x_wela <= d_up_wela wait {}
	 when True sync up_net45a do {x_wela'=0} goto e_11_X_wela;
	 when True sync down_net13a do {x_wela'=0} goto e_00_X_wela;
	 when True sync down_net45a do {} goto e_10_X_wela;
	 when True sync up_net13a do {} goto e_10_X_wela;
	 when x_wela = d_up_wela sync up_wela 
	      	       do {} goto e_10_1_wela;
loc  e_11_X_wela: while x_wela <= d_up_wela wait {}
	 when True sync down_net45a do {x_wela'=0} goto e_10_X_wela;
	 when True sync down_net13a do {x_wela'=0} goto e_01_X_wela;
	 when True sync up_net45a do {} goto e_11_X_wela;
	 when True sync up_net13a do {} goto e_11_X_wela;
	 when x_wela = d_up_wela sync up_wela 
	      	       do {} goto e_11_1_wela;


	 end -- f2_wela

automaton not_net13a
synclabs: down_ck, up_ck,
 down_net13a, up_net13a;
initially init_not_net13a;

loc  init_not_net13a : while True wait {}
	 when True sync up_ck do {x_net13a'=0} goto A_not_net13a;
	 when True sync down_ck do {x_net13a'=0} goto B_not_net13a;

loc  A_not_net13a : while x_net13a <= d_dn_net13a wait {}
	 when True sync down_ck do {x_net13a'=0} goto B_not_net13a;
	 when x_net13a = d_dn_net13a sync down_net13a goto init_not_net13a;

loc  B_not_net13a : while x_net13a <= d_up_net13a wait {}
	 when True sync up_ck do {x_net13a'=0} goto A_not_net13a;
	 when x_net13a = d_up_net13a sync up_net13a goto init_not_net13a;

end -- not_net13a


--###########################################################################"
--#### INCORPORATION delai net45a
--#### entraine la suppression de l'automate retard_net45a
automaton reg_net45
synclabs: down_wen_h, up_wen_h,			-- inputs  (data)
	  down_en_latchwen, up_en_latchwen,	-- inputs (enable)
	  down_net45a, up_net45a ;		-- outputs
initially e0d1_U_reg_net45;

loc e0d0_U_reg_net45: while True wait {}
   		     	when True sync down_en_latchwen do {} goto e0d0_U_reg_net45;
  		     	when True sync down_wen_h do {} goto e0d0_U_reg_net45;
			when True sync up_en_latchwen do {x_net45'=0} goto e1d0_X_reg_net45;
			when True sync up_wen_h do {} goto e0d1_U_reg_net45;

loc e1d0_X_reg_net45: while x_net45 <= d_dn_net45 + d_dn_net45a wait {}
   		     	when True sync down_wen_h do {} goto e1d0_X_reg_net45;
			when True sync up_en_latchwen do {} goto e1d0_X_reg_net45;
			when True sync down_en_latchwen do {} goto e0d0_U_reg_net45;
			when True sync up_wen_h do {x_net45'=0} goto e1d1_X_reg_net45;
			when x_net45 = d_dn_net45 + d_dn_net45a sync down_net45a do {qW'=1} goto e1d0_0_reg_net45;

loc e1d0_0_reg_net45: while True wait {}
    		     	when True sync down_wen_h do {} goto e1d0_0_reg_net45;
			when True sync down_en_latchwen do {} goto e0d0_U_reg_net45;
			when True sync up_en_latchwen do {} goto e1d0_0_reg_net45;
			when True sync up_wen_h do {x_net45'=0} goto e1d1_X_reg_net45;

loc e0d1_U_reg_net45: while True wait {}
    		     	when True sync up_wen_h do {} goto e0d1_U_reg_net45;
			when True sync down_en_latchwen do {} goto e0d1_U_reg_net45;
			when True sync up_en_latchwen do {x_net45'=0} goto e1d1_X_reg_net45;
			when True sync down_wen_h do {} goto e0d0_U_reg_net45;

loc e1d1_X_reg_net45: while x_net45 <= d_up_net45 + d_up_net45a wait {}
			when True sync down_en_latchwen do {} goto e0d1_U_reg_net45;
			when True sync up_wen_h do {} goto e1d1_X_reg_net45;
			when True sync up_en_latchwen do {} goto e1d1_X_reg_net45;
			when True sync down_wen_h do {x_net45'=0} goto e1d0_X_reg_net45;
			when x_net45 = d_up_net45 + d_up_net45a sync up_net45a goto e1d1_1_reg_net45;

loc e1d1_1_reg_net45: while True wait {}
			when True sync down_en_latchwen do {} goto e0d1_U_reg_net45;
			when True sync up_en_latchwen do {} goto e1d1_1_reg_net45;
			when True sync down_wen_h do {x_net45'=0} goto e1d0_X_reg_net45;
			when True sync up_wen_h do {} goto e1d1_1_reg_net45;
 end -- reg_net45

--###########################################################################"
--#### INCORPORATION delai d_inta
--#### entraine la suppression de l'automate retard_d_inta
automaton reg_d_int
synclabs: down_d_h, up_d_h,			-- inputs  (data)
	  down_en_latchd, up_en_latchd,		-- inputs (enable)
	  down_d_inta, up_d_inta ;		-- outputs
initially e0d0_U_reg_d_int;

loc e0d0_U_reg_d_int: while True wait {}
    		     	when True sync down_en_latchd do {} goto e0d0_U_reg_d_int;
   		     	when True sync down_d_h do {} goto e0d0_U_reg_d_int;
			when True sync up_en_latchd do {x_d_int'=0} goto e1d0_X_reg_d_int;
			when True sync up_d_h do {} goto e0d1_U_reg_d_int;

loc e1d0_X_reg_d_int: while x_d_int <= d_dn_d_int + d_dn_d_inta wait {}
    		     	when True sync down_d_h do {} goto e1d0_X_reg_d_int;
			when True sync up_en_latchd do {} goto e1d0_X_reg_d_int;
			when True sync down_en_latchd do {} goto e0d0_U_reg_d_int;
			when True sync up_d_h do {x_d_int'=0} goto e1d1_X_reg_d_int;
			when x_d_int = d_dn_d_int + d_dn_d_inta sync down_d_inta goto e1d0_0_reg_d_int;

loc e1d0_0_reg_d_int: while True wait {}
    		     	when True sync down_d_h do {} goto e1d0_0_reg_d_int;
			when True sync down_en_latchd do {} goto e0d0_U_reg_d_int;
			when True sync up_en_latchd do {} goto e1d0_0_reg_d_int;
			when True sync up_d_h do {x_d_int'=0} goto e1d1_X_reg_d_int;

loc e0d1_U_reg_d_int: while True wait {}
    		     	when True sync up_d_h do {} goto e0d1_U_reg_d_int;
			when True sync down_en_latchd do {} goto e0d1_U_reg_d_int;
			when True sync up_en_latchd do {x_d_int'=0} goto e1d1_X_reg_d_int;
			when True sync down_d_h do {} goto e0d0_U_reg_d_int;

loc e1d1_X_reg_d_int: while x_d_int <= d_up_d_int + d_up_d_inta wait {}
			when True sync down_en_latchd do {} goto e0d1_U_reg_d_int;
			when True sync up_d_h do {} goto e1d1_X_reg_d_int;
			when True sync up_en_latchd do {} goto e1d1_X_reg_d_int;
			when True sync down_d_h do {x_d_int'=0} goto e1d0_X_reg_d_int;
			when x_d_int = d_up_d_int + d_up_d_inta sync up_d_inta do {qD' = 1} goto e1d1_1_reg_d_int;

loc e1d1_1_reg_d_int: while True wait {}
			when True sync down_en_latchd do {} goto e0d1_U_reg_d_int;
			when True sync up_en_latchd do {} goto e1d1_1_reg_d_int;
			when True sync down_d_h do {x_d_int'=0} goto e1d0_X_reg_d_int;
			when True sync up_d_h do {} goto e1d1_1_reg_d_int;
 end -- reg_d_int


automaton not_en_latchd
synclabs: down_ck, up_ck,
 down_en_latchd, up_en_latchd;
initially init_not_en_latchd;

loc  init_not_en_latchd : while True wait {}
	 when True sync up_ck do {x_en_latchd'=0} goto A_not_en_latchd;
	 when True sync down_ck do {x_en_latchd'=0} goto B_not_en_latchd;

loc  A_not_en_latchd : while x_en_latchd <= d_dn_en_latchd wait {}
	 when True sync down_ck do {x_en_latchd'=0} goto B_not_en_latchd;
	 when x_en_latchd = d_dn_en_latchd sync down_en_latchd goto init_not_en_latchd;

loc  B_not_en_latchd : while x_en_latchd <= d_up_en_latchd wait {}
	 when True sync up_ck do {x_en_latchd'=0} goto A_not_en_latchd;
	 when x_en_latchd = d_up_en_latchd sync up_en_latchd goto init_not_en_latchd;

end -- not_en_latchd



automaton not_en_latchwen
synclabs: down_ck, up_ck,
 down_en_latchwen, up_en_latchwen;
initially init_not_en_latchwen;

loc  init_not_en_latchwen : while True wait {}
	 when True sync up_ck do {x_en_latchwen'=0} goto A_not_en_latchwen;
	 when True sync down_ck do {x_en_latchwen'=0} goto B_not_en_latchwen;

loc  A_not_en_latchwen : while x_en_latchwen <= d_dn_en_latchwen wait {}
	 when True sync down_ck do {x_en_latchwen'=0} goto B_not_en_latchwen;
	 when x_en_latchwen = d_dn_en_latchwen sync down_en_latchwen goto init_not_en_latchwen;

loc  B_not_en_latchwen : while x_en_latchwen <= d_up_en_latchwen wait {}
	 when True sync up_ck do {x_en_latchwen'=0} goto A_not_en_latchwen;
	 when x_en_latchwen = d_up_en_latchwen sync up_en_latchwen goto init_not_en_latchwen;

end -- not_en_latchwen


automaton retard_wen_h
synclabs: down_wen, up_wen,
 down_wen_h, up_wen_h;
initially init_ret_wen_h;

loc  init_ret_wen_h : while True wait {}
	 when True sync up_wen do {x_wen_h'=0} goto A_ret_wen_h;
	 when True sync down_wen do {x_wen_h'=0} goto B_ret_wen_h;

loc  A_ret_wen_h : while x_wen_h <= d_up_wen_h wait {}
	 when True sync down_wen do {x_wen_h'=0} goto B_ret_wen_h;
	 when x_wen_h = d_up_wen_h sync up_wen_h goto init_ret_wen_h;

loc  B_ret_wen_h : while x_wen_h <= d_dn_wen_h wait {}
	 when True sync up_wen do {x_wen_h'=0} goto A_ret_wen_h;
	 when x_wen_h = d_dn_wen_h sync down_wen_h goto init_ret_wen_h;

end -- not_wen_h



automaton retard_d_h
synclabs: down_d_0, up_d_0,
 down_d_h, up_d_h;


initially init_ret_d_h;

loc  init_ret_d_h : while True wait {}
	 when True sync up_d_0 do {x_d_h'=0} goto A_ret_d_h;
	 when True sync down_d_0 do {x_d_h'=0} goto B_ret_d_h;

loc  A_ret_d_h : while x_d_h <= d_up_d_h wait {}
	 when True sync down_d_0 do {x_d_h'=0} goto B_ret_d_h;
	 when x_d_h = d_up_d_h sync up_d_h goto init_ret_d_h;

loc  B_ret_d_h : while x_d_h <= d_dn_d_h wait {}
	 when True sync up_d_0 do {x_d_h'=0} goto A_ret_d_h;
	 when x_d_h = d_dn_d_h sync down_d_h goto init_ret_d_h;

end -- not_d_h

automaton env
synclabs: up_d_0, down_d_0, up_wen, down_wen,
	  down_ck, up_ck;
initially init_env;

loc  init_env : while s <= tHI + tLO - tsetupd wait {}
	 when s = tHI + tLO - tsetupd sync up_d_0 goto env1;

loc  env1 : while s <= tHI  wait {}
	 when s = tHI  sync down_ck goto env2;

loc  env2 : while s <= tHI + tLO - tsetupwen wait {}
	 when s = tHI + tLO - tsetupwen sync down_wen goto env3;

loc  env3 : while s <= tHI + tLO wait {}
	 when s = tHI + tLO sync up_ck goto env4;

loc  env4 : while s <= 2 tHI + tLO wait {}
	 when s = 2 tHI + tLO sync down_ck goto env5;

loc  env5 : while s <= 2 tHI + 2 tLO wait {}
	 when s = 2 tHI + 2 tLO sync up_ck goto env6;

loc env6 : while True wait{}
--     	 when True goto env6;


end -- not_d_h


-- analysis commands

var
init_reg, post_reg, bad_reg, inter_reg, final_reg
	: region;

init_reg := 
	loc[env] = init_env

 	& loc[abs_net27] = init_abs_net27 
	& loc[f2_wela]= e_01_1_wela		
	& loc[not_net13a] = init_not_net13a
	& loc[reg_net45] = e0d1_U_reg_net45
	& loc[reg_d_int] = e0d0_U_reg_d_int
	& loc[not_en_latchd] = init_not_en_latchd 
	& loc[not_en_latchwen] = init_not_en_latchwen
	& loc[retard_wen_h] = init_ret_wen_h
	& loc[retard_d_h] = init_ret_d_h


	& s = 0

	& qD = 0
	& qW = 0
	& qwa = 0
	& qQ = 0

	& x_q_0 = 0 
	& x_wela = 0 
	& x_net13a = 0
	& x_net45 = 0
	& x_d_int = 0
	& x_en_latchd = 0
	& x_en_latchwen = 0
	& x_wen_h = 0
	& x_d_h	 = 0

-- delais pour SP1 (cf. wseas06, Fig.5)

	& d_up_q_0 = 21		& d_dn_q_0 = 20		-- delai_27
	& d_up_net27 = 0	& d_dn_net27 = 0	-- delai_24
	& d_up_d_inta = 22	& d_dn_d_inta = 45	-- delai_18 
	& d_up_wela = 0		& d_dn_wela = 0 + 22	-- delai_9 + delai_13
	& d_up_net45a = 5	& d_dn_net45a = 4	-- delai_28
	& d_up_net13a = 5 + 14	& d_dn_net13a = 2 + 11	-- delai_4 + delai_7
	& d_up_net45 = 21	& d_dn_net45 = 22	-- delai_6
	& d_up_d_int = 14	& d_dn_d_int = 18	-- delai_15
	& d_up_en_latchd = 5 + 23 & d_dn_en_latchd = 2 + 30 -- delai_4 + delai_16
	& d_up_en_latchwen = 5 & d_dn_en_latchwen = 4   -- delai_3 
	& d_up_wen_h = 11	& d_dn_wen_h = 8	-- delai_2
	& d_up_d_h = 95  	& d_dn_d_h = 66		-- delai_1

		
	& tHI = 45 & tLO = 65 --& tsetupd = 108 & tsetupwen = 48
;

prints "****************** INITIAL REG ******************";

print init_reg;

prints "****************** POST* ******************";

post_reg := reach forward from init_reg endreach;

print (hide
s,
	x_q_0,  x_d_int, x_en_latchd, x_d_h, x_wen_h, x_net45, 
	x_net13a, x_en_latchwen,
        d_up_q_0,d_dn_q_0, d_up_net27,d_dn_net27,
	d_up_d_inta,d_dn_d_inta,
	d_up_wela,d_dn_wela, d_up_net45a,d_dn_net45a,
	d_up_net13a,d_dn_net13a,
	d_up_net45,d_dn_net45,d_up_d_int,d_dn_d_int,d_up_en_latchd,d_dn_en_latchd,
	d_up_en_latchwen,d_dn_en_latchwen,
	d_up_wen_h,d_dn_wen_h, d_up_d_h,d_dn_d_h,

	tHI, tLO, --, tsetupd, tsetupwen
	
	qD, qW , qwa ,x_wela, x_net27
	
	
       in post_reg endhide);

prints "****************** FINAL ******************";

final_reg := post_reg & loc[env] = env6;

print (hide
s,
	x_q_0,  x_d_int, x_en_latchd, x_d_h, x_wen_h, x_net45, 
	x_net13a, x_en_latchwen,
        d_up_q_0,d_dn_q_0, d_up_net27,d_dn_net27,
	d_up_d_inta,d_dn_d_inta,
	d_up_wela,d_dn_wela, d_up_net45a,d_dn_net45a,
	d_up_net13a,d_dn_net13a,
	d_up_net45,d_dn_net45,d_up_d_int,d_dn_d_int,d_up_en_latchd,d_dn_en_latchd,
	d_up_en_latchwen,d_dn_en_latchwen,
	d_up_wen_h,d_dn_wen_h, d_up_d_h,d_dn_d_h,

	tHI, tLO, --, tsetupd, tsetupwen
	
	qD, qW , qwa ,x_wela, x_net27
	
	
       in final_reg endhide);


prints "****************** BAD ******************";

bad_reg := final_reg & qQ = 0
		;

print (hide
s,
	x_q_0,  x_d_int, x_en_latchd, x_d_h, x_wen_h, x_net45, 
	x_net13a, x_en_latchwen,
        d_up_q_0,d_dn_q_0, d_up_net27,d_dn_net27,
	d_up_d_inta,d_dn_d_inta,
	d_up_wela,d_dn_wela, d_up_net45a,d_dn_net45a,
	d_up_net13a,d_dn_net13a,
	d_up_net45,d_dn_net45,d_up_d_int,d_dn_d_int,d_up_en_latchd,d_dn_en_latchd,
	d_up_en_latchwen,d_dn_en_latchwen,
	d_up_wen_h,d_dn_wen_h, d_up_d_h,d_dn_d_h,

	tHI, tLO, --, tsetupd, tsetupwen
	
	qD, qW , qwa ,x_wela, x_net27
	
	
       in bad_reg endhide);

prints "****************** POST* - BAD ******************";

inter_reg := weakdiff(final_reg, bad_reg);

print (hide
s,
	x_q_0,  x_d_int, x_en_latchd, x_d_h, x_wen_h, x_net45, 
	x_net13a, x_en_latchwen,
        d_up_q_0,d_dn_q_0, d_up_net27,d_dn_net27,
	d_up_d_inta,d_dn_d_inta,
	d_up_wela,d_dn_wela, d_up_net45a,d_dn_net45a,
	d_up_net13a,d_dn_net13a,
	d_up_net45,d_dn_net45,d_up_d_int,d_dn_d_int,d_up_en_latchd,d_dn_en_latchd,
	d_up_en_latchwen,d_dn_en_latchwen,
	d_up_wen_h,d_dn_wen_h, d_up_d_h,d_dn_d_h,

	tHI, tLO, --, tsetupd, tsetupwen
	
	qD, qW , qwa ,x_wela, x_net27
	
	
       in inter_reg endhide);
