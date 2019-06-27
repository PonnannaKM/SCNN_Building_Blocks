--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: stochastic_sigmoid
-- Module Name: stochastic_sigmoid - Behavioral
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This module is an SC component. It implements the Sigmoid activation function found in a typical CNN.	
--				This module recieves binary sum(-ve/+ve) from the output of two parallel counter modules.
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

entity stochastic_sigmoid is
	generic(number_of_states_g : positive;-- := 8; -- number of states. always keep it powers of 2!
			input_width_g : positive-- := 6 -- input width
			);
			
	port(clk_i : in std_logic;
		 reset_i : in std_logic;
		 bin_sum_valid_i : in std_logic; -- binary sum input valid indication
		 bin_sum_i : in std_logic_vector(input_width_g-1 downto 0); -- binary sum of parallel_counter(+ve) - parallel_counter(-ve)
		 sn_sigmoid_o : out std_logic; -- stochastic number sigmoid output
		 sn_sigmoid_valid_o : out std_logic -- stochastic number sigmoid valid indication
		 );
end stochastic_sigmoid;

architecture behavioural of stochastic_sigmoid is
	attribute sync_set_reset of reset_i : signal is "true";
	
	function find_bit_width_msb(input1 : positive) return positive is -- to determine the number of bits required to represent the state signal
		begin
			for i in 0 to 63 loop
				if(input1 <= (2**i))then
					return i;
					exit;
				end if;
			end loop;
	end function find_bit_width_msb;
	
	constant state_counter_msb_c : positive := find_bit_width_msb(number_of_states_g); -- determine the msb position for state signal
    constant state_init_c : unsigned(state_counter_msb_c downto 0) := to_unsigned(((number_of_states_g/2) - 1),state_counter_msb_c+1);
	
	signal state_counter_s : unsigned(state_counter_msb_c downto 0);
	signal lfsr3bit_s : std_logic_vector(2 downto 0):= "001"; -- initialize to 1
	signal bin_sum_s : std_logic_vector(input_width_g-1 downto 0); -- one clock cycle delayed bin_sum_i for consistent output generation when bin_sum_i = 0
	signal lfsr3bit_input_s :std_logic; -- msb input of lsfr
	
	begin
		------------------------------
		-- stochastic sigmoid function
		------------------------------	
		stochastic_sigmoid : process(clk_i)
											begin
												if(rising_edge(clk_i))then
													if(reset_i = '1' or bin_sum_valid_i = '0')then
														state_counter_s <= state_init_c;
													else
														if(bin_sum_valid_i = '1')then		
															bin_sum_s <= bin_sum_i;
															if(signed(bin_sum_i) > 0)then
																if(state_counter_s < number_of_states_g-3)then
																	state_counter_s <= state_counter_s + 1;
																end if;
															elsif(signed(bin_sum_i) < 0)then
																if(state_counter_s > 2)then--0
																	state_counter_s <= state_counter_s - 1;
																end if;
															elsif(signed(bin_sum_i) = 0)then
																for i in 0 to 1 loop
																	lfsr3bit_s(i) <= lfsr3bit_s(i+1);
																	lfsr3bit_s(2) <= lfsr3bit_input_s;
																end loop;
															end if;
														end if;
													end if;
												end if;
										end process stochastic_sigmoid;
										
		sn_sigmoid_o <=  lfsr3bit_s(0) when (signed(bin_sum_s) = 0) else
		   			  state_counter_s(2);
		----------------------------
		-- lsfr msb input generation
		----------------------------		
		lfsr3bit_input_s <= lfsr3bit_s(0) xor lfsr3bit_s(2);
		
		-----------------------------
		-- output validity indication
		-----------------------------	
		valid_output_indication : process(clk_i)
									begin
										if(rising_edge(clk_i))then
											sn_sigmoid_valid_o <= bin_sum_valid_i;
										end if;
								  end process valid_output_indication;
								  
						
		
end behavioural;		