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

    subtype bus_elem is std_logic_vector(SIZE-1 DOWNTO 0);
    -- TODO use that to store temporary data 
    signal  c_real_table :      bus_elem(1 to NB_CALC);
    signal  c_imag_table :      bus_elem(1 to NB_CALC);
    signal  iterations_table :  bus_elem(1 to NB_CALC);

begin


end Behavioral;
