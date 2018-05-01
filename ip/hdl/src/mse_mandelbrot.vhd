-------------------------------------------------------------------------------
-- Title       : MSE Mandelbrot Top Level
-- Project     : MSE Mandelbrot
-------------------------------------------------------------------------------
-- File        : mse_mandelbrot.vhd
-- Authors     : Joachim Schmidt
-- Company     : Hepia
-- Created     : 26.02.2018
-- Last update : 26.02.2018
-- Platform    : Vivado (synthesis)
-- Standard    : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Hepia, Geneve
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 26.02.2018   0.0      SCJ      Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.hdmi_interface_pkg.all;

entity mse_mandelbrot is

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
        HdmiTxNxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0));

end entity mse_mandelbrot;

architecture rtl of mse_mandelbrot is

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

    constant C_DATA_SIZE                        : integer := 16;
    constant C_PIXEL_SIZE                       : integer := 8;
    constant C_BRAM_VIDEO_MEMORY_ADDR_SIZE      : integer := 20;
    constant C_BRAM_VIDEO_MEMORY_HIGH_ADDR_SIZE : integer := 10;
    constant C_BRAM_VIDEO_MEMORY_LOW_ADDR_SIZE  : integer := 10;
    constant C_BRAM_VIDEO_MEMORY_DATA_SIZE      : integer := 9;
    
    constant C_POINT_POS                        : integer := 12;
    constant C_MAX_ITER                         : integer := 100;

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
            ena :   IN STD_LOGIC;
            wea :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
            dina :  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb :  IN STD_LOGIC;
            enb :   IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    end component blk_mem_iter;

--    component image_generator is
--        generic (
--            C_DATA_SIZE  : integer;
--            C_PIXEL_SIZE : integer;
--            C_VGA_CONFIG : t_VgaConfig);
--        port (
--            ClkVgaxC     : in  std_logic;
--            RstxRA       : in  std_logic;
--            PllLockedxSI : in  std_logic;
--            HCountxDI    : in  std_logic_vector((C_DATA_SIZE - 1) downto 0);
--            VCountxDI    : in  std_logic_vector((C_DATA_SIZE - 1) downto 0);
--            VidOnxSI     : in  std_logic;
--            DataxDO      : out std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0));
--    end component image_generator;
    
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
    
    
    signal s_screen_x :         std_logic_vector(9 downto 0);
    signal s_screen_y :         std_logic_vector(9 downto 0);
    signal s_finished_cstGen :  std_logic;
    signal s_c_real :           std_logic_vector(C_DATA_SIZE-1 downto 0);
    signal s_c_imaginary :      std_logic_vector(C_DATA_SIZE-1 downto 0);
    
    signal s_ready_mndl_cal :   std_logic;
    signal s_finished_mndl_cal :std_logic;
    signal s_z_real :           std_logic_vector(C_DATA_SIZE-1 downto 0);
    signal s_z_imaginary :      std_logic_vector(C_DATA_SIZE-1 downto 0);
    signal s_iterations :       std_logic_vector(C_DATA_SIZE-1 downto 0);
    
    signal s_en_a_bram :        std_logic;
    signal s_output_bram :      std_logic_vector(7 downto 0);

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
            RstxR          => RstxR,
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
            ena     => s_en_a_bram,
            wea(0)  => s_finished_mndl_cal,
            addra   => s_screen_y & s_screen_x,
            dina    => s_iterations(7 downto 0),
            clkb    => ClkVgaxC,
            enb     => PllLockedxS, --VidOnxS,
            addrb   => VCountxD(9 downto 0) & HCountxD(9 downto 0),
            doutb   => s_output_bram);

--    ImageGeneratorxB : block is
--    begin  -- block ImageGeneratorxB

--    ---------------------------------------------------------------------------
--    -- Image generator example
--    ---------------------------------------------------------------------------
--    ImageGeneratorxI : entity work.image_generator
--        generic map (
--            C_DATA_SIZE  => C_DATA_SIZE,
--            C_PIXEL_SIZE => C_PIXEL_SIZE,
--            C_VGA_CONFIG => C_VGA_CONFIG)
--        port map (
--            ClkVgaxC     => ClkVgaxC,
--            RstxRA       => RstPllLockedxS,
--            PllLockedxSI => PllLockedxS,
--            HCountxDI    => HCountxD,
--            VCountxDI    => VCountxD,
--            VidOnxSI     => VidOnxS,
--            DataxDO      => DataxD);

--    end block ImageGeneratorxB;
    
    ---------------------------------------------------------------------------
    -- Mandelbrot Calculator
    ---------------------------------------------------------------------------
    MandelbrotCalculator : entity work.mandelbrot_calculator
        generic map (
            point_pos   => C_POINT_POS,
            max_iter    => C_MAX_ITER,
            SIZE        => C_DATA_SIZE)
        port map (
            clk         => ClkSys100MhzxC,
            rst         => RstxR,
            ready       => s_ready_mndl_cal,
            start       => s_finished_cstGen,
            finished    => s_finished_mndl_cal,
            c_real      => s_c_real,
            c_imaginary => s_c_imaginary,
            z_real      => s_z_real,
            z_imaginary => s_z_imaginary,
            iterations  => s_iterations);
            
    ---------------------------------------------------------------------------
    -- Constants Generator
    ---------------------------------------------------------------------------
    ConstantsGenerator : entity work.constants_generator
        generic map (
            point_pos   => C_POINT_POS,
            SIZE        => C_DATA_SIZE)
        port map (
            clk         => ClkSys100MhzxC,
            rst         => RstxR,
            ready       => s_ready_mndl_cal,
            finished    => s_finished_cstGen,
            screen_x    => s_screen_x,
            screen_y    => s_screen_y,
            c_real      => s_c_real,
            c_imaginary => s_c_imaginary);
            
    s_en_a_bram <= not RstxR;
    DataxD      <= s_output_bram & s_output_bram & s_output_bram;
    --DataxD      <= (others=>'1');

end architecture rtl;
