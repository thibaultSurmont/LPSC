----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.04.2018 09:59:51
-- Design Name: 
-- Module Name: generic_register - Behavioral
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

entity generic_register is
    generic(    SIZE :          integer := 16);
    port(
                clk :           in  std_logic;
                rst :           in  std_logic;
                en :            in  std_logic;
                clr :           in  std_logic;
                data_in :       in  std_logic_vector(SIZE-1 downto 0);
                data_out :      out std_logic_vector(SIZE-1 downto 0));
end generic_register;

architecture Behavioral of generic_register is
    
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- reset synchrone
                data_out <= (others=>'0');
            elsif en = '1' then
                if clr = '1' then
                    -- clear synchrone
                    data_out <= (others=>'0');
                else
                    -- update output
                    data_out <= data_in;
                end if;
            end if; 
        end if;        
    end process;

end Behavioral;
