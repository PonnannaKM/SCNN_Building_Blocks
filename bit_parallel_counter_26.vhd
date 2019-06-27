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
-- Description: The module takes 26 stochastic numbers (25 + 1bias) coming from AND multipier and outputs the total number of 1s in each column
--				of the input matrix of stochastic numbers. This module implements the standard accumulation of '(weights*input)+bias' functionality in a typical CNN.
--				The output is in binary and goes into a binaty adder before reaching sc sigmoid component.	This module instantiates 19 full adder components		
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

entity parallel_counter_26 is
	port(sn_i : in std_logic_vector(1 to 26); -- 26 stochastic number inputs from AND multiplier
		 bin_sum_o : out std_logic_vector(4 downto 0) -- total number of 1s in a column of the input matrix
		 );
end parallel_counter_26;

architecture structural of parallel_counter_26 is
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
		   sumfa11_s,sumfa12_s,sumfa13_s,sumfa14_s,sumfa15_s,sumfa16_s,sumfa17_s,sumfa18_s,sumfa19_s : std_logic;
	signal carryfa1_s,carryfa2_s,carryfa3_s,carryfa4_s,carryfa5_s,carryfa6_s,carryfa7_s,carryfa8_s,carryfa9_s,carryfa10_s,
		   carryfa11_s,carryfa12_s,carryfa13_s,carryfa14_s,carryfa15_s,carryfa16_s,carryfa17_s,carryfa18_s,carryfa19_s : std_logic;
	signal sum_out1_s,sum_out2_s : std_logic_vector(3 downto 0);
	signal bin_sum_s : unsigned(4 downto 0);
	
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
				port map(operand1_i => sumfa1_s,
					 operand2_i => sumfa2_s,
					 carry_i => sumfa3_s,
					 sum_o => sumfa7_s,
					 carry_o => carryfa7_s
					 );	
		inst8 : full_adder
				port map(operand1_i => carryfa1_s,
					 operand2_i => carryfa2_s,
					 carry_i => carryfa3_s,
					 sum_o => sumfa8_s,
					 carry_o => carryfa8_s
					 );	

		inst9 : full_adder
				port map(operand1_i => sumfa4_s,
					 operand2_i => sumfa5_s,
					 carry_i => sumfa6_s,
					 sum_o => sumfa9_s,
					 carry_o => carryfa9_s
					 );		

		inst10 : full_adder
				port map(operand1_i => carryfa4_s,
					 operand2_i => carryfa5_s,
					 carry_i => carryfa6_s,
					 sum_o => sumfa10_s,
					 carry_o => carryfa10_s
					 );	
		inst11 : full_adder
				port map(operand1_i => sumfa7_s,
					 operand2_i => sn_i(19),
					 carry_i => sumfa9_s,
					 sum_o => sumfa11_s,
					 carry_o => carryfa11_s
					 );	
		inst12 : full_adder
				port map(operand1_i => carryfa7_s,
					 operand2_i => sumfa8_s,
					 carry_i => carryfa9_s,
					 sum_o => sumfa12_s,
					 carry_o => carryfa12_s
					 );		
		inst13 : full_adder
				port map(operand1_i => sumfa11_s,
					 operand2_i => sn_i(20),
					 carry_i => sn_i(21),
					 sum_o => sumfa13_s,
					 carry_o => carryfa13_s
					 );		
		inst14 : full_adder
				port map(operand1_i => carryfa11_s,
					 operand2_i => sumfa12_s,
					 carry_i => sumfa10_s,
					 sum_o => sumfa14_s,
					 carry_o => carryfa14_s
					 );		
		inst15 : full_adder
				port map(operand1_i => carryfa12_s,
					 operand2_i => carryfa8_s,
					 carry_i => carryfa10_s,
					 sum_o => sumfa15_s,
					 carry_o => carryfa15_s
					 );		
		inst16 : full_adder
				port map(operand1_i => sumfa13_s,
					 operand2_i => sn_i(22),
					 carry_i => sn_i(23),
					 sum_o => sumfa16_s,
					 carry_o => carryfa16_s
					 );		
		inst17 : full_adder
				port map(operand1_i => carryfa16_s,
					 operand2_i => carryfa13_s,
					 carry_i => sumfa14_s,
					 sum_o => sumfa17_s,
					 carry_o => carryfa17_s
					 );		
		inst18 : full_adder
				port map(operand1_i => sumfa16_s,
					 operand2_i => sn_i(24),
					 carry_i => sn_i(25),
					 sum_o => sumfa18_s,
					 carry_o => carryfa18_s
					 );		
		inst19 : full_adder
				port map(operand1_i => carryfa17_s,
					 operand2_i => carryfa14_s,
					 carry_i => sumfa15_s,
					 sum_o => sumfa19_s,
					 carry_o => carryfa19_s
					 );		

					 
		----------------------------
		-- binary output computation
		----------------------------	
		sum_out1_s <= carryfa15_s & sumfa19_s & sumfa17_s & sn_i(26);
		sum_out2_s <= carryfa19_s & '0' & carryfa18_s & sumfa18_s;
		
		bin_sum_s <= resize(unsigned(sum_out1_s),5) + resize(unsigned(sum_out2_s),5);
		bin_sum_o <= std_logic_vector(bin_sum_s);
		
end structural;
	
	