----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.04.2018 11:08:22
-- Design Name: 
-- Module Name: generic_counter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity generic_counter is
    generic (   SIZE :          integer := 16);
    port (
                clk :           in  std_logic;
                rst :           in  std_logic;
                en :            in  std_logic;
                clr :           in  std_logic;
                counter :       out std_logic_vector(SIZE-1 downto 0));
end generic_counter;

architecture Behavioral of generic_counter is

signal counter_up: std_logic_vector(SIZE-1 downto 0);
    
begin
    -- up counter
    process(clk)
    begin
        if(rising_edge(clk)) then
            if rst = '1' then
                counter_up <= (others=>'0');
            elsif en = '1' then
                if clr = '1' then
                    counter_up <= (others=>'0');
                else
                    counter_up <= std_logic_vector(unsigned(counter_up) + 1);
                end if;
            end if;
        end if;
    end process;
    
    counter <= counter_up;
end Behavioral;
