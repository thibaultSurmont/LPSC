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
    
    constant NB_CALCULATORS :   integer := 4;
    
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
    
    component Dispatcher is
        generic (   SIZE :          integer := 16;
                    NB_CALC :       integer := 2);
        port (
                    clk :           in  std_logic;
                    rst :           in  std_logic;
                    -- Constants generator interface
                    next_cst :      out std_logic;
                    x_in :          in  std_logic_vector(9 downto 0);
                    y_in :          in  std_logic_vector(9 downto 0);
                    cst_valid :     in  std_logic;
                    -- Mandelbrot calculator interface
                    calc_ready :        in  std_logic_vector(NB_CALC-1 downto 0);
                    start_calc :        out std_logic_vector(NB_CALC-1 downto 0);
                    iterations_bus :    in  std_logic_vector(NB_CALC*SIZE-1 downto 0);
                    iter_valid :        in  std_logic_vector(NB_CALC-1 downto 0);
                    ack_calc :          out std_logic_vector(NB_CALC-1 downto 0);
                    -- BRAM interface
                    addr :          out std_logic_vector(19 downto 0);
                    data :          out std_logic_vector(7 downto 0);
                    data_valid :    out std_logic);
    end component Dispatcher;
    
    component MandelbrotCalculatorAck is
        generic (   point_pos :     integer := 12; -- nombre de bits après la virgule
                    max_iter :      integer := 100;
                    SIZE :          integer := 16);
        port (
                    clk :           in  std_logic;
                    rst :           in  std_logic;
                    ready :         out std_logic;
                    start :         in  std_logic;
                    finished :      out std_logic;
                    ack :           in  std_logic;
                    c_real :        in  std_logic_vector(SIZE-1 downto 0);
                    c_imaginary :   in  std_logic_vector(SIZE-1 downto 0);
                    z_real :        out std_logic_vector(SIZE-1 downto 0);
                    z_imaginary :   out std_logic_vector(SIZE-1 downto 0);
                    iterations :    out std_logic_vector(SIZE-1 downto 0));
    end component MandelbrotCalculatorAck;
    
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

    -- Stimulus
    signal sti_clk :            std_logic := '0';
    signal sti_hdmi_clk :       std_logic := '0';
    signal sti_rst :            std_logic;
    -- Constants generator interface
    signal obs_next_cst :       std_logic;
    signal obs_x_in :           std_logic_vector(9 downto 0);
    signal obs_y_in :           std_logic_vector(9 downto 0);
    signal obs_c_real :         std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_c_imag :         std_logic_vector(VECTOR_SIZE-1 downto 0);
    signal obs_cst_valid :      std_logic;
    -- Mandelbrot calculator interface
    signal obs_calc_ready :     std_logic_vector(NB_CALCULATORS-1 downto 0);
    signal obs_start_calc :     std_logic_vector(NB_CALCULATORS-1 downto 0);
    signal obs_iterations_bus : std_logic_vector(NB_CALCULATORS*VECTOR_SIZE-1 downto 0);
    signal obs_iter_valid :     std_logic_vector(NB_CALCULATORS-1 downto 0);
    signal obs_ack_calc :       std_logic_vector(NB_CALCULATORS-1 downto 0);
    -- BRAM interface
    signal obs_addr :           std_logic_vector(19 downto 0);
    signal obs_data :           std_logic_vector(7 downto 0);
    signal obs_data_valid :     std_logic;
    signal sti_addr_out :       std_logic_vector(19 downto 0);
    signal obs_data_out :       std_logic_vector(7 downto 0);
    
    function getSubBus (fullBus : in std_logic_vector; subBusSize : integer; index : integer) return std_logic_vector is
    begin
        return fullBus(subBusSize*index+subBusSize-1 downto subBusSize*index);
    end function;

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
            ready       => obs_next_cst,
            finished    => obs_cst_valid,
            screen_x    => obs_x_in,
            screen_y    => obs_y_in,
            c_real      => obs_c_real,
            c_imaginary => obs_c_imag);
            
    ---------------------------------------------------------------------------
    -- Constants Generator
    ---------------------------------------------------------------------------
    CalculatorsDispatcher :
    entity work.Dispatcher
        generic map (
            SIZE            => VECTOR_SIZE,
            NB_CALC         => NB_CALCULATORS)
        port map (
            clk             => sti_clk,
            rst             => sti_rst,
            -- Constants generator interface
            next_cst        => obs_next_cst,
            x_in            => obs_x_in,
            y_in            => obs_y_in,
            cst_valid       => obs_cst_valid,
            -- Mandelbrot calculator interface
            calc_ready      => obs_calc_ready,
            start_calc      => obs_start_calc,
            iterations_bus  => obs_iterations_bus,
            iter_valid      => obs_iter_valid,
            ack_calc        => obs_ack_calc,
            -- BRAM interface
            addr            => obs_addr,
            data            => obs_data,
            data_valid      => obs_data_valid);
            
    ---------------------------------------------------------------------------
    -- Mandelbrot Calculators
    ---------------------------------------------------------------------------
    GEN_MandelbrotCalculator: 
    for I in 0 to NB_CALCULATORS-1 generate
        MandelbrotCalculatorX :
        MandelbrotCalculatorAck
            generic map (
                point_pos   => POINT_POSITION,
                max_iter    => MAX_ITERATION,
                SIZE        => VECTOR_SIZE)
            port map (
                clk         => sti_clk,
                rst         => sti_rst,
                ready       => obs_calc_ready(I),
                start       => obs_start_calc(I),
                finished    => obs_iter_valid(I),
                ack         => obs_ack_calc(I),
                c_real      => obs_c_real,
                c_imaginary => obs_c_imag,
                z_real      => open,
                z_imaginary => open,
                iterations  => obs_iterations_bus(VECTOR_SIZE*I+VECTOR_SIZE-1 downto VECTOR_SIZE*I));
    end generate GEN_MandelbrotCalculator;
            
    ---------------------------------------------------------------------------
    -- BRAM used to store mandelbrot_calculator results
    ---------------------------------------------------------------------------
    Bram_iteration : blk_mem_iter
        port map (
            clka    => sti_clk,
            wea(0)  => obs_data_valid,
            addra   => obs_addr,
            dina    => obs_data,
            clkb    => sti_hdmi_clk,
            addrb   => sti_addr_out,
            doutb   => obs_data_out);
            
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
            
            wait until falling_edge(obs_data_valid);
            
            wait until rising_edge(sti_hdmi_clk);
                
                -- Compute address
                sti_addr_out <= std_logic_vector(to_unsigned(screen_y, 10)) & std_logic_vector(to_unsigned(screen_x, 10));
                
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

end testbench;
