--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: stochastic_max
-- Module Name: stochastic_max - Structural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This module is an SC component. The module takes 4 stochastic numbers coming from 4 SC Neurons and outputs the maximum of the inputs. The output
--				is again a stochastic number. This module implements the standard max-pooling functionality in a typical CNN.
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

entity stochastic_max is
	generic(sn_precision_g : positive-- := 9 -- := 9; -- stochstatic number precsion parameter = binary precision
			);
			
	port(clk_i : in std_logic;
		 reset_i : in std_logic;
		 sn_valid_i : in std_logic; -- valid stochastic number indication input
		 sn_i : in std_logic_vector(1 to 4); -- 4 stochastic number inputs
		 sn_max_o : out std_logic; -- maximum stochastic number output
		 sn_valid_o : out std_logic -- valid maximum stochastic number output indication
		 );
end stochastic_max;

architecture structural of stochastic_max is
	attribute sync_set_reset of reset_i : signal is "true"; -- attribute to guide the synthesizer to use Xilinx device specific reset pin of FDRE

	signal counter_sn1_s : unsigned(sn_precision_g-1 downto 0); -- counter for first input stochastic number
	signal counter_sn2_s : unsigned(sn_precision_g-1 downto 0); -- counter for second input stochastic number
	signal counter_sn3_s : unsigned(sn_precision_g-1 downto 0); -- counter for third input stochastic number
	signal counter_sn4_s : unsigned(sn_precision_g-1 downto 0); -- counter for fourth input stochastic number
	signal counter_sn1_incr_s : std_logic; -- first stochastic number counter increment signal
	signal counter_sn2_incr_s : std_logic; -- second stochastic number counter increment signal	
	signal counter_sn3_incr_s : std_logic; -- third stochastic number counter increment signal
	signal counter_sn4_incr_s : std_logic; -- fourth stochastic number counter increment signal
	signal counter_sn1_decr_s : std_logic; -- first stochastic number counter decrement signal
	signal counter_sn2_decr_s : std_logic;	-- second stochastic number counter decrement signal	
	signal counter_sn3_decr_s : std_logic; -- third stochastic number counter decrement signal
	signal counter_sn4_decr_s : std_logic; -- fourth stochastic number counter decrement signal
	signal counter_sn1_not0_s : std_logic; -- first stochastic number counter not zero status
	signal counter_sn2_not0_s : std_logic; -- second stochastic number counter not zero status
	signal counter_sn3_not0_s : std_logic; -- third stochastic number counter not zero status
	signal counter_sn4_not0_s : std_logic; -- fourth stochastic number counter not zero status	
	signal sn_max_s : std_logic; -- maximum stochastic number
	signal output1_s : std_logic;
	signal output2_s : std_logic;
	signal output3_s : std_logic;
	signal output4_s : std_logic;
	signal nor1_s : std_logic;
	signal nor2_s : std_logic;
	signal nor3_s : std_logic;
	signal nor4_s : std_logic;	
	
	begin
			--------------------------------------------
			-- 4 counters for 4 input stochastic numbers
			--------------------------------------------		
			stochastic_number_counters : process(clk_i)
											begin
												if(rising_edge(clk_i))then
													if(reset_i = '1' or sn_valid_i = '0')then
														counter_sn1_s <= (others => '0');
														counter_sn2_s <= (others => '0');
														counter_sn3_s <= (others => '0');
														counter_sn4_s <= (others => '0');
													else
														if(counter_sn1_incr_s = '1')then
															counter_sn1_s <= counter_sn1_s + 1;
														elsif(counter_sn1_decr_s = '1')then
															counter_sn1_s <= counter_sn1_s - 1;
														end if;
														if(counter_sn2_incr_s = '1')then
															counter_sn2_s <= counter_sn2_s + 1;
														elsif(counter_sn2_decr_s = '1')then
															counter_sn2_s <= counter_sn2_s - 1;
														end if;					
														if(counter_sn3_incr_s = '1')then
															counter_sn3_s <= counter_sn3_s + 1;
														elsif(counter_sn3_decr_s = '1')then
															counter_sn3_s <= counter_sn3_s - 1;
														end if;					
														if(counter_sn4_incr_s = '1')then
															counter_sn4_s <= counter_sn4_s + 1;
														elsif(counter_sn4_decr_s = '1')then
															counter_sn4_s <= counter_sn4_s - 1;
														end if;
													end if;
												end if;
										end process stochastic_number_counters;			
					
			-------------------------------------------
			-- 4 counters increment and decrement logic
			-------------------------------------------										
			counter_sn1_not0_s <= '0' when counter_sn1_s = 0 else -- checking counter 1 not zero status
								  '1';
			counter_sn2_not0_s <= '0' when counter_sn2_s = 0 else -- checking counter 2 not zero status
								  '1';
			counter_sn3_not0_s <= '0' when counter_sn3_s = 0 else -- checking counter 3 not zero status
								  '1';
			counter_sn4_not0_s <= '0' when counter_sn4_s = 0 else -- checking counter 4 not zero status
								  '1';	
							  							  
			nor1_s <= not((output2_s or output3_s) or output4_s);
			nor2_s <= not((output1_s or output3_s) or output4_s);
			nor3_s <= not((output1_s or output1_s) or output4_s);
			nor4_s <= not((output1_s or output2_s) or output3_s);
			
			counter_sn1_incr_s <= (not(sn_i(1))) and sn_max_s and sn_valid_i;
			counter_sn2_incr_s <= (not(sn_i(2))) and sn_max_s and sn_valid_i;		
			counter_sn3_incr_s <= (not(sn_i(3))) and sn_max_s and sn_valid_i;					
			counter_sn4_incr_s <= (not(sn_i(4))) and sn_max_s and sn_valid_i;

			counter_sn1_decr_s <= counter_sn1_not0_s and sn_i(1) and nor1_s;
			counter_sn2_decr_s <= counter_sn2_not0_s and sn_i(2) and nor1_s;
			counter_sn3_decr_s <= counter_sn3_not0_s and sn_i(3) and nor1_s;
			counter_sn4_decr_s <= counter_sn4_not0_s and sn_i(4) and nor1_s;			
			
			---------------
			-- output logic
			---------------	
			output1_s <= (not(counter_sn1_not0_s)) and sn_i(1);
			output2_s <= (not(counter_sn2_not0_s)) and sn_i(2);
			output3_s <= (not(counter_sn3_not0_s)) and sn_i(3);
			output4_s <= (not(counter_sn4_not0_s)) and sn_i(4);	

			sn_max_s <= output1_s or output2_s or output3_s or output4_s; -- maximum stochastic number
			sn_max_o <= sn_max_s;
			sn_valid_o <= sn_valid_i;
		
end structural;