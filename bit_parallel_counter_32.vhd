--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: parallel_counter_26
-- Module Name: parallel_counter_26 - Structural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: The module takes 32 stochastic numbers coming from AND multipier and outputs the total number of 1s in each column
--				of the input matrix of stochastic numbers. This module implements the standard accumulation of '(weights*input)+bias' functionality in a typical CNN.
--				The output is in binary and goes into a binaty adder before reaching sc sigmoid component.	This module instantiates 26 full adder components		
-- Dependencies: 
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity parallel_counter_32 is
	port(sn_i : in std_logic_vector(1 to 32); -- 64 stochastic number inputs from AND multiplier
		 bin_sum_o : out std_logic_vector(5 downto 0)-- total number of 1s in a column of the input matrix
		 );
end parallel_counter_32;

architecture structural of parallel_counter_32 is
	-----------------------
	-- component full adder
	-----------------------
	component full_adder is
		port(operand1_i : in std_logic;
			 operand2_i : in std_logic;
			 carry_i : in std_logic;
			 sum_o : out std_logic;
			 carry_o : out std_logic
			 );
	end component;

	signal sumfa1_s,sumfa2_s,sumfa3_s,sumfa4_s,sumfa5_s,sumfa6_s,sumfa7_s,sumfa8_s,sumfa9_s,sumfa10_s,
		   sumfa11_s,sumfa12_s,sumfa13_s,sumfa14_s,sumfa15_s,sumfa16_s,sumfa17_s,sumfa18_s,sumfa19_s,sumfa20_s,
		   sumfa21_s,sumfa22_s,sumfa23_s,sumfa24_s,sumfa25_s,sumfa26_s,sumfa27_s,sumfa28_s,sumfa29_s,sumfa30_s,
		   sumfa31_s,sumfa32_s : std_logic;

	signal carryfa1_s,carryfa2_s,carryfa3_s,carryfa4_s,carryfa5_s,carryfa6_s,carryfa7_s,carryfa8_s,carryfa9_s,carryfa10_s,
		   carryfa11_s,carryfa12_s,carryfa13_s,carryfa14_s,carryfa15_s,carryfa16_s,carryfa17_s,carryfa18_s,carryfa19_s,carryfa20_s,
		   carryfa21_s,carryfa22_s,carryfa23_s,carryfa24_s,carryfa25_s,carryfa26_s,carryfa27_s,carryfa28_s,carryfa29_s,carryfa30_s,
		   carryfa31_s,carryfa32_s : std_logic;

	signal sum_out1_s,sum_out2_s : std_logic_vector(4 downto 0);
	signal bin_sum_s : unsigned(5 downto 0);
	
	begin
		-------------------------------
		-- instantiations of full adder
		-------------------------------	
		inst1 : full_adder
				port map(operand1_i => sn_i(1),
					 operand2_i => sn_i(2),
					 carry_i => sn_i(3),
					 sum_o => sumfa1_s,
					 carry_o => carryfa1_s
					 );	

		inst2 : full_adder
				port map(operand1_i => sn_i(4),
					 operand2_i => sn_i(5),
					 carry_i => sn_i(6),
					 sum_o => sumfa2_s,
					 carry_o => carryfa2_s
					 );	

		inst3 : full_adder
				port map(operand1_i => sn_i(7),
					 operand2_i => sn_i(8),
					 carry_i => sn_i(9),
					 sum_o => sumfa3_s,
					 carry_o => carryfa3_s
					 );	
					 
		inst4 : full_adder
				port map(operand1_i => sn_i(10),
					 operand2_i => sn_i(11),
					 carry_i => sn_i(12),
					 sum_o => sumfa4_s,
					 carry_o => carryfa4_s
					 );	

		inst5 : full_adder
				port map(operand1_i => sn_i(13),
					 operand2_i => sn_i(14),
					 carry_i => sn_i(15),
					 sum_o => sumfa5_s,
					 carry_o => carryfa5_s
					 );		

		inst6 : full_adder
				port map(operand1_i => sn_i(16),
					 operand2_i => sn_i(17),
					 carry_i => sn_i(18),
					 sum_o => sumfa6_s,
					 carry_o => carryfa6_s
					 );	

		inst7 : full_adder
				port map(operand1_i => sn_i(19),
					 operand2_i => sn_i(20),
					 carry_i => sn_i(21),
					 sum_o => sumfa7_s,
					 carry_o => carryfa7_s
					 );	
					 
		inst8 : full_adder
				port map(operand1_i => sn_i(22),
					 operand2_i => sn_i(23),
					 carry_i => sn_i(24),
					 sum_o => sumfa8_s,
					 carry_o => carryfa8_s
					 );		

		inst9 : full_adder
				port map(operand1_i => sn_i(25),
					 operand2_i => sn_i(26),
					 carry_i => sn_i(27),
					 sum_o => sumfa9_s,
					 carry_o => carryfa9_s
					 );		

		inst10 : full_adder
				port map(operand1_i => sumfa1_s,
					 operand2_i => sumfa2_s,
					 carry_i => sumfa3_s,
					 sum_o => sumfa10_s,
					 carry_o => carryfa10_s
					 );	
					 
		inst11 : full_adder
				port map(operand1_i => carryfa1_s,
					 operand2_i => carryfa2_s,
					 carry_i => carryfa3_s,
					 sum_o => sumfa11_s,
					 carry_o => carryfa11_s
					 );		
					 
		inst12 : full_adder
				port map(operand1_i => sumfa4_s,
					 operand2_i => sumfa5_s,
					 carry_i => sumfa6_s,
					 sum_o => sumfa12_s,
					 carry_o => carryfa12_s
					 );	
					 
		inst13 : full_adder
				port map(operand1_i => carryfa4_s,
					 operand2_i => carryfa5_s,
					 carry_i => carryfa6_s,
					 sum_o => sumfa13_s,
					 carry_o => carryfa13_s
					 );	
					 
		inst14 : full_adder
				port map(operand1_i => sumfa7_s,
					 operand2_i => sumfa8_s,
					 carry_i => sumfa9_s,
					 sum_o => sumfa14_s,
					 carry_o => carryfa14_s
					 );	
					 
		inst15 : full_adder
				port map(operand1_i => carryfa7_s,
					 operand2_i => carryfa8_s,
					 carry_i => carryfa9_s,
					 sum_o => sumfa15_s,
					 carry_o => carryfa15_s
					 );	
					 
		inst16 : full_adder
				port map(operand1_i => sumfa10_s,
					 operand2_i => sumfa12_s,
					 carry_i => sumfa14_s,
					 sum_o => sumfa16_s,
					 carry_o => carryfa16_s
					 );	
					 
		inst17 : full_adder
				port map(operand1_i => carryfa10_s,
					 operand2_i => carryfa12_s,
					 carry_i => carryfa14_s,
					 sum_o => sumfa17_s,
					 carry_o => carryfa17_s
					 );	
					 
		inst18 : full_adder
				port map(operand1_i => sumfa13_s,
					 operand2_i => sumfa11_s,
					 carry_i => sumfa15_s,
					 sum_o => sumfa18_s,
					 carry_o => carryfa18_s
					 );	
					 
		inst19 : full_adder
				port map(operand1_i => carryfa11_s,
					 operand2_i => carryfa13_s,
					 carry_i => carryfa15_s,
					 sum_o => sumfa19_s,
					 carry_o => carryfa19_s
					 );		

		inst20 : full_adder
				port map(operand1_i => sumfa16_s,
					 operand2_i => sn_i(28),
					 carry_i => sn_i(29),
					 sum_o => sumfa20_s,
					 carry_o => carryfa20_s
					 );	
					 
		inst21 : full_adder
				port map(operand1_i => carryfa16_s,
					 operand2_i => sumfa17_s,
					 carry_i => sumfa18_s,
					 sum_o => sumfa21_s,
					 carry_o => carryfa21_s
					 );	

		inst22 : full_adder
				port map(operand1_i => carryfa17_s,
					 operand2_i => carryfa18_s,
					 carry_i => sumfa19_s,
					 sum_o => sumfa22_s,
					 carry_o => carryfa22_s
					 );	
		inst23 : full_adder
				port map(operand1_i => sumfa20_s,
					 operand2_i => sn_i(30),
					 carry_i => sn_i(31),
					 sum_o => sumfa23_s,
					 carry_o => carryfa23_s
					 );	
		inst24 : full_adder
				port map(operand1_i => carryfa23_s,
					 operand2_i => carryfa20_s,
					 carry_i => sumfa21_s,
					 sum_o => sumfa24_s,
					 carry_o => carryfa24_s
					 );	
		inst25 : full_adder
				port map(operand1_i => carryfa24_s,
					 operand2_i => carryfa21_s,
					 carry_i => sumfa22_s,
					 sum_o => sumfa25_s,
					 carry_o => carryfa25_s 
					 );	
		inst26 : full_adder
				port map(operand1_i => carryfa25_s,
					 operand2_i => carryfa22_s,
					 carry_i => carryfa19_s,
					 sum_o => sumfa26_s,
					 carry_o => carryfa26_s
					 );	

		 
		----------------------------
		-- binary output computation
		----------------------------	
		sum_out1_s <= carryfa26_s & sumfa26_s & sumfa25_s & sumfa24_s & sumfa23_s;
		sum_out2_s <= '0' & '0' & '0' & '0' & sn_i(32);
		
		bin_sum_s <= resize(unsigned(sum_out1_s),6) + resize(unsigned(sum_out2_s),6);
		bin_sum_o <= std_logic_vector(bin_sum_s);
end structural;
	
	