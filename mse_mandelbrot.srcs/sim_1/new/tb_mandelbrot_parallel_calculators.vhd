----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.05.2018 19:57:13
-- Design Name: 
-- Module Name: tb_mandelbrot_parallel_calculators - Behavioral
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

entity tb_mandelbrot_parallel_calculators is
--  Port ( );
end tb_mandelbrot_parallel_calculators;

architecture testbench of tb_mandelbrot_parallel_calculators is

    constant CLK_PERIOD :       time := 10 ns;
    constant CLK_HDMI_PERIOD :  time := 25 ns;

    constant POINT_POSITION :   integer := 12;
    constant MAX_ITERATION :    integer := 100;
    constant VECTOR_SIZE :      integer := 16;
    
    component constants_generator is
        generic (   point_pos :     integer := 12; -- nombre de bits après la virgule
                    SIZE :          integer := 16);
        port (
                    clk :           in  std_logic;
                    rst :           in  std_logic;
                    ready :         in  std_logic;
                    finished :      out std_logic;
                    screen_x :      out std_logic_vector(9 downto 0);
                    screen_y :      out std_logic_vector(9 downto 0);
                    c_real :        out std_logic_vector(SIZE-1 downto 0);
                    c_imaginary :   out std_logic_vector(SIZE-1 downto 0));
    end component constants_generator;
    
    component mandelbrot_calculator is
        generic (   point_pos :     integer := 12; -- nombre de bits après la virgule
                    max_iter :      integer := 100;
                    SIZE :          integer := 16);
        port (
                    clk :           in  std_logic;
                    rst :           in  std_logic;
                    ready :         out std_logic;
                    start :         in  std_logic;
                    finished :      out std_logic;
                    c_real :        in  std_logic_vector(SIZE-1 downto 0);
                    c_imaginary :   in  std_logic_vector(SIZE-1 downto 0);
                    z_real :        out std_logic_vector(SIZE-1 downto 0);
                    z_imaginary :   out std_logic_vector(SIZE-1 downto 0);
                    iterations :    out std_logic_vector(SIZE-1 downto 0));
    end component mandelbrot_calculator;
    
    component blk_mem_iter is
        port (
            clka :  in  std_logic;
            wea :   in  std_logic_vector(0 DOWNTO 0);
            addra : in  std_logic_vector(19 DOWNTO 0);
            dina :  in  std_logic_vector(7 DOWNTO 0);
            clkb :  in  std_logic;
            addrb : in  std_logic_vector(19 DOWNTO 0);
            doutb : out std_logic_vector(7 DOWNTO 0));
    end component blk_mem_iter;

    signal sti_clk :            std_logic := '0';
    signal sti_hdmi_clk :       std_logic := '0';
    signal sti_rst :            std_logic;
    
    signal obs_screen_x :       std_logic_vector(9 downto 0);
    signal obs_screen_y :       std_logic_vector(9 downto 0);
    
    signal s_ready_cal :        std_logic;
    signal s_start_cal :        std_logic;
    signal s_c_real_cal :       std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal s_c_imaginary_cal :  std_logic_vector(VECTOR_SIZE-1 downto 0);
    
    signal obs_finished :       std_logic;
    signal obs_z_real :         std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_z_imaginary :    std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_iterations :     std_logic_vector(VECTOR_SIZE-1 downto 0);
    
    signal s_screen_in :        std_logic_vector(19 downto 0);
    signal sti_screen_out :     std_logic_vector(19 downto 0);
    
    signal obs_bram_out :       std_logic_vector(7 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Clock Simulation
    ---------------------------------------------------------------------------
    SimClk :
    sti_clk <= not sti_clk after (CLK_PERIOD / 2);
    SimHdmiClk :
    sti_hdmi_clk <= not sti_hdmi_clk after (CLK_HDMI_PERIOD / 2);
    
    ---------------------------------------------------------------------------
    -- Constants Generator
    ---------------------------------------------------------------------------
    ConstantsGenerator :
    entity work.constants_generator
        generic map (
            point_pos   => POINT_POSITION,
            SIZE        => VECTOR_SIZE)
        port map (
            clk         => sti_clk,
            rst         => sti_rst,
            ready       => s_ready_cal,
            finished    => s_start_cal,
            screen_x    => obs_screen_x,
            screen_y    => obs_screen_y,
            c_real      => s_c_real_cal,
            c_imaginary => s_c_imaginary_cal);
            
    ---------------------------------------------------------------------------
    -- Mandelbrot Calculator
    ---------------------------------------------------------------------------
    MandelbrotCalculator :
    entity work.mandelbrot_calculator
        generic map (
            point_pos   => POINT_POSITION,
            max_iter    => MAX_ITERATION,
            SIZE        => VECTOR_SIZE)
        port map (
            clk         => sti_clk,
            rst         => sti_rst,
            ready       => s_ready_cal,
            start       => s_start_cal,
            finished    => obs_finished,
            c_real      => s_c_real_cal,
            c_imaginary => s_c_imaginary_cal,
            z_real      => obs_z_real,
            z_imaginary => obs_z_imaginary,
            iterations  => obs_iterations);
            
    ---------------------------------------------------------------------------
    -- BRAM used to store mandelbrot_calculator results
    ---------------------------------------------------------------------------
    Bram_iteration : blk_mem_iter
        port map (
            clka    => sti_clk,
            wea(0)  => obs_finished,
            addra   => s_screen_in,
            dina    => obs_iterations(7 downto 0),
            clkb    => sti_hdmi_clk,
            addrb   => sti_screen_out,
            doutb   => obs_bram_out);
            
    ---------------------------------------------------------------------------
    -- Mandelbrot Simulation
    ---------------------------------------------------------------------------
    MandelbrotSimulation : 
    process is
        variable screen_x : integer := 0;
        variable screen_y : integer := 0;
    begin
    
        -- Reset
        wait until rising_edge(sti_clk);
        sti_rst <= '1';
        
        -- Apply stimulus
        wait until rising_edge(sti_clk);
        sti_rst <= '0';
        
        -- Generate all coordonates of the display
        while screen_y < 600 loop
            
            wait until falling_edge(obs_finished);
            
            wait until rising_edge(sti_hdmi_clk);
                
                -- Compute address
                sti_screen_out <= std_logic_vector(to_unsigned(screen_y, 10)) & std_logic_vector(to_unsigned(screen_x, 10));
                
                -- Check address value
                if screen_x < 1023 then
                
                    screen_x := screen_x + 1;
                else
                
                    screen_x := 0;
                    
                    if screen_y < 600 then
                    
                        screen_y := screen_y + 1;
                    else
                        screen_y := 0;
                    end if;
                end if;
                
                -- Reading
                wait until rising_edge(sti_hdmi_clk);
                
                -- next iteration
        end loop;

        wait;
    end process MandelbrotSimulation;
    
    -- Address building
    s_screen_in <= obs_screen_y & obs_screen_x;

end testbench;
