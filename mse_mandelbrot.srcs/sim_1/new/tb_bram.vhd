----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.04.2018 16:30:11
-- Design Name: 
-- Module Name: tb_bram - Behavioral
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

entity tb_bram is
--  Port ( );
end tb_bram;

architecture testbench of tb_bram is

    constant CLK_PERIOD :       time := 10 ns;
    constant CLK_HDMI_PERIOD :  time := 25 ns;

    constant POINT_POSITION :   integer := 12;
    constant MAX_ITERATION :    integer := 100;
    constant VECTOR_SIZE :      integer := 16;
    
    component blk_mem_iter is
        port (
            clka :  in  std_logic;
            ena :   in  std_logic;
            wea :   in  std_logic_vector(0 DOWNTO 0);
            addra : in  std_logic_vector(19 DOWNTO 0);
            dina :  in  std_logic_vector(7 DOWNTO 0);
            clkb :  in  std_logic;
            enb :   in  std_logic;
            addrb : in  std_logic_vector(19 DOWNTO 0);
            doutb : out std_logic_vector(7 DOWNTO 0));
    end component blk_mem_iter;

    signal sti_clk_a :          std_logic := '0';
    signal sti_clk_b :          std_logic := '0';
    signal sti_rst :            std_logic;
    
    signal sti_en_a :           std_logic := '0';
    signal sti_wr_a :           std_logic := '1';
    signal sti_addr_a :         std_logic_vector(19 downto 0);
    signal sti_in_a :           std_logic_vector(7 downto 0) := (others=>'0');
    
    signal sti_en_b :           std_logic := '0';
    signal sti_addr_b :         std_logic_vector(19 downto 0);
    signal sti_out_b :          std_logic_vector(7 downto 0);
    
begin

    ---------------------------------------------------------------------------
    -- Clock Simulation
    ---------------------------------------------------------------------------
    SimClk :
    sti_clk_a <= not sti_clk_a after (CLK_PERIOD / 2);
    SimHdmiClk :
    sti_clk_b <= not sti_clk_b after (CLK_HDMI_PERIOD / 2);
            
    ---------------------------------------------------------------------------
    -- BRAM simple dual port
    ---------------------------------------------------------------------------
    Bram_iteration : blk_mem_iter
        port map (
            clka    => sti_clk_a,
            ena     => sti_en_a,
            wea(0)  => sti_wr_a,
            addra   => sti_addr_a,
            dina    => sti_in_a,
            clkb    => sti_clk_b,
            enb     => sti_en_b,
            addrb   => sti_addr_b,
            doutb   => sti_out_b);
            
    ---------------------------------------------------------------------------
    -- BRAM Simulation
    ---------------------------------------------------------------------------
    Bram_Simulation : 
    process is
        variable addr_x_a : integer := 0;
        variable addr_y_a : integer := 0;
    begin
    
        while true loop
        
            -- Reset
            wait until rising_edge(sti_clk_a);
            sti_rst <= '1';
            
            -- Apply stimulus
            wait until rising_edge(sti_clk_a);
            sti_rst <= '0';
              
            -- Write in BRAM
            sti_addr_a  <= std_logic_vector(to_unsigned(addr_y_a, 10)) & std_logic_vector(to_unsigned(addr_x_a, 10));
            sti_in_a    <= sti_in_a xor X"FF";
            sti_en_a <= '1';
            
            -- Increment addresses
            if addr_x_a < 1023 then
                            
                addr_x_a := addr_x_a + 1;
            else
            
                addr_x_a := 0;
                
                if addr_y_a < 600 then
                
                    addr_y_a := addr_y_a + 1;
                else
                    addr_y_a := 0;
                end if;
            end if;
            
            wait until rising_edge(sti_clk_a);
            sti_en_a <= '0';
            
            -- Read BRAM
            wait until rising_edge(sti_clk_b);
            -- Update reading addresses
            sti_addr_b  <= sti_addr_a;
            sti_en_b <= '1';
            
            wait until rising_edge(sti_clk_b);
            sti_en_b <= '0';
            
        end loop;

        wait;
    end process Bram_Simulation;

end testbench;
