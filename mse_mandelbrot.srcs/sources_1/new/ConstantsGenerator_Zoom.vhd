----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.05.2018 14:05:09
-- Design Name: 
-- Module Name: ConstantsGenerator_Zoom - Behavioral
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

entity ConstantsGenerator_Zoom is
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
            c_imaginary :   out std_logic_vector(SIZE-1 downto 0);
            up :            in  std_logic;
            left :          in  std_logic;
            down :          in  std_logic;
            right :         in  std_logic;
            zoom :          in  std_logic);
end ConstantsGenerator_Zoom;

architecture Behavioral of ConstantsGenerator_Zoom is

    -- Constants
    constant SCREEN_SIZE_X :    integer := 1024;
    constant SCREEN_SIZE_Y :    integer := 600;
    constant C_REAL_MIN :       integer := -2;
    constant C_REAL_MAX :       integer := 1;
    constant C_REAL_RANGE :     integer := C_REAL_MAX - C_REAL_MIN;
    constant C_IMAG_MIN :       integer := -1;
    constant C_IMAG_MAX :       integer := 1;
    constant C_IMAG_RANGE :     integer := C_IMAG_MAX - C_IMAG_MIN;
    
    constant C_SCREEN_DIV :     integer := 4;
    
    constant ZERO :             std_logic_vector(SIZE-1 downto 0) := (others=>'0');
    
    -- Functions
    function int2FixPointIntPart (int : integer; fix_point_pos : integer; vector_size : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(int, vector_size) sll fix_point_pos);
    end int2FixPointIntPart;
    
    impure function getDeltaInt (axisRange, nbPixels, fix_point_pos : integer) return integer is        
    begin
        return integer(real(real(axisRange) * real(2**fix_point_pos) / real(nbPixels)));
    end getDeltaInt;
    
    function getDelta (axisRange, nbPixels, fix_point_pos, vector_size : integer) return std_logic_vector is        
    begin
        return std_logic_vector(to_signed(getDeltaInt(axisRange, nbPixels, fix_point_pos), vector_size));
    end getDelta;
    
    function slv2int (slv : std_logic_vector) return integer is        
    begin
        return to_integer(unsigned(slv));
    end slv2int;
    
    function computeShift (shift : std_logic_vector; axisRange, fix_point_pos, vector_size, zoom : integer) return std_logic_vector is 
        constant baseRange :    signed := signed(int2FixPointIntPart(axisRange, fix_point_pos, vector_size));
        constant newRange :     signed := baseRange srl zoom;      
    begin
        return std_logic_vector( signed(shift) + ((baseRange - newRange) srl zoom));
    end computeShift;
    
    procedure updateValues (signal xAxis, yAxis, real_cst, imag_cst : inout std_logic_vector; variable real_shift, imag_shift : inout std_logic_vector) is    
    begin
        xAxis       <= (others => '0');
        real_cst    <= std_logic_vector(signed(int2FixPointIntPart(C_REAL_MIN, point_pos, SIZE)) + signed(real_shift));
        yAxis       <= (others => '0');
        imag_cst    <= std_logic_vector(signed(int2FixPointIntPart(C_IMAG_MAX, point_pos, SIZE)) - signed(imag_shift));
    end updateValues;
    
    -- Signals       
    signal s_c_real :       std_logic_vector(SIZE-1 downto 0);
    signal s_c_imag :       std_logic_vector(SIZE-1 downto 0);
    signal s_x :            std_logic_vector(9 downto 0);
    signal s_y :            std_logic_vector(9 downto 0);
    signal s_after_reset :  std_logic;
    signal s_finished :     std_logic;   
    
    signal s_up :           std_logic_vector(2 downto 0);
    signal s_left :         std_logic_vector(2 downto 0);
    signal s_down :         std_logic_vector(2 downto 0);
    signal s_right :        std_logic_vector(2 downto 0);
    signal s_zoom :         std_logic_vector(2 downto 0);

begin

    ComputeProcess:
    process (clk) is
        variable delta_c_real :   std_logic_vector(SIZE-1 downto 0)   := getDelta(C_REAL_RANGE, SCREEN_SIZE_X, point_pos, SIZE);
        variable delta_c_imag :   std_logic_vector(SIZE-1 downto 0)   := getDelta(C_IMAG_RANGE, SCREEN_SIZE_Y, point_pos, SIZE);
        variable zoomExp :          std_logic_vector(1 downto 0)        := (others=>'0');
        variable real_shift :       std_logic_vector(SIZE-1 downto 0)   := (others=>'0');
        variable imag_shift :       std_logic_vector(SIZE-1 downto 0)   := (others=>'0');
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
                delta_c_real    := std_logic_vector((signed(getDelta(C_REAL_RANGE, SCREEN_SIZE_X, point_pos, SIZE))));
                delta_c_imag    := std_logic_vector((signed(getDelta(C_IMAG_RANGE, SCREEN_SIZE_Y, point_pos, SIZE))));
                s_finished      <= '0';
                s_after_reset   <= '1';
                zoomExp         := (others=>'0');
                real_shift      := (others=>'0');
                imag_shift      := (others=>'0');
                -- Inputs synchronized
                s_up            <= (others=>'0');
                s_left          <= (others=>'0');
                s_down          <= (others=>'0');
                s_right         <= (others=>'0');
                s_zoom          <= (others=>'0');
            -- Sync process
            else            
                -- Compute next values if ready is set
                if ready = '1' and s_finished = '0' then
                
                    -- Do nothing after reset
                    if s_after_reset = '0' then
                        -- Next X axis & C real
                        if s_x < std_logic_vector(to_unsigned(SCREEN_SIZE_X-1, s_x'length)) then
                        
                            s_x         <= std_logic_vector(unsigned(s_x) + 1);
                            s_c_real    <= std_logic_vector(signed(s_c_real) + signed(delta_c_real));
                        else
                        
                            s_x         <= (others => '0');
                            s_c_real    <= std_logic_vector(signed(int2FixPointIntPart(C_REAL_MIN, point_pos, SIZE)) + signed(real_shift));
                            -- Next Y axis & C imaginary
                            if s_y < std_logic_vector(to_unsigned(SCREEN_SIZE_Y-1, s_y'length)) then
                            
                                s_y         <= std_logic_vector(unsigned(s_y) + 1);
                                s_c_imag    <= std_logic_vector(signed(s_c_imag) - signed(delta_c_imag));
                            -- End of Screen
                            else
                               s_y      <= (others => '0');
                               s_c_imag <= std_logic_vector(signed(int2FixPointIntPart(C_IMAG_MAX, point_pos, SIZE)) - signed(imag_shift));
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
                
                -- Inputs Synchronisation
                -- up
                s_up(0)    <= up;
                s_up(1)    <= s_up(0);
                s_up(2)    <= s_up(1);
                -- left
                s_left(0)  <= left;
                s_left(1)  <= s_left(0);
                s_left(2)  <= s_left(1);
                -- down
                s_down(0)  <= down;
                s_down(1)  <= s_down(0);
                s_down(2)  <= s_down(1);
                -- right
                s_right(0) <= right;
                s_right(1) <= s_right(0);
                s_right(2) <= s_right(1);
                -- zoom
                s_zoom(0)  <= zoom;
                s_zoom(1)  <= s_zoom(0);
                s_zoom(2)  <= s_zoom(1);
                
                -- Rising Edges detection
                -- up
                if s_up(2) = '0' and s_up(1) = '1' then
                    imag_shift    := std_logic_vector(signed(imag_shift) - (signed(delta_c_imag) sll C_SCREEN_DIV));
                    
                    updateValues (s_x, s_y, s_c_real, s_c_imag, real_shift, imag_shift);
                end if;
                -- left
                if s_left(2) = '0' and s_left(1) = '1' then
                    real_shift    := std_logic_vector(signed(real_shift) - (signed(delta_c_real) sll C_SCREEN_DIV));
                    
                    updateValues (s_x, s_y, s_c_real, s_c_imag, real_shift, imag_shift);
                 end if;
                -- down
                if s_down(2) = '0' and s_down(1) = '1' then
                    imag_shift    := std_logic_vector(signed(imag_shift) + (signed(delta_c_imag) sll C_SCREEN_DIV));
                    
                    updateValues (s_x, s_y, s_c_real, s_c_imag, real_shift, imag_shift);
                end if;
                -- right
                if s_right(2) = '0' and s_right(1) = '1' then
                    real_shift    := std_logic_vector(signed(real_shift) + (signed(delta_c_real) sll C_SCREEN_DIV));
                    
                    updateValues (s_x, s_y, s_c_real, s_c_imag, real_shift, imag_shift);
                end if;
                -- zoom
                if s_zoom(2) = '0' and s_zoom(1) = '1' then
                    zoomExp   := std_logic_vector(unsigned(zoomExp) + 1);
                    if zoomExp > B"00" then
                        real_shift    := computeShift(real_shift, C_REAL_RANGE, point_pos, SIZE, slv2int(zoomExp));
                        imag_shift    := computeShift(imag_shift, C_IMAG_RANGE, point_pos, SIZE, slv2int(zoomExp));
                    else
                        real_shift    := (others=>'0');
                        imag_shift    := (others=>'0');
                    end if;
                    
                    delta_c_real  := std_logic_vector((signed(getDelta(C_REAL_RANGE, SCREEN_SIZE_X, point_pos, SIZE)) srl slv2int(zoomExp)));
                    delta_c_imag  := std_logic_vector((signed(getDelta(C_IMAG_RANGE, SCREEN_SIZE_Y, point_pos, SIZE)) srl slv2int(zoomExp)));
                    
                    updateValues (s_x, s_y, s_c_real, s_c_imag, real_shift, imag_shift);
                end if;
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
