--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: sc_mac_84
-- Module Name: sc_mac_84 - Structural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: 
--
-- Dependencies: 
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-------------------------------------------------------------------------------------------------------------------
library IEEE;
library synopsys;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use synopsys.attributes.all;


entity sc_mac_84 is
	generic(mult_depth_g : positive-- := 84 -- mutliplication instances
			);
	
	port(sc_mac_clk_i : in std_logic;
		 sc_mac_reset_i : in std_logic;
		 sc_mac_pixel_sn_valid_i : in std_logic; -- input pixel stochastic numbers valid indication from first convolution layer
		 sc_mac_pixel_sn_i : in std_logic_vector(1 to 84); -- input pixel stochastic numbers from first convolution layer
		 sc_mac_weight_sn_valid_i : in std_logic; -- input weight stochastic numbers valid indication
		 sc_mac_weight_sn_i : in std_logic_vector(1 to 84); -- input weight stochastic numbers
		 sc_mac_weight_sign_i : in std_logic_vector(1 to 84); -- input weight's sign bit
		 sc_mac_o : out std_logic_vector(7 downto 0); -- nueron output
		 sc_mac_valid_o : out std_logic -- neuron output valid indication		 
		 );
end sc_mac_84;

architecture structural of sc_mac_84 is

	attribute sync_set_reset of sc_mac_reset_i : signal is "true";
	----------------------------------
	-- component stochastic multiplier
	----------------------------------
	component stochastic_multipliers is
		generic(mult_depth_g : positive:= 84 -- mutliplication instances
			);	
		port(sn1_i : in std_logic_vector(1 to mult_depth_g); -- 120 stochastic numbers input
			 sn2_i : in std_logic_vector(1 to mult_depth_g); -- 120 stochastic numbers input
			 sn_mult_o : out std_logic_vector(1 to mult_depth_g) -- 25 stochastic numbers multiplication output
			 );
	end component;
	
	-----------------------------
	-- component parallel counter
	-----------------------------
	component parallel_counter_42 is
		port(sn_i : in std_logic_vector(1 to 42); -- 42 stochastic number inputs from AND multiplier
			 bin_sum_o : out std_logic_vector(5 downto 0) -- total number of 1s in a column of the input matrix
			 );
	end component;
	
		
	signal sn_mult_s : std_logic_vector(1 to 84); -- stochastic multiplication results
	signal sn_ppc_s : std_logic_vector(1 to 84); -- stochastic number inputs to +ve parallel_counter_42
	signal sn_npc_s : std_logic_vector(1 to 84); -- stochastic number inputs to -ve parallel_counter_42
	type bin_sum_pc42 is array(1 to 2) of std_logic_vector(5 downto 0); -- binary sum of parallel_counter_42s
	signal bin_sum_ppc_s : bin_sum_pc42; -- binary sum of 2 parallel_counter_42 for +ve inputs
	signal bin_sum_npc_s : bin_sum_pc42; -- binary sum of 2 parallel_counter_42 for -ve inputs
	type bin_sum is array(1 to 2) of signed(6 downto 0); -- binary signed sum
	signal bin_sum_s : bin_sum; -- 2 binary signed sum
	signal bin_sum_final_s : std_logic_vector(7 downto 0); -- final accumulated binary sum
	begin
		------------------------------------------
		-- instantiation of stochastic multipliers
		------------------------------------------	
		inst_sc_multiplier_84 : stochastic_multipliers
								generic map(mult_depth_g => mult_depth_g
											)
		
								port map(sn1_i => sc_mac_pixel_sn_i(1 to 84),
										 sn2_i => sc_mac_weight_sn_i(1 to 84),
										 sn_mult_o => sn_mult_s(1 to 84)
										 );	
										 
									 
		----------------------------------------------------
		-- instantiation of 2 parallel counters for positive
		----------------------------------------------------										 
		inst_parallel_count_positive_1 : parallel_counter_42
									     port map(sn_i => sn_ppc_s(1 to 42),
												  bin_sum_o => bin_sum_ppc_s(1)
												  );	
												
		inst_parallel_count_positive_2 : parallel_counter_42
									     port map(sn_i => sn_ppc_s(43 to 84),
												  bin_sum_o => bin_sum_ppc_s(2)
												  );	
												  
		----------------------------------------------------
		-- instantiation of 2 parallel counters for negative
		----------------------------------------------------		
		inst_parallel_count_negative_1 : parallel_counter_42
									     port map(sn_i => sn_npc_s(1 to 42),
												  bin_sum_o => bin_sum_npc_s(1)
												  );	
												
		inst_parallel_count_negative_2 : parallel_counter_42
									     port map(sn_i => sn_npc_s(43 to 84),
												  bin_sum_o => bin_sum_npc_s(2)
												  );									  
                                       

		------------------------------------
		-- valid input indication generation
		------------------------------------	
		sc_mac_valid_o <= sc_mac_pixel_sn_valid_i and sc_mac_weight_sn_valid_i;
		
		------------------------------------------------------------------------
		-- binary sum computation from output of two parallel_counter_42 modules
		------------------------------------------------------------------------					
		bin_sum_s(1) <= (signed('0' & bin_sum_ppc_s(1)) - signed('0' & bin_sum_npc_s(1)));
		bin_sum_s(2) <= (signed('0' & bin_sum_ppc_s(2)) - signed('0' & bin_sum_npc_s(2)));
	
		
		bin_sum_final_s <= std_logic_vector(resize(bin_sum_s(1),8) + resize(bin_sum_s(2),8));
		----------------------------------------------------------------------------------------------
		-- routing logic for routing multiplication results to appropriate parallel_counter_42 modules
		----------------------------------------------------------------------------------------------			
		routing_multiplication_results_loop_unroll : process(sn_mult_s,sc_mac_weight_sign_i)
														begin
															for i in 1 to 84 loop
																sn_ppc_s(i) <= sn_mult_s(i) and (not(sc_mac_weight_sign_i(i)));
																sn_npc_s(i) <= sn_mult_s(i) and sc_mac_weight_sign_i(i);															
															end loop;   	
													 end process routing_multiplication_results_loop_unroll;
													 
													 
													 
		sc_mac_o <=  bin_sum_final_s;
					   										
end structural;				