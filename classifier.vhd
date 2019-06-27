--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: classifier
-- Module Name: classifier - Structural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This component is instantiated as a sub component inside FC_10_LAYER component of SCNN. It does the final classification task of classifying the test input image
--			    into one of the 10 possible classes of LeNet5
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
use work.sc_dnn_pkg.all;
use synopsys.attributes.all;

entity classifier is
	
	port(class_clk_i : in std_logic;
		 class_reset_i : in std_logic;
		 class_input_i : in classifier_in;
		 class_input_valid_i : in std_logic;
		 class_enable_i : in std_logic;
		 class_out_o : out std_logic_vector(1 to 10);
		 class_out_valid_o : out std_logic
		 );

end classifier;

architecture structural of classifier is
	attribute sync_set_reset of class_reset_i : signal is "true";
	
	type accum_array is array (1 to 10) of signed(17 downto 0);
	signal accumulator_s : accum_array:= (others => "001111111111111111");
	signal class_ff_s : std_logic_vector(1 to 10);
	signal class_out_s : std_logic_vector(1 to 10);
	signal shift_left_s : std_logic;
	signal class_req_out_cond_s :std_logic;
	signal class_ff_en_s : std_logic;
	signal class_zero_out_s : std_logic;
	begin
							 
		---------------
		-- accumulators
		---------------
		accumulation : process(class_clk_i)
							begin
								if(rising_edge(class_clk_i))then
									if(class_reset_i = '1')then
										for i in 1 to 10 loop
											accumulator_s(i) <= "001111111111111111";
										end loop;
									else
										if(class_input_valid_i = '1')then
											for i in 1 to 10 loop
												accumulator_s(i) <= accumulator_s(i) + signed(class_input_i(i));
											end loop;
										end if;
										if(shift_left_s = '1')then
											for i in 1 to 10 loop
												accumulator_s(i) <= accumulator_s(i)(16 downto 0) & '0';
											end loop;
										end if;
									end if;
								end if;
					   end process accumulation;

		-----------------
		-- classification
		-----------------	
		
		-- class flip flops

		class_flip_flops : process(class_clk_i)
								begin
									if(rising_edge(class_clk_i))then
										if(class_reset_i = '1')then
											class_ff_s <= (others => '1');
										else
											if(class_ff_en_s = '1')then
												class_ff_s <= class_out_s;
											end if;
										end if;
									end if;
						   end process class_flip_flops;	
				
		-- output generation
		class_out_s(1) <= class_ff_s(1) and accumulator_s(1)(17);
		class_out_s(2) <= class_ff_s(2) and accumulator_s(2)(17);
		class_out_s(3) <= class_ff_s(3) and accumulator_s(3)(17);
		class_out_s(4) <= class_ff_s(4) and accumulator_s(4)(17);
		class_out_s(5) <= class_ff_s(5) and accumulator_s(5)(17);
		class_out_s(6) <= class_ff_s(6) and accumulator_s(6)(17);
		class_out_s(7) <= class_ff_s(7) and accumulator_s(7)(17);
		class_out_s(8) <= class_ff_s(8) and accumulator_s(8)(17);
		class_out_s(9) <= class_ff_s(9) and accumulator_s(9)(17);
		class_out_s(10) <= class_ff_s(10) and accumulator_s(10)(17);	
		
		-- shift left, flip flop enable/disable
		with class_out_s select
		class_req_out_cond_s <= '0' when "1000000000"|"0100000000"|"0010000000"|"0001000000"|"0000100000"|"0000010000"|"0000001000"|"0000000100"|"0000000010"|"0000000001",
								'1' when others;
								
		class_zero_out_s <= '1' when class_out_s = "0000000000" else
							'0';
							
		
		class_ff_en_s <= ((not(class_zero_out_s)) and (class_req_out_cond_s)) and (class_enable_i);
						  
		shift_left_s <= (class_enable_i) and (class_req_out_cond_s or class_zero_out_s);
		
		class_out_o <= class_out_s;
		class_out_valid_o <= (not(class_req_out_cond_s)) and class_enable_i;
		
end structural;		