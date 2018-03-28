----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.03.2018 18:07:52
-- Design Name: 
-- Module Name: mandelbrot_calculator - Behavioral
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

entity mandelbrot_calculator is
    generic (   point_pos :         integer := 12; -- nombre de bits après la virgule
                max_iter :      integer := 100;
                SIZE :          integer := 16);
    port(
                clk :           in  std_logic;
                rst :           in  std_logic;
                ready :         out std_logic;
                start :         in  std_logic;
                finished :      out std_logic;
                c_real :        in  std_logic_vector(SIZE-1 downto 0);
                c_imaginary :   in  std_logic_vector(SIZE-1 downto 0);
                z_real :        out std_logic_vector(SIZE-1 downto 0);
                z_imaginary :   out std_logic_vector(SIZE-1 downto 0);
                iterations :    out std_logic_vector(SIZE-1 downto 0);
    );
end mandelbrot_calculator;

architecture Behavioral of mandelbrot_calculator is
    
    function mult (val1, val2 : std_logic_vector; vector_size, fix_point_pos : integer) return std_logic_vector is
        variable mult : std_logic_vector(vector_size*2-1 downto 0);
        variable lsb :  integer := fix_point_pos;
        variable msb :  integer := vector_size-1 + fix_point_pos;
    begin
        mult <= std_logic_vector(unsigned(val1)*unsigned(val2));
        return mult(msb downto lsb);
    end square;
    
    function square (val : std_logic_vector; vector_size, fix_point_pos : integer) return std_logic_vector is
    begin
        return mult(val, val, vector_size, fix_point_pos);
    end square;
    
begin
    
    process(clk)
    begin
        if rising_edge(clock) then
            if (rst = '1') then
                -- reset synchrone
            else
                -- other cases
            end if; 
        end if;        
    end process;

end Behavioral;
