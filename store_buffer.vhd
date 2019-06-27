--------------------------------------------------------------------------------------------------------------------
-- University: University of Stuttgart
-- Department: Infotech 
-- Student : Ponnanna Kelettira Muthappa
-- Create Date: 09.02.2018 15:17:55
-- Design Name: line_buffer
-- Module Name: line_buffer - Behavioural
-- Project Name: Stochastic Convolution Neural Network(LeNet5) using Stochastic Circuits on FPGA.
-- Target Devices: Zynq APSoC XC7Z020
-- Tool Versions: Vivado 2017.4
-- Description: This module is a component of the top module 'conv6_max_layer.vhd'.
--				As a store buffer this module buffers the stochastic number data output by quad sc  neuron..
-- Dependencies: 
-- 
-- Revision: 0.01
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity buffer_store is
	generic(sn_length_g : positive;-- := 512; -- the stochastic number length. this parameter controls the depth of the buffer/ram
			store_buffer_addr_width_g : positive;-- := 9 -- read and write address width are same. 9 bits to access 0 to 511 locations for sn_length_g = 512
			data_width_g : positive-- := 144 -- read and write width
			);
			
	port (clk_i : in std_logic; -- clock
		  store_buffer_write_enable_i : in std_logic; -- write enable
		  store_buffer_addr_write_i : in std_logic_vector(store_buffer_addr_width_g-1 downto 0); -- write address
		  store_buffer_addr_read_i : in std_logic_vector(store_buffer_addr_width_g-1 downto 0); -- read address
	      store_buffer_write_data_i : in std_logic_vector(1 to data_width_g); -- write data 
		  store_buffer_read_data_o : out std_logic_vector(1 to data_width_g) -- read data
		  );
		  
end buffer_store;

architecture behavioral of buffer_store is
	-----------------------------------------------------------
	-- create RAM : sn_length_g locations x no_of_pixels_g bits
	-----------------------------------------------------------
	type buffer_module is array (0 to sn_length_g-1) of std_logic_vector(1 to data_width_g);
	signal store_buffer : buffer_module := (others => (others => '0'));
	
	begin
		store_buffer_unit : process (clk_i)
								begin
									if (rising_edge(clk_i)) then
										if (store_buffer_write_enable_i = '1') then
											store_buffer(conv_integer(store_buffer_addr_write_i)) <= store_buffer_write_data_i;
										else
											
										end if;
										store_buffer_read_data_o <= store_buffer(conv_integer(store_buffer_addr_read_i));
									end if;
						   end process store_buffer_unit;
end behavioral;