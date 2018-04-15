----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.04.2018 10:16:33
-- Design Name: 
-- Module Name: constants_generator - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity constants_generator is
    generic (   
                point_pos :         integer := 12; -- nombre de bits après la virgule
                SIZE :              integer := 16);
    port (
                clk :           in  std_logic;
                rst :           in  std_logic;
                ready :         in  std_logic;
                finished :      out std_logic;
                screen_x :      out std_logic_vector(9 downto 0);
                screen_y :      out std_logic_vector(9 downto 0);
                c_real :        out std_logic_vector(SIZE-1 downto 0);
                c_imaginary :   out std_logic_vector(SIZE-1 downto 0));
end constants_generator;

architecture Behavioral of constants_generator is

    -- Constants
    constant SCREEN_SIZE_X :    integer := 1024;
    constant SCREEN_SIZE_Y :    integer := 680;
    constant C_REAL_MIN :       integer := -2;
    constant C_REAL_MAX :       integer := 1;
    constant C_IMAG_MIN :       integer := -1;
    constant C_IMAG_MAX :       integer := 1;
    constant DELTA_C_REAL :     integer := SCREEN_SIZE_X / (C_REAL_MAX - C_REAL_MIN);
    constant DELTA_C_IMAG :     integer := SCREEN_SIZE_Y / (C_IMAG_MAX - C_IMAG_MIN);
    
    -- Signals
    signal s_c_real :       std_logic_vector(SIZE-1 downto 0);
    signal s_c_imag :       std_logic_vector(SIZE-1 downto 0);
    signal s_x :            std_logic_vector(9 downto 0);
    signal s_y :            std_logic_vector(9 downto 0);
    signal s_after_reset :  std_logic;     

begin

    SyncProcess:
    process (clk) is
    begin
    
        -- Synchronization
        if rising_edge(clk) then
        
            -- Reset
            if rst = '1' then
            
                -- Clear signals
                s_x             <= (others => '0');
                s_y             <= (others => '0');
                s_c_real        <= std_logic_vector(to_signed(C_REAL_MIN, SIZE));      -- point fixe
                s_c_imag        <= std_logic_vector(to_signed(C_IMAG_MAX, SIZE));
                finished        <= '0';
                s_after_reset   <= '1';
            
            -- Compute next values if ready is set
            elsif ready = '1' then
            
                -- Do nothing after reset
                if s_after_reset = '0' then
                
                    -- Next Y axis & C imaginary
                    if s_y < std_logic_vector(to_unsigned(SCREEN_SIZE_Y, SIZE)) then
                    
                        -- Next X axis & C real
                        if s_x < std_logic_vector(to_unsigned(SCREEN_SIZE_X, SIZE)) then
                        
                            s_x         <= std_logic_vector(unsigned(s_x) + 1);
                            s_c_real    <= std_logic_vector(signed(s_c_real) + DELTA_C_REAL);
                        
                        else
                        
                            s_x         <= (others => '0');
                            s_c_real    <= std_logic_vector(to_signed(C_REAL_MIN, SIZE));
                            
                            s_y         <= std_logic_vector(unsigned(s_y) + 1);
                            s_c_imag    <= std_logic_vector(signed(s_c_imag) + DELTA_C_REAL);
                        
                        end if;
                        
                    -- End of Screen
                    else
                    
                       s_y      <= (others => '0');
                       s_c_imag <= std_logic_vector(to_signed(C_IMAG_MAX, SIZE));
                    
                    end if;
                
                end if;
                
                -- New values available
                finished <= '1';
                
            else
            
                finished <= '0';
                
            end if;
            
        end if;
        
    end process;

    -- Affect signals
    screen_x    <= s_x;
    screen_y    <= s_y;
    c_real      <= s_c_real;
    c_imaginary <= s_c_imag;

end Behavioral;
