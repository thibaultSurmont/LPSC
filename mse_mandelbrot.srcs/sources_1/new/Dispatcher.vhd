----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.05.2018 10:27:55
-- Design Name: 
-- Module Name: Dispatcher - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Dispatcher is
    generic (   SIZE :          integer := 16;
                NB_CALC :       integer := 2);
    port (
                clk :           in  std_logic;
                rst :           in  std_logic;
                -- Constants generator interface
                next_cst :      out std_logic;
                x_in :          in  std_logic_vector(9 downto 0);
                y_in :          in  std_logic_vector(9 downto 0);
                c_real_in :     in  std_logic_vector(SIZE-1 downto 0);
                c_imag_in :     in  std_logic_vector(SIZE-1 downto 0);
                cst_valid :     in  std_logic;
                -- Mandelbrot calculator interface
                calc_ready :        in  std_logic_vector(NB_CALC-1 downto 0);
                start_calc :        out std_logic_vector(NB_CALC-1 downto 0);
                c_real_out_bus :    out std_logic_vector(NB_CALC*SIZE-1 downto 0);
                c_imag_out_bus :    out std_logic_vector(NB_CALC*SIZE-1 downto 0);
                iterations_bus :    in  std_logic_vector(NB_CALC*SIZE-1 downto 0);
                iter_valid :        in  std_logic_vector(NB_CALC-1 downto 0);
                -- BRAM interface
                addr :          out std_logic_vector(19 downto 0);
                data :          out std_logic_vector(23 downto 0);
                data_valid :    out std_logic);
end Dispatcher;

architecture Behavioral of Dispatcher is

    -- Build a subtype to manage calculators' signals
    subtype bus_elem is std_logic_vector(SIZE-1 DOWNTO 0);
    signal  c_real_table :      bus_elem(1 to NB_CALC);
    signal  c_imag_table :      bus_elem(1 to NB_CALC);
    signal  iterations_table :  bus_elem(1 to NB_CALC);
    
    -- Build enumerated types for the state machines
    type input_state_type is (RESET_STATE, WAIT_STATE, REQUEST_STATE, APPLY_STATE);
    type output_state_type is (RESET_STATE, WAIT_STATE, STORE_STATE, ACK_STATE);
    -- Registers to hold the current states
    signal input_state : input_state_type;
    signal output_state : output_state_type;

begin

    ---------------------------------------------------------------------------
    -- Moore state machines
    ---------------------------------------------------------------------------
    Input_state_machine:
    process (clk, rst)
    begin
        if rst = '1' then
            input_state <= RESET_STATE;
        elsif (rising_edge(clk)) then
            -- Determine the next state synchronously, based on
            -- the current state and the input
            case input_state is
                when RESET_STATE =>         
                    -- Change state
                    input_state <= WAIT_STATE;
                    
                when WAIT_STATE =>                                           
                    -- Change state
                    input_state <= REQUEST_STATE;
                    
                when REQUEST_STATE =>
                    -- Change state
                    input_state <= APPLY_STATE;
                    
                when APPLY_STATE =>                        
                    -- Change state
                    input_state <= WAIT_STATE;
            end case;
        end if;
    end process;
    
    Output_state_machine:
    process (clk, rst)
    begin
        if rst = '1' then
            output_state <= RESET_STATE;
        elsif (rising_edge(clk)) then
            -- Determine the next state synchronously, based on
            -- the current state and the input
            case output_state is
                when RESET_STATE =>         
                    -- Change state
                    output_state <= WAIT_STATE;
                    
                when WAIT_STATE =>                                           
                    -- Change state
                    output_state <= STORE_STATE;
                    
                when STORE_STATE =>
                    -- Change state
                    output_state <= ACK_STATE;
                    
                when ACK_STATE =>                        
                    -- Change state
                    output_state <= WAIT_STATE;
            end case;
        end if;
    end process;


end Behavioral;
