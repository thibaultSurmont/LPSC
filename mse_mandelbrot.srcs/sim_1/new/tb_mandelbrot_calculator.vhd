----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.04.2018 12:10:36
-- Design Name: 
-- Module Name: tb_mandelbrot_calculator - Behavioral
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

entity tb_mandelbrot_calculator is
--  Port ( );
end tb_mandelbrot_calculator;

architecture testbench of tb_mandelbrot_calculator is

    constant CLK_PERIOD :       time := 10 ns;

    constant POINT_POSITION :   integer := 12;
    constant MAX_ITERATION :    integer := 100;
    constant VECTOR_SIZE :      integer := 16;
    
    constant C_REAL :       std_logic_vector(VECTOR_SIZE-1 downto 0) := X"05FF";
    constant C_IMAGINARY :  std_logic_vector(VECTOR_SIZE-1 downto 0) := X"05FF";
    
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

    signal sti_clk :            std_logic := '0';
    signal sti_rst :            std_logic;
    signal obs_ready :          std_logic;
    signal sti_start :          std_logic;
    signal obs_finished :       std_logic;
    signal sti_c_real :         std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal sti_c_imaginary :    std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_z_real :         std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_z_imaginary :    std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_iterations :     std_logic_vector(VECTOR_SIZE-1 downto 0);
    
begin

    ---------------------------------------------------------------------------
    -- Clock Simulation
    ---------------------------------------------------------------------------
    SimClk :
    sti_clk <= not sti_clk after (CLK_PERIOD / 2);
    
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
            ready       => obs_ready,
            start       => sti_start,
            finished    => obs_finished,
            c_real      => sti_c_real,
            c_imaginary => sti_c_imaginary,
            z_real      => obs_z_real,
            z_imaginary => obs_z_imaginary,
            iterations  => obs_iterations);
            
    ---------------------------------------------------------------------------
    -- Mandelbrot Calculator Simulation
    ---------------------------------------------------------------------------
    MandelbrotCalculatorSimulation : 
    process is
    begin
    
        -- Reset
        wait until rising_edge(sti_clk);
        sti_rst <= '1';
        sti_start <= '0';
        
        -- Apply stimulus
        wait until rising_edge(sti_clk);
        sti_rst <= '0';
        sti_c_real <= C_REAL;
        sti_c_imaginary <= C_IMAGINARY;
        
        -- Wait for calcultaor is ready to start computation
        wait until obs_ready = '1' and rising_edge(sti_clk);
        sti_start <= '1';
        
        -- Wait for next rising edge to clear start signal
        wait until rising_edge(sti_clk);
        sti_start <= '0';
        
        -- Wait for termination of the computation
        wait until obs_finished = '1' and rising_edge(sti_clk);

        wait;
    end process MandelbrotCalculatorSimulation;
            
end architecture testbench;
