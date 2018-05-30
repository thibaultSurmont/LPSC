----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.05.2018 20:16:59
-- Design Name: 
-- Module Name: mse_mandelbrot_Z - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.hdmi_interface_pkg.all;


entity mse_mandelbrot_Z is

    generic (
        C_CHANNEL_NUMBER : integer := 4);

    port (
        ClkSys100MhzxC : in    std_logic;
        RstxR          : in    std_logic;
        -- HDMI
        HdmiTxRsclxSO  : out   std_logic;
        HdmiTxRsdaxSIO : inout std_logic;
        HdmiTxHpdxSI   : in    std_logic;
        HdmiTxCecxSIO  : inout std_logic;
        HdmiTxClkPxSO  : out   std_logic;
        HdmiTxClkNxSO  : out   std_logic;
        HdmiTxPxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0);
        HdmiTxNxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0);
        -- Btns
        btnu           : in    std_logic;
        btnl           : in    std_logic;
        btnd           : in    std_logic;
        btnr           : in    std_logic;
        btnc           : in    std_logic);
        
end mse_mandelbrot_Z;

architecture rtl of mse_mandelbrot_Z is

    ---------------------------------------------------------------------------
    -- Resolution configuration
    ---------------------------------------------------------------------------
    -- Possible resolutions
    --
    -- 1024x768
    -- 1024x600
    -- 800x600
    -- 640x480

    -- constant C_VGA_CONFIG : t_VgaConfig := C_1024x768_VGACONFIG;
    constant C_VGA_CONFIG : t_VgaConfig := C_1024x600_VGACONFIG;
    -- constant C_VGA_CONFIG : t_VgaConfig := C_800x600_VGACONFIG;
    -- constant C_VGA_CONFIG : t_VgaConfig := C_640x480_VGACONFIG;

    -- constant C_RESOLUTION : string := "1024x768";
    constant C_RESOLUTION : string := "1024x600";
    -- constant C_RESOLUTION : string := "800x600";
    -- constant C_RESOLUTION : string := "640x480";
    ---------------------------------------------------------------------------
    -- 
    ---------------------------------------------------------------------------

    constant C_DATA_SIZE                        : integer := 20;
    constant C_PIXEL_SIZE                       : integer := 8;
    constant C_BRAM_VIDEO_MEMORY_ADDR_SIZE      : integer := 20;
    constant C_BRAM_VIDEO_MEMORY_HIGH_ADDR_SIZE : integer := 10;
    constant C_BRAM_VIDEO_MEMORY_LOW_ADDR_SIZE  : integer := 10;
    constant C_BRAM_VIDEO_MEMORY_DATA_SIZE      : integer := 9;
    
    constant C_POINT_POS                        : integer := 14;
    constant C_MAX_ITER                         : integer := 100;
    
    constant NB_CALCULATORS                     : integer := 16;

    component hdmi is
        generic (
            C_CHANNEL_NUMBER : integer;
            C_DATA_SIZE      : integer;
            C_PIXEL_SIZE     : integer;
            C_VGA_CONFIG     : t_VgaConfig;
            C_RESOLUTION     : string);
        port (
            ClkSys100MhzxC : in    std_logic;
            RstxR          : in    std_logic;
            PllLockedxSO   : out   std_logic;
            ClkVgaxCO      : out   std_logic;
            HCountxDO      : out   std_logic_vector((C_DATA_SIZE - 1) downto 0);
            VCountxDO      : out   std_logic_vector((C_DATA_SIZE - 1) downto 0);
            VidOnxSO       : out   std_logic;
            DataxDI        : in    std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0);
            HdmiTxRsclxSO  : out   std_logic;
            HdmiTxRsdaxSIO : inout std_logic;
            HdmiTxHpdxSI   : in    std_logic;
            HdmiTxCecxSIO  : inout std_logic;
            HdmiTxClkPxSO  : out   std_logic;
            HdmiTxClkNxSO  : out   std_logic;
            HdmiTxPxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0);
            HdmiTxNxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0));
    end component hdmi;
    
    component blk_mem_iter is
        port (
            clka :  IN STD_LOGIC;
            wea :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
            dina :  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb :  IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    end component blk_mem_iter;
        
    component mandelbrot_calculator_Z is
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
    end component mandelbrot_calculator_Z;
        
    component CalculatorsDispatcherZ is
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
                        iter_valid :        in  std_logic_vector(NB_CALC-1 downto 0);
                        ack_calc :          out std_logic_vector(NB_CALC-1 downto 0);
                        -- BRAM interface
                        addr :          out std_logic_vector(19 downto 0);
                        data_valid :    out std_logic);
    end component CalculatorsDispatcherZ;
    
    component ConstantsGenerator_Zoom is
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
                    c_imaginary :   out std_logic_vector(SIZE-1 downto 0);
                    up :            in  std_logic;
                    left :          in  std_logic;
                    down :          in  std_logic;
                    right :         in  std_logic;
                    zoom :          in  std_logic);
    end component ConstantsGenerator_Zoom;

    -- Pll Locked
    signal PllLockedxS    : std_logic                                           := '0';
    signal RstPllLockedxS : std_logic                                           := '0';
    -- Clocks
    signal ClkVgaxC       : std_logic                                           := '0';
    -- VGA
    signal HCountxD       : std_logic_vector((C_DATA_SIZE - 1) downto 0)        := (others => '0');
    signal VCountxD       : std_logic_vector((C_DATA_SIZE - 1) downto 0)        := (others => '0');
    signal VidOnxS        : std_logic                                           := '0';
    -- Others
    signal DataxD         : std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0) := (others => '0');
    signal HdmiSourcexD   : t_HdmiSource                                        := C_NO_HDMI_SOURCE;
    
    signal s_rst :            std_logic;
    
    -- Constants generator interface
    signal s_next_cst :       std_logic;
    signal s_x_in :           std_logic_vector(9 downto 0);
    signal s_y_in :           std_logic_vector(9 downto 0);
    signal s_c_real :         std_logic_vector(C_DATA_SIZE-1 downto 0);
    signal s_c_imag :         std_logic_vector(C_DATA_SIZE-1 downto 0);
    signal s_cst_valid :      std_logic;
    -- Mandelbrot calculator interface
    signal s_calc_ready :     std_logic_vector(NB_CALCULATORS-1 downto 0);
    signal s_start_calc :     std_logic_vector(NB_CALCULATORS-1 downto 0);
    signal s_iterations_bus : std_logic_vector(C_DATA_SIZE-1 downto 0);
    signal s_iter_valid :     std_logic_vector(NB_CALCULATORS-1 downto 0);
    signal s_ack_calc :       std_logic_vector(NB_CALCULATORS-1 downto 0);
    -- BRAM interface
    signal s_addr :           std_logic_vector(19 downto 0);
    signal s_data_valid :     std_logic;
    signal s_addr_out :       std_logic_vector(19 downto 0);
    signal s_data_out :       std_logic_vector(7 downto 0);

    -- Debug signals

    -- attribute mark_debug                               : string;
    -- attribute mark_debug of HCountxD                   : signal is "true";
    -- attribute mark_debug of VCountxD                   : signal is "true";
    -- attribute mark_debug of DataImGen2BramMVxD         : signal is "true";
    -- attribute mark_debug of DataBramMV2HdmixD          : signal is "true";
    -- attribute mark_debug of BramVideoMemoryWriteAddrxD : signal is "true";
    -- attribute mark_debug of BramVideoMemoryReadAddrxD  : signal is "true";
    -- attribute mark_debug of BramVideoMemoryWriteDataxD : signal is "true";
    -- attribute mark_debug of BramVideoMemoryReadDataxD  : signal is "true";

    -- attribute keep                               : string;
    -- attribute keep of HCountxD                   : signal is "true";
    -- attribute keep of VCountxD                   : signal is "true";
    -- attribute keep of DataImGen2BramMVxD         : signal is "true";
    -- attribute keep of DataBramMV2HdmixD          : signal is "true";
    -- attribute keep of BramVideoMemoryWriteAddrxD : signal is "true";
    -- attribute keep of BramVideoMemoryReadAddrxD  : signal is "true";
    -- attribute keep of BramVideoMemoryWriteDataxD : signal is "true";
    -- attribute keep of BramVideoMemoryReadDataxD  : signal is "true";

begin  -- architecture rtl

    s_rst <= not RstxR;
    
    -- Asynchronous statements

    assert ((C_VGA_CONFIG = C_640x480_VGACONFIG) and (C_RESOLUTION = "640x480"))
        or ((C_VGA_CONFIG = C_800x600_VGACONFIG) and (C_RESOLUTION = "800x600"))
        or ((C_VGA_CONFIG = C_1024x600_VGACONFIG) and (C_RESOLUTION = "1024x600"))
        or ((C_VGA_CONFIG = C_1024x768_VGACONFIG) and (C_RESOLUTION = "1024x768"))
        report "Not supported resolution!" severity failure;

    HdmiSourceOutxB : block is
    begin  -- block HdmiSourceOutxB

        HdmiTxRsclxAS : HdmiTxRsclxSO                           <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxRsclxS;
        HdmiTxRsdaxAS : HdmiTxRsdaxSIO                          <= HdmiSourcexD.HdmiSourceInOutxS.HdmiTxRsdaxS;
        HdmiTxHpdxAS  : HdmiSourcexD.HdmiSourceInxS.HdmiTxHpdxS <= HdmiTxHpdxSI;
        HdmiTxCecxAS  : HdmiTxCecxSIO                           <= HdmiSourcexD.HdmiSourceInOutxS.HdmiTxCecxS;
        HdmiTxClkPxAS : HdmiTxClkPxSO                           <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkPxS;
        HdmiTxClkNxAS : HdmiTxClkNxSO                           <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkNxS;
        HdmiTxPxAS    : HdmiTxPxDO                              <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxPxD;
        HdmiTxNxAS    : HdmiTxNxDO                              <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxNxD;

    end block HdmiSourceOutxB;

    ---------------------------------------------------------------------------
    -- HDMI Interface
    ---------------------------------------------------------------------------
    HdmixI : entity work.hdmi
        generic map (
            C_CHANNEL_NUMBER => C_CHANNEL_NUMBER,
            C_DATA_SIZE      => C_DATA_SIZE,
            C_PIXEL_SIZE     => C_PIXEL_SIZE,
            C_VGA_CONFIG     => C_VGA_CONFIG,
            C_RESOLUTION     => C_RESOLUTION)
        port map (
            ClkSys100MhzxC => ClkSys100MhzxC,
            RstxR          => s_rst,
            PllLockedxSO   => PllLockedxS,
            ClkVgaxCO      => ClkVgaxC,
            HCountxDO      => HCountxD,
            VCountxDO      => VCountxD,
            VidOnxSO       => VidOnxS,
            DataxDI        => DataxD,
            HdmiTxRsclxSO  => HdmiSourcexD.HdmiSourceOutxD.HdmiTxRsclxS,
            HdmiTxRsdaxSIO => HdmiSourcexD.HdmiSourceInOutxS.HdmiTxRsdaxS,
            HdmiTxHpdxSI   => HdmiSourcexD.HdmiSourceInxS.HdmiTxHpdxS,
            HdmiTxCecxSIO  => HdmiSourcexD.HdmiSourceInOutxS.HdmiTxCecxS,
            HdmiTxClkPxSO  => HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkPxS,
            HdmiTxClkNxSO  => HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkNxS,
            HdmiTxPxDO     => HdmiSourcexD.HdmiSourceOutxD.HdmiTxPxD,
            HdmiTxNxDO     => HdmiSourcexD.HdmiSourceOutxD.HdmiTxNxD);

    RstPllLockedxB : block is
    begin  -- block RstPllLockedxB

        RstPllLockedxAS : RstPllLockedxS <= not PllLockedxS;

    end block RstPllLockedxB;

    ---------------------------------------------------------------------------
    -- BRAM used to store mandelbrot_calculator results
    ---------------------------------------------------------------------------
    Bram_iteration : blk_mem_iter
        port map (
            clka    => ClkSys100MhzxC,
            wea(0)  => s_data_valid,
            addra   => s_addr,
            dina    => s_iterations_bus(7 downto 0),
            clkb    => ClkVgaxC,
            addrb   => s_addr_out,
            doutb   => s_data_out);
    
    ---------------------------------------------------------------------------
    -- Mandelbrot Calculators
    ---------------------------------------------------------------------------
    GEN_MandelbrotCalculator: 
    for I in 0 to NB_CALCULATORS-1 generate
        MandelbrotCalculatorX :
        mandelbrot_calculator_Z
            generic map (
                point_pos   => C_POINT_POS,
                max_iter    => C_MAX_ITER,
                SIZE        => C_DATA_SIZE)
            port map (
                clk         => ClkSys100MhzxC,
                rst         => s_rst,
                ready       => s_calc_ready(I),
                start       => s_start_calc(I),
                finished    => s_iter_valid(I),
                ack         => s_ack_calc(I),
                c_real      => s_c_real,
                c_imaginary => s_c_imag,
                z_real      => open,
                z_imaginary => open,
                iterations  => s_iterations_bus);
    end generate GEN_MandelbrotCalculator;
            
    ---------------------------------------------------------------------------
    -- Dispatcher
    ---------------------------------------------------------------------------
    CalculatorsDispatcher :
    entity work.CalculatorsDispatcherZ
        generic map (
            SIZE            => C_DATA_SIZE,
            NB_CALC         => NB_CALCULATORS)
        port map (
            clk             => ClkSys100MhzxC,
            rst             => s_rst,
            -- Constants generator interface
            next_cst        => s_next_cst,
            x_in            => s_x_in,
            y_in            => s_y_in,
            cst_valid       => s_cst_valid,
            -- Mandelbrot calculator interface
            calc_ready      => s_calc_ready,
            start_calc      => s_start_calc,
            iter_valid      => s_iter_valid,
            ack_calc        => s_ack_calc,
            -- BRAM interface
            addr            => s_addr,
            data_valid      => s_data_valid);
            
    ---------------------------------------------------------------------------
    -- Constants Generator
    ---------------------------------------------------------------------------
    ConstantsGenerator : entity work.ConstantsGenerator_Zoom
        generic map (
            point_pos   => C_POINT_POS,
            SIZE        => C_DATA_SIZE)
        port map (
            clk         => ClkSys100MhzxC,
            rst         => s_rst,
            ready       => s_next_cst,
            finished    => s_cst_valid,
            screen_x    => s_x_in,
            screen_y    => s_y_in,
            c_real      => s_c_real,
            c_imaginary => s_c_imag,
            up          => btnu,
            left        => btnl,
            down        => btnd,
            right       => btnr,
            zoom        => btnc);
            
    s_addr_out  <=  VCountxD(9 downto 0) & HCountxD(9 downto 0);
            
    DataxD      <=  s_data_out(6 downto 0) & '0' &
                    s_data_out(6 downto 0) & '0' &
                    s_data_out(6 downto 0) & '0' when s_data_out < X"1F" else
                    s_data_out &
                    X"1E" &
                    s_data_out when s_data_out < X"3F" else
                    s_data_out &
                    X"1E" &
                    X"3E"; 

end architecture rtl;
