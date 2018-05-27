----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.05.2018 18:15:33
-- Design Name: 
-- Module Name: CalculatorsDispatcherZ - Behavioral
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

entity CalculatorsDispatcherZ is
    generic (   SIZE :          integer := 16;
                NB_CALC :       integer := 2);
    port (
                clk :           in  std_logic;
                rst :           in  std_logic;
                -- Constants generator interface
                next_cst :      out std_logic;
                x_in :          in  std_logic_vector(9 downto 0);
                y_in :          in  std_logic_vector(9 downto 0);
                --c_real_in :     in  std_logic_vector(SIZE-1 downto 0);
                --c_imag_in :     in  std_logic_vector(SIZE-1 downto 0);
                cst_valid :     in  std_logic;
                -- Mandelbrot calculator interface
                calc_ready :        in  std_logic_vector(NB_CALC-1 downto 0);
                start_calc :        out std_logic_vector(NB_CALC-1 downto 0);
                iter_valid :        in  std_logic_vector(NB_CALC-1 downto 0);
                ack_calc :          out std_logic_vector(NB_CALC-1 downto 0);
                -- BRAM interface
                addr :          out std_logic_vector(19 downto 0);
                data_valid :    out std_logic);
end CalculatorsDispatcherZ;

architecture Behavioral of CalculatorsDispatcherZ is
    
    -- Build an array to manage addresses for BRAM
    type addresses_table is array (NB_CALC-1 downto 0) of std_logic_vector(addr'length-1 DOWNTO 0);
    signal  addr_table : addresses_table;
    
    
    -- Build enumerated types for the state machines
    type input_state_type is (RESET_STATE, WAIT_STATE, START_STATE);
    type output_state_type is (RESET_STATE, WAIT_STATE, ACK_STATE);
    -- Registers to hold the current states
    signal input_state : input_state_type;
    signal output_state : output_state_type;

begin   
    
    ---------------------------------------------------------------------------
    -- Moore state machines
    ---------------------------------------------------------------------------
    Input_state_machine:
    process (clk, rst)
        variable calc_inst : integer range 0 to NB_CALC-1;
    begin
        if rst = '1' then
            input_state <= RESET_STATE;
        elsif (rising_edge(clk)) then
            -- Determine the next state synchronously, based on
            -- the current state and the input
            case input_state is
                when RESET_STATE =>
                    next_cst    <= '0';
                    start_calc  <= (others=>'0');
                             
                    -- Change state
                    input_state <= WAIT_STATE;
                    
                when WAIT_STATE =>
                    -- Clear start_calc signal
                    start_calc  <= (others=>'0');
                    -- Check if at least one calculator is ready
                    for i in 0 to NB_CALC-1 loop
                    
                        if calc_ready(i) = '1' then    
                            -- Save calculator which is ready
                            calc_inst := i;
                            -- Request constant
                            next_cst <= '1';    
                                             
                            -- Change state
                            input_state <= START_STATE;
                            -- Exit loop
                            exit;
                        end if;
                        
                    end loop;
                    
                when START_STATE =>
                    -- Clear next_cst signal
                    next_cst <= '0';
                    
                    -- If new constant is valid
                    if cst_valid = '1' then
                        -- Save new addresse
                        addr_table(calc_inst) <= y_in & x_in;
                        -- Start calculator
                        start_calc(calc_inst) <= '1';
                    -- If calculator has started
                    elsif calc_ready(calc_inst) = '0' then
                        
                        -- Change state
                        input_state <= WAIT_STATE;
                    end if;
            end case;
        end if;
    end process;
    
    Output_state_machine:
    process (clk, rst)
        variable calc_inst : integer range 0 to NB_CALC-1;
    begin
        if rst = '1' then
            output_state <= RESET_STATE;
        elsif (rising_edge(clk)) then
            -- Determine the next state synchronously, based on
            -- the current state and the input
            case output_state is
                when RESET_STATE =>
                    ack_calc    <= (others=>'0');   
                    data_valid  <= '0'; 
                         
                    -- Change state
                    output_state <= WAIT_STATE;
                    
                when WAIT_STATE =>   
                    -- Clear ack_calc signal
                    ack_calc  <= (others=>'0'); 
                    -- Check if at least one calculator is ready
                    for i in 0 to NB_CALC-1 loop
                    
                        if iter_valid(i) = '1' then    
                            -- Save calculator which has finished
                            calc_inst       := i;
                            -- Write data in BRAM
                            addr            <= addr_table(calc_inst);
                            data_valid      <= '1';
                            -- ACK calculator result
                            ack_calc(calc_inst) <= '1';  
                                            
                            -- Change state
                            output_state <= ACK_STATE;
                            -- Exit loop        
                            exit;
                        end if;
                        
                    end loop;                                       
                    
                when ACK_STATE =>
                    -- "data_valid" is cleared
                    data_valid      <= '0';
                    -- "ack_calc" is cleared
                    ack_calc(calc_inst) <= '0';
                    
                    -- Change state
                    output_state <= WAIT_STATE;
            end case;
        end if;
    end process;


end Behavioral;
