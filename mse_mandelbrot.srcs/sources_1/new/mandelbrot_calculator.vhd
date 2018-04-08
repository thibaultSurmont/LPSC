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
end mandelbrot_calculator;

architecture Behavioral of mandelbrot_calculator is
    
    function mult (val1, val2 : std_logic_vector; vector_size, fix_point_pos : integer) return std_logic_vector is
    
        variable mult : std_logic_vector(vector_size*2-1 downto 0);
        variable lsb :  integer := fix_point_pos;
        variable msb :  integer := vector_size-1 + fix_point_pos;
        
    begin
    
        mult := std_logic_vector(unsigned(val1)*unsigned(val2));
        return mult(msb downto lsb);
    end mult;
    
    function square (val : std_logic_vector; vector_size, fix_point_pos : integer) return std_logic_vector is
    begin
    
        return mult(val, val, vector_size, fix_point_pos);
    end square;
    
    function int2stdLogicVector (int, length : integer) return std_logic_vector is
    begin
    
        return std_logic_vector(to_unsigned(int, length));
    end int2stdLogicVector;
    
    -- Build an enumerated type for the state machine
    type state_type is (RESET_STATE, READY_STATE, COMPUTE_STATE, FINISH_STATE);
    -- Register to hold the current state
    signal state : state_type;
    
    -- Instatiation of counter
    component generic_counter is
        generic (   SIZE :          integer := 16);
        port (
                    clk :           in  std_logic;
                    rst :           in  std_logic;
                    en :            in  std_logic;
                    clr :           in  std_logic;
                    counter :       out std_logic_vector(SIZE-1 downto 0));
    end component generic_counter;
    -- Counter signals
    signal s_counter :  std_logic_vector(SIZE-1 downto 0);
    
    -- Instatiation of register
    component generic_register is
        generic(    SIZE :          integer := 16);
        port(
                    clk :           in  std_logic;
                    rst :           in  std_logic;
                    en :            in  std_logic;
                    clr :           in  std_logic;
                    data_in :       in  std_logic_vector(SIZE-1 downto 0);
                    data_out :      out std_logic_vector(SIZE-1 downto 0));
    end component generic_register;
    
    -- Enable & Clear signals for counter and registers
    signal s_en :       std_logic;
    signal s_clr :      std_logic;
    
    -- Computation signals
    signal s_real_reg_in :          std_logic_vector(SIZE-1 downto 0);
    signal s_imaginary_reg_in :     std_logic_vector(SIZE-1 downto 0);
    signal s_real2 :                std_logic_vector(SIZE-1 downto 0);
    signal s_imaginary2 :           std_logic_vector(SIZE-1 downto 0);
    signal s_2mult :                std_logic_vector(SIZE-1 downto 0);
    signal s_real_reg_out :         std_logic_vector(SIZE-1 downto 0);
    signal s_imaginary_reg_out :    std_logic_vector(SIZE-1 downto 0);
    
begin

    ---------------------------------------------------------------------------
    -- Iteration counter
    ---------------------------------------------------------------------------
    IterationCounter : entity work.generic_counter
        generic map (
            SIZE => SIZE)
        port map (
            clk     => clk,
            rst     => rst,
            en     => s_en,
            clr     => s_clr,
            counter => s_counter);
            
    ---------------------------------------------------------------------------
    -- Real register
    ---------------------------------------------------------------------------
    RealRegister : entity work.generic_register
        generic map (
            SIZE => SIZE)
        port map (
            clk         => clk,
            rst         => rst,
            en          => s_en,
            clr         => s_clr,
            data_in     => s_real_reg_in,
            data_out    => s_real_reg_out);
            
    ---------------------------------------------------------------------------
    -- Real register
    ---------------------------------------------------------------------------
    ImaginaryRegister : entity work.generic_register
        generic map (
            SIZE => SIZE)
        port map (
            clk         => clk,
            rst         => rst,
            en          => s_en,
            clr         => s_clr,
            data_in     => s_imaginary_reg_in,
            data_out    => s_imaginary_reg_out);
            
    ---------------------------------------------------------------------------
    -- Control signals
    ---------------------------------------------------------------------------
            
            
    ---------------------------------------------------------------------------
    -- Computation block
    ---------------------------------------------------------------------------
    s_real2             <= square(s_real_reg_out, SIZE, point_pos);
    s_imaginary2        <= square(s_imaginary_reg_out, SIZE, point_pos);
    s_real_reg_in       <= std_logic_vector(unsigned(s_real2) - unsigned(s_imaginary2) + unsigned(c_real));
    s_2mult             <= std_logic_vector(unsigned(mult(s_real_reg_out, s_imaginary_reg_out, SIZE, point_pos)) sll 1);
    s_imaginary_reg_in  <= std_logic_vector(unsigned(s_2mult) + unsigned(c_imaginary));
    -- Result of computation
    z_real      <= s_real_reg_out when state = COMPUTE_STATE;
    z_imaginary <= s_imaginary_reg_out when state = COMPUTE_STATE;
    
    ---------------------------------------------------------------------------
    -- Iterations counter
    ---------------------------------------------------------------------------
    iterations <=   s_counter       when state = COMPUTE_STATE else
                    (others=>'0')   when s_counter > int2stdLogicVector(max_iter, s_counter'length);
    
    ---------------------------------------------------------------------------
    -- Mealy state machine
    ---------------------------------------------------------------------------
    Mealy_state_machine_sync:
	process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET_STATE;
        elsif (rising_edge(clk)) then
            -- Determine the next state synchronously, based on
            -- the current state and the input
            case state is
                when RESET_STATE =>
                    state <= READY_STATE;
                when READY_STATE =>
                    if start = '1' then
                        state <= COMPUTE_STATE;
                    else
                        state <= READY_STATE;
                    end if;
                when COMPUTE_STATE =>
                    -- Check counter limit
                    if s_counter > int2stdLogicVector(max_iter, s_counter'length) then
                        state <= FINISH_STATE;
                    -- Compare Zr² + Zi² > 4
                    elsif (unsigned(s_real2) + unsigned(s_imaginary2)) > (to_unsigned(4, SIZE) sll 12)  then
                        state <= FINISH_STATE;
                    else
                        state <= COMPUTE_STATE;
                    end if;
                when FINISH_STATE =>
                    state <= READY_STATE;
            end case;
        end if;
    end process;
    
    Moore_state_machine_state_change:
    -- Determine the output based only on the current state
    process (state)
    begin
        case state is
            when RESET_STATE =>
                -- Nothing to do
            when READY_STATE =>
                -- All outputs and registers are cleared
                finished    <= '0';
                s_en        <= '0';
                s_clr       <= '0';
                -- ready set (waiting for start cmd)
                ready       <= '1';
            when COMPUTE_STATE =>
                -- ready cleared
                ready       <= '0';
                -- Counter & registers enabled
                s_en        <= '1';
            when FINISH_STATE =>
                -- finished set (result available)
                finished    <= '1';
                -- s_clr set (counter and registers cleared for next computation)
                s_clr       <= '1';
        end case;
    end process;

end Behavioral;
