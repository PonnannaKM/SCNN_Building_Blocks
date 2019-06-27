--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: sng_36
-- Module Name: sng_36 - Behavioural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This module is a component of the top module 
--				This module generates 4 stochstatic numbers of '2**sn_precision_g' length.
--				
-- Dependencies: 
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-------------------------------------------------------------------------------------------------------------------
library IEEE;
library synopsys; -- for synthesis
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use synopsys.attributes.all; -- for synthesis
use work.sc_dnn_pkg.all;

entity sng_4 is
	generic(bn_precision_g : positive;-- := 9; -- binary precision paramater
			sn_precision_g : positive;-- := 9; -- stochstatic number precsion parameter = binary precision
		    lfsr_depth_12_g : positive-- := 12 -- width of LFSR and state S (or) number of random numbers produced by this module
			);
			
	port(clk_i : in std_logic;
		 start_i : in std_logic;
		 reset_i : in std_logic;
		 bin_num_i : in sng_4_in; -- array of 7 inputs. Each of 'bn_precision_g' bits wide
		 sc_num_o : out std_logic_vector(1 to 4); -- array of 4 ouputs. Each of 1bit wide
		 sc_num_valid_o : out std_logic -- valid ouput indication (or) handshake signal for later stages
		 );
		 
end sng_4;



architecture behavioural of sng_4 is
	attribute sync_set_reset of reset_i : signal is "true"; -- attribute to guide the synthesizer to use Xilinx device specific reset pin of FDRE
	 
	signal lfsr1_4_s : std_logic_vector(lfsr_depth_12_g-9 downto 0):= x"A"; -- LFSR of SBoNG (4bit LFSR with random initialization). One LUT ca be used as 2 16bit shift registers
	signal lfsr2_4_s : std_logic_vector(lfsr_depth_12_g-9 downto 0):= x"C";
	signal lfsr3_4_s : std_logic_vector(lfsr_depth_12_g-9 downto 0):= x"7";
	signal lfsr_12_out_s : std_logic_vector(lfsr_depth_12_g-1 downto 0); -- combined ouput of two 4bit LSFR and a 3bit LFSR
	signal state_s_s : std_logic_vector(lfsr_depth_12_g-1 downto 0); -- state S register of SBoNG
	signal xor_lfsr_state_s_s : std_logic_vector(lfsr_depth_12_g-1 downto 0); -- xor of LFSR and S state contents
	signal sbox_out_s : std_logic_vector(lfsr_depth_12_g-1 downto 0); -- output from S-Boxes
	signal sbox_out_1r_s : std_logic_vector(lfsr_depth_12_g-1 downto 0); -- output after 1 bit rotation of S-Boxe's output
	type sbong_out_type is array(1 to 4) of std_logic_vector(lfsr_depth_12_g-1 downto 0);  --define array of 4 signals. Each of 12bit wide
	signal sbong_out_s : sbong_out_type; -- 4 output after rotation by 1 bit
	signal one_delay_s : std_logic; -- register for one delay element
	signal one_delay_in_s : std_logic; -- packing inputs for one delay element(ouputs from comparator)
	signal two_delay_in_s : std_logic; -- packing inputs for two delay element(ouputs from comparator)
	signal sc_num_s : std_logic_vector(1 to 4); -- ouput of comparator
	signal two_delay1_s : std_logic; -- register for two delay element
	signal two_delay2_s : std_logic; -- register for two delay element
	signal we_s : std_logic; -- write enable for LFSR and state S driven by external start command
	
	begin
	
			we_s <= start_i;
			-------
			-- LFSR
			-------
			lfsr12_unit : process(clk_i)
								begin
									if(rising_edge(clk_i))then
										if(we_s = '1')then
											for i in 0 to lfsr_depth_12_g-10 loop
												lfsr1_4_s(i) <= lfsr1_4_s(i+1);
											end loop;
											lfsr1_4_s(lfsr_depth_12_g-9) <= lfsr1_4_s(0) xor lfsr2_4_s(0);
											for i in 0 to lfsr_depth_12_g-10 loop
												lfsr2_4_s(i) <= lfsr2_4_s(i+1);
											end loop;
											lfsr2_4_s(lfsr_depth_12_g-9) <= lfsr1_4_s(0) xor lfsr3_4_s(0);
											for i in 0 to lfsr_depth_12_g-10 loop
												lfsr3_4_s(i) <= lfsr3_4_s(i+1);
											end loop;
											lfsr3_4_s(lfsr_depth_12_g-9) <= lfsr1_4_s(0);						
										end if;
									end if;
						  end process lfsr12_unit;
						  lfsr_12_out_s(lfsr_depth_12_g-1 downto 0) <=  lfsr3_4_s(lfsr_depth_12_g-9 downto 0) & lfsr2_4_s(lfsr_depth_12_g-9 downto 0) & lfsr1_4_s(lfsr_depth_12_g-9 downto 0);


			----------			  
			-- state S
			----------
			state_s_unit : process(clk_i)
								begin
									if(rising_edge(clk_i))then
										if(reset_i = '1')then
											state_s_s <= (others => '0');
										else
											if(we_s = '1')then
												state_s_s <= lfsr_12_out_s xor sbox_out_1r_s;
											end if;
										end if;
									end if;
							end process state_s_unit;
							xor_lfsr_state_s_s <= state_s_s(lfsr_depth_12_g-1 downto 0) xor lfsr_12_out_s(lfsr_depth_12_g-1 downto 0);
			----------
			-- S-Boxes	
			----------
			sbox_unit : process(xor_lfsr_state_s_s)
								begin
									case xor_lfsr_state_s_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) is
										when x"0" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_12_g-1 downto lfsr_depth_12_g-4) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) is
										when x"0" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_12_g-5 downto lfsr_depth_12_g-8) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) is
										when x"0" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_12_g-9 downto lfsr_depth_12_g-12) <= x"0";
									end case;	
								
						end process sbox_unit;
			-----------------			
			-- 1 bit rotation
			-----------------
			sbox_out_1r_s(lfsr_depth_12_g-1 downto 0) <= sbox_out_s(0) & sbox_out_s(lfsr_depth_12_g-1 downto 1);
			
			---------------------			
			-- rotation by 1 bits
			---------------------
			rn_unit : process(sbox_out_1r_s)
							begin
								sbong_out_s(1) <= sbox_out_1r_s(lfsr_depth_12_g-1 downto 0);
								sbong_out_s(2) <= sbox_out_1r_s(0) & sbox_out_1r_s(lfsr_depth_12_g-1 downto 1);
								sbong_out_s(3) <= sbox_out_1r_s(1 downto 0) & sbox_out_1r_s(lfsr_depth_12_g-1 downto 2);		
								sbong_out_s(4) <= sbox_out_1r_s(2 downto 0) & sbox_out_1r_s(lfsr_depth_12_g-1 downto 3);				
								
					  end process rn_unit;
			--------------
			-- comparators
			--------------
			sc_num_s(1) <= '1' when sbong_out_s(1)(bn_precision_g-1 downto 0)	< bin_num_i(1) else
						   '0';
			sc_num_s(2) <= '1' when sbong_out_s(2)(bn_precision_g-1 downto 0)	< bin_num_i(2) else
						   '0';						   
			sc_num_s(3) <= '1' when sbong_out_s(3)(bn_precision_g-1 downto 0)	< bin_num_i(3) else
						   '0';
			sc_num_s(4) <= '1' when sbong_out_s(4)(bn_precision_g-1 downto 0)	< bin_num_i(4) else
						   '0';									
								

			---------------------------------------------
			-- pack inputs for one and two delay elements
			---------------------------------------------
			one_delay_in_s <= sc_num_s(2);
					
			two_delay_in_s  <= sc_num_s(3);
			--------------------											
			-- one delay element
			--------------------
			one_delay_unit : process(clk_i)
								begin
									if(rising_edge(clk_i))then
										if(reset_i = '1')then
											one_delay_s <= '0';
										else
											if(we_s = '1')then
												one_delay_s <= one_delay_in_s;
											end if;
										end if;
									end if;
							end process one_delay_unit;
			--------------------
			-- two delay element
			--------------------
			two_delay_unit : process(clk_i)
								begin
									if(rising_edge(clk_i))then
										if(reset_i = '1')then
											two_delay1_s <= '0';
											two_delay2_s <= '0';
										else
											if(we_s = '1')then
												two_delay1_s <= two_delay_in_s;
												two_delay2_s <= two_delay1_s;
											end if;
										end if;
									end if;
							end process two_delay_unit;
			--------------										
			-- ouput valid
			--------------
			sc_valid_bit_unit : process(clk_i)
									begin
										if(rising_edge(clk_i))then
											if(reset_i = '1')then
												sc_num_valid_o <= '0';
											else
												sc_num_valid_o <= we_s;
											end if;
										end if;
								end process sc_valid_bit_unit;
			-------------------------------
			-- 36 stochastic number outputs
			-------------------------------
			sc_num_o(1) <= sc_num_s(1);
			sc_num_o(2) <= one_delay_s;
			sc_num_o(3) <= two_delay2_s;
			sc_num_o(4) <= sc_num_s(4);

			
end behavioural;								