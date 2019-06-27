--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: sc_neuron
-- Module Name: sc_neuron - Structural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This module is the complete stochastic neuron type1 implementation. It contains components like 'stochastic_multipliers_25', two 'parallel_counter_26'
--				and a 'stochastic_sigmoid'. This module will be a component inside the quad_sc_neuron_engine module type1.			
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

entity sc_neuron_type1 is
	generic(number_of_states_g : positive;-- := 8; -- number of states. always keep it powers of 2!
			input_width_g : positive;-- := 6 -- stochastic sigmoid input width
			mult_depth_g : positive-- := 25 -- mutliplication instances
			);
	
	port(sc_neuron_clk_i : in std_logic;
		 sc_neuron_reset_i : in std_logic;
		 sc_neuron_pixel_sn_valid_i : in std_logic; -- input pixel stochastic numbers valid indication
		 sc_neuron_pixel_sn_i : in std_logic_vector(1 to 25); -- input pixel stochastic numbers
		 sc_neuron_weight_sn_valid_i : in std_logic; -- input weight stochastic numbers valid indication
		 sc_neuron_weight_sn_i : in std_logic_vector(1 to 25); -- input weight stochastic numbers
		 sc_neuron_weight_sign_i : in std_logic_vector(1 to 25); -- input weight's sign bit
		 sc_neuron_bias_sn_i : in std_logic; -- input bias stochastic number
		 sc_neuron_bias_sign_i : in std_logic; -- input bias's sign bit
		 sc_neuron_sn_o : out std_logic; -- nueron output
		 sc_neuron_sn_valid_o : out std_logic -- neuron output valid indication
		 );
end sc_neuron_type1;

architecture structural of sc_neuron_type1 is

	attribute sync_set_reset of sc_neuron_reset_i : signal is "true";
	----------------------------------
	-- component stochastic multiplier
	----------------------------------
	component stochastic_multipliers is
		generic(mult_depth_g : positive-- := 25 -- mutliplication instances
				);
		port(sn1_i : in std_logic_vector(1 to mult_depth_g); -- 25 stochastic numbers input
			 sn2_i : in std_logic_vector(1 to mult_depth_g); -- 25 stochastic numbers input
			 sn_mult_o : out std_logic_vector(1 to mult_depth_g) -- 25 stochastic numbers multiplication output
			 );
	end component;
	
	-----------------------------
	-- component parallel counter
	-----------------------------
	component parallel_counter_26 is
		port(sn_i : in std_logic_vector(1 to 26); -- 26 stochastic number inputs from AND multiplier
			 bin_sum_o : out std_logic_vector(4 downto 0) -- total number of 1s in a column of the input matrix
			 );
	end component;
	
	-------------------------------
	-- component stochastic sigmoid
	-------------------------------		
	component stochastic_sigmoid is
		generic(number_of_states_g : positive := 8; -- number of states. always keep it powers of 2!
				input_width_g : positive := 6 -- input binary sum width
				);
				
		port(clk_i : in std_logic;
			 reset_i : in std_logic;
			 bin_sum_valid_i : in std_logic; -- binary sum input valid indication
			 bin_sum_i : in std_logic_vector(input_width_g-1 downto 0); -- binary sum of parallel_counter(+ve) - parallel_counter(-ve)
			 sn_sigmoid_o : out std_logic; -- stochastic number sigmoid output
			 sn_sigmoid_valid_o : out std_logic -- stochastic number sigmoid valid indication
			);
	end component;
	
		
	signal sn_mult_s : std_logic_vector(1 to 25); -- stochastic multiplication results
	signal sn_ppc_s : std_logic_vector(1 to 26); -- stochastic number inputs to +ve parallel_counter_26
	signal sn_npc_s : std_logic_vector(1 to 26); -- stochastic number inputs to -ve parallel_counter_26
	signal bin_sum_ppc_s : std_logic_vector(4 downto 0); -- binary sum of parallel_counter_26 for +ve inputs
	signal bin_sum_npc_s : std_logic_vector(4 downto 0); -- binary sum of parallel_counter_26 for -ve inputs	
	signal bin_sum_s : std_logic_vector(5 downto 0); -- binary signed sum
	signal bin_sum_valid_s : std_logic; -- valid input to stochastic_sigmoid
	
	begin
		-----------------------------------------
		-- instantiation of stochastic multiplier
		-----------------------------------------		
		inst_sc_multiplier_25 : stochastic_multipliers
								generic map(mult_depth_g => mult_depth_g
											)
								port map(sn1_i => sc_neuron_pixel_sn_i,
										 sn2_i => sc_neuron_weight_sn_i,
										 sn_mult_o => sn_mult_s
										 );	
										 
		-------------------------------------------------
		-- instantiation of parallel counter for positive
		-------------------------------------------------										 
		inst_parallel_count_positive : parallel_counter_26
									   port map(sn_i => sn_ppc_s,
												bin_sum_o => bin_sum_ppc_s
												);	
												
		-------------------------------------------------
		-- instantiation of parallel counter for negative
		-------------------------------------------------		
		inst_parallel_count_negative : parallel_counter_26
									   port map(sn_i => sn_npc_s,
											bin_sum_o => bin_sum_npc_s
											);

		--------------------------------------
		-- instantiation of stochastic sigmoid
		--------------------------------------											
		inst_stochastic_sigmoid : stochastic_sigmoid
							   generic map(number_of_states_g => number_of_states_g,
										   input_width_g => input_width_g
										   )
										
							   port map(clk_i => sc_neuron_clk_i,
										reset_i => sc_neuron_reset_i,
										bin_sum_valid_i => bin_sum_valid_s,
										bin_sum_i => bin_sum_s,
										sn_sigmoid_o => sc_neuron_sn_o,
										sn_sigmoid_valid_o => sc_neuron_sn_valid_o
										);

		-----------------------------------------------------------
		-- valid input indication generation for stochastic_sigmoid
		-----------------------------------------------------------		
		bin_sum_valid_s <= sc_neuron_pixel_sn_valid_i and sc_neuron_weight_sn_valid_i;
		
		------------------------------------------------------------------------
		-- binary sum computation from output of two parallel_counter_26 modules
		------------------------------------------------------------------------					
		bin_sum_s <= std_logic_vector(signed('0' & bin_sum_ppc_s) - signed('0' & bin_sum_npc_s));
		
		----------------------------------------------------------------------------------------------
		-- routing logic for routing multiplication results to appropriate parallel_counter_26 modules
		----------------------------------------------------------------------------------------------			
		routing_multiplication_results_loop_unroll : process(sn_mult_s,sc_neuron_weight_sign_i,sc_neuron_bias_sn_i,sc_neuron_bias_sign_i)
														begin
															for i in 1 to 25 loop
																sn_ppc_s(i) <= sn_mult_s(i) and (not(sc_neuron_weight_sign_i(i)));
																sn_npc_s(i) <= sn_mult_s(i) and sc_neuron_weight_sign_i(i);
															end loop;
															sn_ppc_s(26) <= sc_neuron_bias_sn_i and (not(sc_neuron_bias_sign_i));
															sn_npc_s(26) <= sc_neuron_bias_sn_i and sc_neuron_bias_sign_i;
															
													 end process routing_multiplication_results_loop_unroll;
												
end structural;				