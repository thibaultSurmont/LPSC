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

    function int2FixPointIntPart (int : integer; fix_point_pos : integer; vector_size : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(int, vector_size) sll fix_point_pos);
    end int2FixPointIntPart;

    -- Constants
    constant SCREEN_SIZE_X :    integer := 1024;
    constant SCREEN_SIZE_Y :    integer := 600;
    constant C_REAL_MIN :       integer := -2;
    constant C_REAL_MAX :       integer := 1;
    constant C_IMAG_MIN :       integer := -1;
    constant C_IMAG_MAX :       integer := 1;
    constant DELTA_C_REAL_INT : integer := integer(real(real(C_REAL_MAX - C_REAL_MIN) * real(2**point_pos) / real(SCREEN_SIZE_X)));
    constant DELTA_C_IMAG_INT : integer := integer(real(real(C_IMAG_MAX - C_IMAG_MIN) * real(2**point_pos) / real(SCREEN_SIZE_Y)));
    
    constant DELTA_C_REAL :     std_logic_vector(SIZE-1 downto 0) := std_logic_vector(to_signed(DELTA_C_REAL_INT, SIZE));
    constant DELTA_C_IMAG :     std_logic_vector(SIZE-1 downto 0) := std_logic_vector(to_signed(DELTA_C_IMAG_INT, SIZE));
    
    -- Signals
    signal s_c_real :       std_logic_vector(SIZE-1 downto 0);
    signal s_c_imag :       std_logic_vector(SIZE-1 downto 0);
    signal s_x :            std_logic_vector(9 downto 0);
    signal s_y :            std_logic_vector(9 downto 0);
    signal s_after_reset :  std_logic;
    signal s_finished :     std_logic;     

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
                s_c_real        <= int2FixPointIntPart(C_REAL_MIN, point_pos, SIZE);
                s_c_imag        <= int2FixPointIntPart(C_IMAG_MAX, point_pos, SIZE);
                s_finished      <= '0';
                s_after_reset   <= '1';
            
            -- Compute next values if ready is set
            elsif ready = '1' and s_finished = '0' then
            
                -- Do nothing after reset
                if s_after_reset = '0' then
                    
                    -- Next X axis & C real
                    if s_x < std_logic_vector(to_unsigned(SCREEN_SIZE_X-1, s_x'length)) then
                    
                        s_x         <= std_logic_vector(unsigned(s_x) + 1);
                        s_c_real    <= std_logic_vector(signed(s_c_real) + signed(DELTA_C_REAL));
                    
                    else
                    
                        s_x         <= (others => '0');
                        s_c_real    <= int2FixPointIntPart(C_REAL_MIN, point_pos, SIZE);
                        
                        -- Next Y axis & C imaginary
                        if s_y < std_logic_vector(to_unsigned(SCREEN_SIZE_Y-1, s_y'length)) then
                        
                            s_y         <= std_logic_vector(unsigned(s_y) + 1);
                            s_c_imag    <= std_logic_vector(signed(s_c_imag) - signed(DELTA_C_IMAG));
                            
                        -- End of Screen
                        else
                        
                           s_y      <= (others => '0');
                           s_c_imag <= int2FixPointIntPart(C_IMAG_MAX, point_pos, SIZE);
                        
                        end if;
                    
                    end if;
                    
                else
                
                    -- Clear signal
                    s_after_reset <= '0';
                
                end if;
                
                -- New values available
                s_finished <= '1';
                
            else
            
                s_finished <= '0';
                
            end if;
            
        end if;
        
    end process;

    -- Affect signals
    screen_x    <= s_x;
    screen_y    <= s_y;
    c_real      <= s_c_real;
    c_imaginary <= s_c_imag;
    finished    <= s_finished;

end Behavioral;
