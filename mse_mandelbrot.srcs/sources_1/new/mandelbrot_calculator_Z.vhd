----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.05.2018 17:58:10
-- Design Name: 
-- Module Name: mandelbrot_calculator_Z - Behavioral
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

entity mandelbrot_calculator_Z is
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
end mandelbrot_calculator_Z;

architecture Behavioral of mandelbrot_calculator_Z is
    
    function mult (val1, val2 : std_logic_vector; vector_size, fix_point_pos : integer) return std_logic_vector is
    
        variable mult : std_logic_vector(vector_size*2-1 downto 0);
        variable lsb :  integer := fix_point_pos;
        variable msb :  integer := vector_size-1 + fix_point_pos;
        
    begin
    
        mult := std_logic_vector(signed(val1)*signed(val2));
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
    
    signal s_iterations :           std_logic_vector(SIZE-1 downto 0);
    
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
    -- Computation block
    ---------------------------------------------------------------------------
    s_real2             <= square(s_real_reg_out, SIZE, point_pos);
    s_imaginary2        <= square(s_imaginary_reg_out, SIZE, point_pos);
    s_real_reg_in       <= std_logic_vector(signed(s_real2) - signed(s_imaginary2) + signed(c_real));
    s_2mult             <= std_logic_vector(signed(mult(s_real_reg_out, s_imaginary_reg_out, SIZE, point_pos)) sll 1);
    s_imaginary_reg_in  <= std_logic_vector(signed(s_2mult) + signed(c_imaginary));
    
    ---------------------------------------------------------------------------
    -- Moore state machine
    ---------------------------------------------------------------------------
    Moore_state_machine:
	process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET_STATE;
            -- ready cleared
            ready <= '0';
        elsif (rising_edge(clk)) then
            -- Determine the next state synchronously, based on
            -- the current state and the input
            case state is
                when RESET_STATE =>
                    -- All outputs and registers are cleared
                    finished    <= '0';
                    s_en        <= '0';
                    s_clr       <= '0';
                    -- ready set (waiting for start cmd)
                    ready       <= '1';
                    
                    -- Change state
                    state <= READY_STATE;
                    
                when READY_STATE =>                   
                    -- Start of operations
                    if start = '1' then
                        -- ready cleared
                        ready   <= '0';
                        -- Counter & registers enabled
                        s_en    <= '1';
                        
                        -- Change state
                        state <= COMPUTE_STATE;
                    end if;
                    
                when COMPUTE_STATE =>
                    -- Result of computation
                    z_real      <= s_real_reg_out;
                    z_imaginary <= s_imaginary_reg_out;
                    s_iterations  <=  s_counter;
                    
                    -- Check counter limit
                    if s_counter > int2stdLogicVector(max_iter, s_counter'length) then
                        -- Reset iterations
                        s_iterations <= (others=>'0');
                        -- finished set (result available)
                        finished    <= '1';
                        -- s_clr set (counter and registers cleared for next computation)
                        s_clr       <= '1';
                    
                        -- Change state
                        state <= FINISH_STATE;
                    -- Compare Zr² + Zi² > 4
                    elsif (unsigned(s_real2) + unsigned(s_imaginary2)) > (to_unsigned(4, SIZE) sll point_pos)  then
                        -- finished set (result available)
                        finished    <= '1';
                        -- s_clr set (counter and registers cleared for next computation)
                        s_clr       <= '1';
                    
                        -- Change state
                        state <= FINISH_STATE;
                    end if;
                    
                when FINISH_STATE =>
                    -- Registers are cleared
                    s_en    <= '0';
                    s_clr   <= '0';
                    
                    -- Check ACK
                    if ack = '1' then
                        -- finished cleared
                        finished    <= '0';
                        -- Ready set (waiting for start cmd)
                        ready       <= '1';
                        
                        -- Change state
                        state       <= READY_STATE;
                    end if;
            end case;
        end if;
    end process;
    
    -- High Z when not selected (ack)
    iterations <=   (others=>'Z') when ack = '0' else
                    s_iterations;

end Behavioral;