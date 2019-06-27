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
-- Description: This module is a component of the top module 'conv16_max_layer.vhd'.
--				As a parameter buffer this module buffers the weights(2400) and biases(16) recieved through IPIF core.
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

entity param_buffer is
	generic(sn_length_g : positive;-- := 512; -- the stochastic number length. this parameter controls the depth of the buffer/ram
			param_buffer_addr_width_g : positive;-- := 10 -- read and write address width are same. 10 bits to access 0 to 815 locations (2400/3parameters + 16/1parameter)
			C_NATIVE_DATA_WIDTH_g : positive;--:= 32;
			depth_g : positive-- := 816 -- depth of parameter buffer
			);
			
	port (clk_i : in std_logic; -- clock
		  param_buffer_write_enable_i : in std_logic; -- write enable
		  param_buffer_addr_write_i : in std_logic_vector(param_buffer_addr_width_g-1 downto 0); -- write address
		  param_buffer_addr_read_i : in std_logic_vector(param_buffer_addr_width_g-1 downto 0); -- read address
	      param_buffer_write_data_i : in std_logic_vector(C_NATIVE_DATA_WIDTH_g-1 downto 0); -- write data / 32bit IPIF data words
		  param_buffer_read_data_o : out std_logic_vector(C_NATIVE_DATA_WIDTH_g-1 downto 0) -- read data / 32bit IPIF data words
		  );
		  
end param_buffer;

architecture behavioral of param_buffer is
	---------------------------------------
	-- create RAM : 816 locations x 32 bits
	---------------------------------------
	type buffer_module is array (0 to depth_g-1) of std_logic_vector(C_NATIVE_DATA_WIDTH_g-1 downto 0);
	signal param_buffer : buffer_module := (others => (others => '0'));
	
	begin
		param_buffer_unit : process (clk_i)
								begin
									if (rising_edge(clk_i)) then
										if (param_buffer_write_enable_i = '1') then
											param_buffer(conv_integer(param_buffer_addr_write_i)) <= param_buffer_write_data_i;
										else
											
										end if;
										param_buffer_read_data_o <= param_buffer(conv_integer(param_buffer_addr_read_i));
									end if;
						   end process param_buffer_unit;
end behavioral;