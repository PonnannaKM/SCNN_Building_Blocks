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
--				This module generates 36 stochstatic numbers of '2**sn_precision_g' length.
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

entity sng_36 is
	generic(bn_precision_g : positive;-- := 9; -- binary precision paramater
			sn_precision_g : positive;-- := 9; -- stochstatic number precsion parameter = binary precision
		    lfsr_depth_36_g : positive-- := 36 -- width of LFSR and state S (or) number of random numbers produced by this module
			);
			
	port(clk_i : in std_logic;
		 start_i : in std_logic;
		 reset_i : in std_logic;
		 bin_num_i : in sng_36_in; -- array of 36 inputs. Each of 'bn_precision_g' bits wide
		 sc_num_o : out std_logic_vector(1 to 36); -- array of 36 ouputs. Each of 1bit wide
		 sc_num_valid_o : out std_logic -- valid ouput indication (or) handshake signal for later stages
		 );
		 
end sng_36;



architecture behavioural of sng_36 is
	attribute sync_set_reset of reset_i : signal is "true"; -- attribute to guide the synthesizer to use Xilinx device specific reset pin of FDRE
	 
	signal lfsr1_16_s : std_logic_vector(lfsr_depth_36_g-21 downto 0):= x"A049"; -- LFSR of SBoNG (16bit LFSR with random initialization). One LUT ca be used as 2 16bit shift registers
	signal lfsr2_16_s : std_logic_vector(lfsr_depth_36_g-21 downto 0):= x"C12D";
	signal lfsr3_16_s : std_logic_vector(lfsr_depth_36_g-21 downto 0):= x"7768";
	signal lfsr_36_out_s : std_logic_vector(lfsr_depth_36_g-1 downto 0); -- combined ouput of two 16bit LSFR and a 4bit LFSR
	signal state_s_s : std_logic_vector(lfsr_depth_36_g-1 downto 0); -- state S register of SBoNG
	signal xor_lfsr_state_s_s : std_logic_vector(lfsr_depth_36_g-1 downto 0); -- xor of LFSR and S state contents
	signal sbox_out_s : std_logic_vector(lfsr_depth_36_g-1 downto 0); -- output from S-Boxes
	signal sbox_out_1r_s : std_logic_vector(lfsr_depth_36_g-1 downto 0); -- output after 1 bit rotation of S-Boxe's output
	type sbong_out_type is array(1 to lfsr_depth_36_g) of std_logic_vector(lfsr_depth_36_g-1 downto 0);  --define array of 36 signals. Each of 36bit wide
	signal sbong_out_s : sbong_out_type; -- 36 output after rotation by 1 bit
	signal one_delay_s : std_logic_vector(11 downto 0); -- register for one delay element
	signal one_delay_in_s : std_logic_vector(11 downto 0); -- packing inputs for one delay element(ouputs from comparator)
	signal two_delay_in_s : std_logic_vector(11 downto 0); -- packing inputs for two delay element(ouputs from comparator)
	signal sc_num_s : std_logic_vector(1 to 36); -- ouput of comparator
	signal two_delay1_s : std_logic_vector(11 downto 0); -- register for two delay element
	signal two_delay2_s : std_logic_vector(11 downto 0); -- register for two delay element
	signal we_s : std_logic; -- write enable for LFSR and state S driven by external start command
	
	begin
	
			we_s <= start_i;
			-------
			-- LFSR
			-------
			lfsr36_unit : process(clk_i)
								begin
									if(rising_edge(clk_i))then
										if(we_s = '1')then
											for i in 0 to lfsr_depth_36_g-22 loop
												lfsr1_16_s(i) <= lfsr1_16_s(i+1);
											end loop;
											lfsr1_16_s(lfsr_depth_36_g-21) <= lfsr1_16_s(0) xor lfsr2_16_s(0);
											for i in 0 to lfsr_depth_36_g-22 loop
												lfsr2_16_s(i) <= lfsr2_16_s(i+1);
											end loop;
											lfsr2_16_s(lfsr_depth_36_g-21) <= lfsr1_16_s(0) xor lfsr3_16_s(0);
											for i in 0 to lfsr_depth_36_g-34 loop
												lfsr3_16_s(i) <= lfsr3_16_s(i+1);
											end loop;
											lfsr3_16_s(lfsr_depth_36_g-33) <= lfsr1_16_s(0);						
										end if;
									end if;
						  end process lfsr36_unit;
						  lfsr_36_out_s(lfsr_depth_36_g-1 downto 0) <=  lfsr3_16_s(lfsr_depth_36_g-33 downto 0) & lfsr2_16_s(lfsr_depth_36_g-21 downto 0) & lfsr1_16_s(lfsr_depth_36_g-21 downto 0);


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
												state_s_s <= lfsr_36_out_s xor sbox_out_1r_s;
											end if;
										end if;
									end if;
							end process state_s_unit;
							xor_lfsr_state_s_s <= state_s_s(lfsr_depth_36_g-1 downto 0) xor lfsr_36_out_s(lfsr_depth_36_g-1 downto 0);
			----------
			-- S-Boxes	
			----------
			sbox_unit : process(xor_lfsr_state_s_s)
								begin
									case xor_lfsr_state_s_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-1 downto lfsr_depth_36_g-4) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-5 downto lfsr_depth_36_g-8) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-9 downto lfsr_depth_36_g-12) <= x"0";
									end case;	
									
									case xor_lfsr_state_s_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-13 downto lfsr_depth_36_g-16) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-17 downto lfsr_depth_36_g-20) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-21 downto lfsr_depth_36_g-24) <= x"0";
									end case;

									case xor_lfsr_state_s_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-25 downto lfsr_depth_36_g-28) <= x"0";
									end case;
									
									case xor_lfsr_state_s_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-29 downto lfsr_depth_36_g-32) <= x"0";
									end case;	

									case xor_lfsr_state_s_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) is
										when x"0" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"6";
										when x"1" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"B";
										when x"2" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"5";
										when x"3" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"4";
										when x"4" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"2";
										when x"5" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"E";
										when x"6" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"7";
										when x"7" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"A";
										when x"8" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"9";
										when x"9" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"D";
										when x"A" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"F";
										when x"B" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"C";
										when x"C" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"3";
										when x"D" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"1";
										when x"E" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"0";	
										when x"F" =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"8";
										when others =>
											sbox_out_s(lfsr_depth_36_g-33 downto lfsr_depth_36_g-36) <= x"0";
									end case;
						end process sbox_unit;
			-----------------			
			-- 1 bit rotation
			-----------------
			sbox_out_1r_s(lfsr_depth_36_g-1 downto 0) <= sbox_out_s(0) & sbox_out_s(lfsr_depth_36_g-1 downto 1);
			
			---------------------			
			-- rotation by 1 bits
			---------------------
			rn_unit : process(sbox_out_1r_s)
							begin
								sbong_out_s(1) <= sbox_out_1r_s(lfsr_depth_36_g-1 downto 0);
								sbong_out_s(2) <= sbox_out_1r_s(0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 1);
								sbong_out_s(3) <= sbox_out_1r_s(1 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 2);		
								sbong_out_s(4) <= sbox_out_1r_s(2 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 3);			
								sbong_out_s(5) <= sbox_out_1r_s(3 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 4);	
								sbong_out_s(6) <= sbox_out_1r_s(4 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 5);	
								sbong_out_s(7) <= sbox_out_1r_s(5 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 6);	
								sbong_out_s(8) <= sbox_out_1r_s(6 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 7);	
								sbong_out_s(9) <= sbox_out_1r_s(7 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 8);	
								sbong_out_s(10) <= sbox_out_1r_s(8 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 9);	
								sbong_out_s(11) <= sbox_out_1r_s(9 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 10);									
								sbong_out_s(12) <= sbox_out_1r_s(10 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 11);	
								sbong_out_s(13) <= sbox_out_1r_s(11 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 12);	
								sbong_out_s(14) <= sbox_out_1r_s(12 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 13);	
								sbong_out_s(15) <= sbox_out_1r_s(13 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 14);	
								sbong_out_s(16) <= sbox_out_1r_s(14 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 15);	
								sbong_out_s(17) <= sbox_out_1r_s(15 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 16);	
								sbong_out_s(18) <= sbox_out_1r_s(16 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 17);	
								sbong_out_s(19) <= sbox_out_1r_s(17 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 18);	
								sbong_out_s(20) <= sbox_out_1r_s(18 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 19);	
								sbong_out_s(21) <= sbox_out_1r_s(19 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 20);	
								sbong_out_s(22) <= sbox_out_1r_s(20 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 21);	
								sbong_out_s(23) <= sbox_out_1r_s(21 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 22);	
								sbong_out_s(24) <= sbox_out_1r_s(22 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 23);	
								sbong_out_s(25) <= sbox_out_1r_s(23 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 24);	
								sbong_out_s(26) <= sbox_out_1r_s(24 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 25);	
								sbong_out_s(27) <= sbox_out_1r_s(25 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 26);	
								sbong_out_s(28) <= sbox_out_1r_s(26 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 27);	
								sbong_out_s(29) <= sbox_out_1r_s(27 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 28);	
								sbong_out_s(30) <= sbox_out_1r_s(28 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 29);	
								sbong_out_s(31) <= sbox_out_1r_s(29 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 30);	
								sbong_out_s(32) <= sbox_out_1r_s(30 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 31);	
								sbong_out_s(33) <= sbox_out_1r_s(31 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 32);	
								sbong_out_s(34) <= sbox_out_1r_s(32 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 33);	
								sbong_out_s(35) <= sbox_out_1r_s(33 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 34);	
								sbong_out_s(36) <= sbox_out_1r_s(34 downto 0) & sbox_out_1r_s(lfsr_depth_36_g-1 downto 35);	
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
			sc_num_s(5) <= '1' when sbong_out_s(5)(bn_precision_g-1 downto 0)	< bin_num_i(5) else
						   '0';
			sc_num_s(6) <= '1' when sbong_out_s(6)(bn_precision_g-1 downto 0)	< bin_num_i(6) else
						   '0';						   
			sc_num_s(7) <= '1' when sbong_out_s(7)(bn_precision_g-1 downto 0)	< bin_num_i(7) else
						   '0';
			sc_num_s(8) <= '1' when sbong_out_s(8)(bn_precision_g-1 downto 0)	< bin_num_i(8) else
						   '0';	
			sc_num_s(9) <= '1' when sbong_out_s(9)(bn_precision_g-1 downto 0)	< bin_num_i(9) else
						   '0';
			sc_num_s(10) <= '1' when sbong_out_s(10)(bn_precision_g-1 downto 0)	< bin_num_i(10) else
						    '0';						   
			sc_num_s(11) <= '1' when sbong_out_s(11)(bn_precision_g-1 downto 0)	< bin_num_i(11) else
						    '0';
			sc_num_s(12) <= '1' when sbong_out_s(12)(bn_precision_g-1 downto 0)	< bin_num_i(12) else
						    '0';									
			sc_num_s(13) <= '1' when sbong_out_s(13)(bn_precision_g-1 downto 0)	< bin_num_i(13) else
						    '0';
			sc_num_s(14) <= '1' when sbong_out_s(14)(bn_precision_g-1 downto 0)	< bin_num_i(14) else
						    '0';						   
			sc_num_s(15) <= '1' when sbong_out_s(15)(bn_precision_g-1 downto 0)	< bin_num_i(15) else
						    '0';
			sc_num_s(16) <= '1' when sbong_out_s(16)(bn_precision_g-1 downto 0)	< bin_num_i(16) else
						    '0';		
			sc_num_s(17) <= '1' when sbong_out_s(17)(bn_precision_g-1 downto 0)	< bin_num_i(17) else
						    '0';
			sc_num_s(18) <= '1' when sbong_out_s(18)(bn_precision_g-1 downto 0)	< bin_num_i(18) else
						    '0';						   
			sc_num_s(19) <= '1' when sbong_out_s(19)(bn_precision_g-1 downto 0)	< bin_num_i(19) else
						    '0';
			sc_num_s(20) <= '1' when sbong_out_s(20)(bn_precision_g-1 downto 0)	< bin_num_i(20) else
						    '0';									
			sc_num_s(21) <= '1' when sbong_out_s(21)(bn_precision_g-1 downto 0)	< bin_num_i(21) else
						    '0';
			sc_num_s(22) <= '1' when sbong_out_s(22)(bn_precision_g-1 downto 0)	< bin_num_i(22) else
						    '0';						   
			sc_num_s(23) <= '1' when sbong_out_s(23)(bn_precision_g-1 downto 0)	< bin_num_i(23) else
						    '0';
			sc_num_s(24) <= '1' when sbong_out_s(24)(bn_precision_g-1 downto 0)	< bin_num_i(24) else
						    '0';	
			sc_num_s(25) <= '1' when sbong_out_s(25)(bn_precision_g-1 downto 0)	< bin_num_i(25) else
						    '0';
			sc_num_s(26) <= '1' when sbong_out_s(26)(bn_precision_g-1 downto 0)	< bin_num_i(26) else
						    '0';						   
			sc_num_s(27) <= '1' when sbong_out_s(27)(bn_precision_g-1 downto 0)	< bin_num_i(27) else
						    '0';
			sc_num_s(28) <= '1' when sbong_out_s(28)(bn_precision_g-1 downto 0)	< bin_num_i(28) else
						    '0';									
			sc_num_s(29) <= '1' when sbong_out_s(29)(bn_precision_g-1 downto 0)	< bin_num_i(29) else
						    '0';
			sc_num_s(30) <= '1' when sbong_out_s(30)(bn_precision_g-1 downto 0)	< bin_num_i(30) else
						    '0';						   
			sc_num_s(31) <= '1' when sbong_out_s(31)(bn_precision_g-1 downto 0)	< bin_num_i(31) else
						    '0';
			sc_num_s(32) <= '1' when sbong_out_s(32)(bn_precision_g-1 downto 0)	< bin_num_i(32) else
						    '0';	
			sc_num_s(33) <= '1' when sbong_out_s(33)(bn_precision_g-1 downto 0)	< bin_num_i(33) else
						    '0';						   
			sc_num_s(34) <= '1' when sbong_out_s(34)(bn_precision_g-1 downto 0)	< bin_num_i(34) else
						    '0';
			sc_num_s(35) <= '1' when sbong_out_s(35)(bn_precision_g-1 downto 0)	< bin_num_i(35) else
						    '0';	
			sc_num_s(36) <= '1' when sbong_out_s(36)(bn_precision_g-1 downto 0)	< bin_num_i(36) else
						    '0';	
			---------------------------------------------
			-- pack inputs for one and two delay elements
			---------------------------------------------
			one_delay_in_s(11 downto 0) <= sc_num_s(2) & sc_num_s(5)& sc_num_s(8) & sc_num_s(11) & sc_num_s(14) & sc_num_s(17) & sc_num_s(20) & sc_num_s(23) & sc_num_s(26) & sc_num_s(29) &
										   sc_num_s(32) & sc_num_s(35);
			
			
			two_delay_in_s(11 downto 0) <= sc_num_s(3) & sc_num_s(6)& sc_num_s(9) & sc_num_s(12) & sc_num_s(15) & sc_num_s(18) & sc_num_s(21) & sc_num_s(24) & sc_num_s(27) & sc_num_s(30) &		
										   sc_num_s(33) & sc_num_s(36);	
			--------------------											
			-- one delay element
			--------------------
			one_delay_unit : process(clk_i)
								begin
									if(rising_edge(clk_i))then
										if(reset_i = '1')then
											one_delay_s <= (others => '0');
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
											two_delay1_s <= (others => '0');
											two_delay2_s <= (others => '0');
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
			sc_num_o(2) <= one_delay_s(11);
			sc_num_o(3) <= two_delay2_s(11);
			sc_num_o(4) <= sc_num_s(4);
			sc_num_o(5) <= one_delay_s(10);
			sc_num_o(6) <= two_delay2_s(10);
			sc_num_o(7) <= sc_num_s(7);
			sc_num_o(8) <= one_delay_s(9);
			sc_num_o(9) <= two_delay2_s(9);	
			sc_num_o(10) <= sc_num_s(10);
			sc_num_o(11) <= one_delay_s(8);
			sc_num_o(12) <= two_delay2_s(8);
			sc_num_o(13) <= sc_num_s(13);
			sc_num_o(14) <= one_delay_s(7);
			sc_num_o(15) <= two_delay2_s(7);
			sc_num_o(16) <= sc_num_s(16);
			sc_num_o(17) <= one_delay_s(6);
			sc_num_o(18) <= two_delay2_s(6);
			sc_num_o(19) <= sc_num_s(19);
			sc_num_o(20) <= one_delay_s(5);
			sc_num_o(21) <= two_delay2_s(5);
			sc_num_o(22) <= sc_num_s(22);
			sc_num_o(23) <= one_delay_s(4);
			sc_num_o(24) <= two_delay2_s(4);
			sc_num_o(25) <= sc_num_s(25);
			sc_num_o(26) <= one_delay_s(3);
			sc_num_o(27) <= two_delay2_s(3);	
			sc_num_o(28) <= sc_num_s(28);
			sc_num_o(29) <= one_delay_s(2);
			sc_num_o(30) <= two_delay2_s(2);
			sc_num_o(31) <= sc_num_s(31);
			sc_num_o(32) <= one_delay_s(1);
			sc_num_o(33) <= two_delay2_s(1);	
			sc_num_o(34) <= sc_num_s(34);
			sc_num_o(35) <= one_delay_s(0);
			sc_num_o(36) <= two_delay2_s(0);
end behavioural;								