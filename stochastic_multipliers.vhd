--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: stochastic_multipliers
-- Module Name: stochastic_multipliers - Structural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This module is an SC component. The module takes pair of 25 stochastic numbers and performs the stochastic multiplication between them.	
-- Dependencies: 
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity stochastic_multipliers is
	generic(mult_depth_g : positive-- := 25 -- mutliplication instances
			);
	port(sn1_i : in std_logic_vector(1 to mult_depth_g); -- 25 stochastic numbers input
		 sn2_i : in std_logic_vector(1 to mult_depth_g); -- 25 stochastic numbers input
		 sn_mult_o : out std_logic_vector(1 to mult_depth_g) -- 25 stochastic numbers multiplication output
		 );
end stochastic_multipliers;

architecture structural of stochastic_multipliers is
	begin
		----------------------------
		-- stochastic multiplication
		----------------------------	
		multiplication_loop_unroll : process(sn1_i,sn2_i)
										begin
											for i in 1 to mult_depth_g loop
												sn_mult_o(i) <= sn1_i(i) and sn2_i(i);
											end loop;
									 end process multiplication_loop_unroll;
		
end structural;
