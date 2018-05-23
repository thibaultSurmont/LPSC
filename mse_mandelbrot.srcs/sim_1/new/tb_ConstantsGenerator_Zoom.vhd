----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.05.2018 19:02:22
-- Design Name: 
-- Module Name: tb_ConstantsGenerator_Zoom - Behavioral
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

entity tb_ConstantsGenerator_Zoom is
--  Port ( );
end tb_ConstantsGenerator_Zoom;

architecture testbench of tb_ConstantsGenerator_Zoom is

    constant CLK_PERIOD :       time := 10 ns;

    constant POINT_POSITION :   integer := 12;
    constant MAX_ITERATION :    integer := 100;
    constant VECTOR_SIZE :      integer := 16;
    
    component ConstantsGenerator_Zoom is
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
    end component ConstantsGenerator_Zoom;
    

    -- Stimulus
    signal sti_clk :        std_logic := '0';
    signal sti_rst :        std_logic;
    -- Constants generator interface
    signal sti_ready :      std_logic;
    signal sti_up :         std_logic;
    signal sti_left :       std_logic;
    signal sti_down :       std_logic;
    signal sti_right :      std_logic;
    signal sti_zoom :       std_logic;
    signal obs_x :          std_logic_vector(9 downto 0);
    signal obs_y :          std_logic_vector(9 downto 0);
    signal obs_c_real :     std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_c_imag :     std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_finished :   std_logic;
    
    function slv2int (slv : std_logic_vector) return integer is        
    begin
        return to_integer(unsigned(slv));
    end slv2int;
  
begin

    ---------------------------------------------------------------------------
    -- Clock Simulation
    ---------------------------------------------------------------------------
    SimClk :
    sti_clk <= not sti_clk after (CLK_PERIOD / 2);
    
    ---------------------------------------------------------------------------
    -- Constants Generator
    ---------------------------------------------------------------------------
    ConstantsGenerator :
    entity work.ConstantsGenerator_Zoom
        generic map (
            point_pos   => POINT_POSITION,
            SIZE        => VECTOR_SIZE)
        port map (
            clk         => sti_clk,
            rst         => sti_rst,
            ready       => sti_ready,
            finished    => obs_finished,
            screen_x    => obs_x,
            screen_y    => obs_y,
            c_real      => obs_c_real,
            c_imaginary => obs_c_imag,
            up          => sti_up,
            left        => sti_left,
            down        => sti_down,
            right       => sti_right,
            zoom        => sti_zoom);
            
    ---------------------------------------------------------------------------
    -- Simulation
    ---------------------------------------------------------------------------
    Simulation : 
    process is
        variable screen_x : integer := 0;
        variable screen_y : integer := 0;
    begin
    
        -- Reset
        wait until rising_edge(sti_clk);
        sti_rst <= '1';
        
        sti_ready   <= '0';
        sti_up      <= '0';
        sti_left    <= '0';
        sti_down    <= '0';
        sti_right   <= '0';
        sti_zoom    <= '0';
        
        -- Apply stimulus
        wait until rising_edge(sti_clk);
        sti_rst <= '0';
        
        sti_zoom    <= '1';
        wait until rising_edge(sti_clk);
        sti_zoom    <= '0';
        sti_right   <= '1';
        wait until rising_edge(sti_clk);
        sti_zoom    <= '0';
        
        
        -- Infinite loop
        while true loop
        
            -- New constant
            sti_ready   <= '1';
            wait until rising_edge(sti_clk);
            sti_ready   <= '0';
            
            -- Constant is valid
            wait until rising_edge(obs_finished);
            -- Wait for a clock period
            wait until rising_edge(sti_clk);
                
           -- next iteration
        end loop;

        wait;
    end process Simulation;

end testbench;