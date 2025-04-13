-------------------------------------------------------------------------------
-- Copyright (c) 2005 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor: Xilinx
-- \   \   \/    Version: 1.0
--  \   \        Filename: prbsgen_ser.vhd
--  /   /        Date Last Modified:  May 1 2007
-- /___/   /\    Date Created: May 1 2007
-- \   \  /  \
--  \___\/\___\
-- 
--Device: Virtex-5
--Purpose: Barrel shifter flex.
--Reference:
--    
--Revision History:
-- Version 2:
--          RST is now active HIGH
--          Fixed bug, preventing BS to work with 40 bits output
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

entity bs_flex is
  generic (
    WDT_IN  : in integer range 2 to 40 := 16;
    WDT_OUT : in integer range 2 to 40 := 16;

    S_MAX : in integer range 2 to 31 := 20
    );
  port (
    CLK    : in  std_logic;
    RST    : in  std_logic;
    DIN    : in  std_logic_vector((WDT_IN - 1) downto 0);
    EN     : in  std_logic;
    EN_IN  : in  std_logic_vector(4 downto 0);
    EN_OUT : out std_logic                              := '0';
    DOUT   : out std_logic_vector((WDT_OUT-1) downto 0) := (others => '0')
    );
end bs_flex;

architecture behavior of bs_flex is

  component rotwdt
    generic (
      WDT_IN  : in integer range 2 to 40 := 10;
      WDT_OUT : in integer range 2 to 40 := 10;

      WDT_OUT_1 : in std_logic_vector(7 downto 0);
      S_MAX     : in integer range 2 to 40        := 10
      );
    port (
      CLK  : in  std_logic;
      RST  : in  std_logic;
      EN   : in  std_logic;
      HIN  : in  std_logic_vector((2*WDT_OUT - 1) downto 0);
      HOUT : out std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
      P    : in  std_logic_vector(7 downto 0)
      );
  end component;


  component control
    generic (
      WDT_IN  : in integer range 2 to 40 := 10;
      WDT_OUT : in integer range 2 to 40 := 10;

      WDT_OUT_1 : in std_logic_vector(7 downto 0);
      S_MAX     : in integer range 2 to 40        := 10
      );
    port (
      CLK    : in  std_logic;
      RST    : in  std_logic;
      EN     : in  std_logic;
      DV     : in  std_logic_vector(6 downto 0);
      SHIFT  : out std_logic_vector(7 downto 0) := (others => '0');
      WRFLAG : out std_logic                    := '0';
      VALID  : out std_logic                    := '0'
      );
  end component;


  signal mask        : std_logic_vector((2*WDT_OUT - 1) downto 0)          := (others => '0');
  signal dinext      : std_logic_vector((2*WDT_OUT - 1) downto 0)          := (others => '0');
  signal dinext_rot  : std_logic_vector((2*WDT_OUT - 1) downto 0)          := (others => '0');
  signal dinext_pre  : std_logic_vector((2*WDT_OUT - WDT_IN - 1) downto 0) := (others => '0');
  signal regwdt      : std_logic_vector((2*WDT_OUT - 1) downto 0)          := (others => '0');
  signal regout      : std_logic_vector((WDT_OUT-1) downto 0)              := (others => '0');
  signal pointer1    : std_logic_vector(7 downto 0)                        := (others => '0');
  signal wrflag      : std_logic                                           := '0';
  signal valid       : std_logic                                           := '0';
  signal EN_IN_int   : std_logic_vector(6 downto 0)                        := (others => '0');
  constant dm0       : std_logic_vector((WDT_OUT - 1) downto 0)            := (others => '1');
  constant dm1       : std_logic_vector((WDT_OUT - 1) downto 0)            := (others => '0');
  constant dm        : std_logic_vector((2*WDT_OUT - 1) downto 0)          := dm1 & dm0;
  constant WDT_OUT_1 : std_logic_vector(7 downto 0)                        := CONV_STD_LOGIC_VECTOR(WDT_OUT, 8);
  -- signal WDT_OUT_1 : std_logic_vector(5 downto 0)                        := (others => '0');
  

begin

--  WDT_OUT_1 <= CONV_STD_LOGIC_VECTOR(WDT_OUT, 6);
  
  Inst_mask_bs : rotwdt
    generic map(
      WDT_IN    => WDT_IN,
      WDT_OUT   => WDT_OUT,
      WDT_OUT_1 => WDT_OUT_1,
      S_MAX     => S_MAX
      )
    port map(
      CLK  => CLK,
      RST  => RST,
      HIN  => dm,
      EN   => EN,
      HOUT => mask,
      P    => pointer1
      );

EN_IN_int <= "00"&EN_IN;
	  
  I_control : control
    generic map(
      WDT_IN    => WDT_IN,
      WDT_OUT   => WDT_OUT,
      WDT_OUT_1 => WDT_OUT_1,
      S_MAX     => S_MAX
      )

    port map(
      CLK    => CLK,
      RST    => RST,
      DV     => EN_IN_int,
      EN     => EN,
      SHIFT  => pointer1,
      WRFLAG => wrflag,
      VALID  => valid
      );

  dinext_pre <= (others => '0');

  dinext <= dinext_pre & DIN;

  Inst_data_bs : rotwdt
    generic map(
      WDT_IN    => WDT_IN,
      WDT_OUT   => WDT_OUT,
      WDT_OUT_1 => WDT_OUT_1,
      S_MAX     => S_MAX
      )
    port map(
      CLK  => CLK,
      RST  => RST,
      HIN  => dinext,
      EN   => EN,
      HOUT => dinext_rot,
      P    => pointer1
      );



  process (CLK, RST)
  begin
    if RST = '1' then
      regwdt <= (others => '0');
    elsif rising_edge(CLK) then
      if EN = '1' then
        for i in 0 to (2*WDT_OUT - 1) loop
          if mask(i) = '1' then
            regwdt(i) <= dinext_rot(i);  -- update
          else
            regwdt(i) <= regwdt(i);      -- keep
          end if;
        end loop;
      end if;
    end if;
  end process;

  regout <= regwdt((WDT_OUT - 1) downto 0) when wrflag = '0' else regwdt((2*WDT_OUT - 1) downto WDT_OUT);

  process (CLK, RST)
  begin
    if RST = '1' then
      DOUT <= (others => '0');
    elsif rising_edge(CLK) then
      if EN = '1' then
        DOUT <= regout;
      end if;
    end if;
  end process;

  process (CLK, RST)
  begin
    if RST = '1' then
      EN_OUT <= '0';
    elsif rising_edge(CLK) then
      if EN = '1' then
        EN_OUT <= valid;
      end if;
    end if;
  end process;

end;


-------------------------------------------------------------------------------
-- Copyright (c) 2005 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor: Xilinx
-- \   \   \/    Version: 1.0
--  \   \        Filename: prbsgen_ser.vhd
--  /   /        Date Last Modified:  May 1 2007
-- /___/   /\    Date Created: May 1 2007
-- \   \  /  \
--  \___\/\___\
-- 
--Device: Virtex-5
--Purpose: Controller for the barrel shifter.
--Reference:
--    
--Revision History:
-- 
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- to Elisa
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

entity control is
  generic (
    WDT_IN    : in integer range 2 to 40        := 10;
    WDT_OUT   : in integer range 2 to 40        := 10;
    WDT_OUT_1 : in std_logic_vector(7 downto 0);
    S_MAX     : in integer range 2 to 40        := 10
    );
  port (
    CLK    : in  std_logic;
    RST    : in  std_logic;
    EN     : in  std_logic;
    DV     : in  std_logic_vector(6 downto 0);
    SHIFT  : out std_logic_vector(7 downto 0) := (others => '0');
    WRFLAG : out std_logic                    := '0';
    VALID  : out std_logic                    := '0'
    );
end control;

architecture behavior of control is


  signal temp    : std_logic_vector(8 downto 0) := (others => '0');
  signal pointer : std_logic_vector(8 downto 0) := (others => '0');
  signal flag    : std_logic                    := '0';
  signal flag_d  : std_logic                    := '0';
  signal rflag   : std_logic                    := '0';
  signal wrflags : std_logic                    := '0';
  signal valids  : std_logic                    := '0';

begin



-- pointer

  temp <= (pointer + ('0' & DV));       -- 0->31

  process (CLK, RST)
  begin
    if RST = '1' then
      pointer <= (others => '0');
    elsif rising_edge(CLK) then
      if EN = '1' then
        if temp <= ((WDT_OUT_1(7 downto 0) & '0') - '1') then
          pointer <= temp;
        else
          pointer <= temp - ((WDT_OUT_1(7 downto 0) & '0'));
        end if;
      end if;
    end if;
  end process;

  SHIFT <= pointer(7 downto 0);
  flag  <= '0' when (pointer < WDT_OUT_1) else '1';

  process (CLK, RST)
  begin
    if RST = '1' then
      flag_d <= '0';
    elsif rising_edge(CLK) then
      if EN = '1' then
        flag_d <= flag;
      end if;
    end if;
  end process;

  process (CLK, RST)
  begin
    if RST = '1' then
      wrflags <= '0';
	  valids  <= '0';
    elsif rising_edge(CLK) then
      if EN = '1' then
        wrflags <= flag_d;
        valids  <= flag xor flag_d;
      end if;
    end if;
  end process;

  WRFLAG <= wrflags;
  VALID  <= valids;

end;



-------------------------------------------------------------------------------
-- Copyright (c) 2005 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor: Xilinx
-- \   \   \/    Version: 1.0
--  \   \        Filename: prbsgen_ser.vhd
--  /   /        Date Last Modified:  May 1 2007
-- /___/   /\    Date Created: May 1 2007
-- \   \  /  \
--  \___\/\___\
-- 
--Device: Virtex-5
--Purpose: Rotator for the barrel shifter.
--Reference:
--    
--Revision History:
--    Rev 1.0 - First created, Giovanni Guasti and Paolo Novellini, May 1 2007.
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- to Elisa
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity rotwdt is
  generic (
    WDT_IN    : in integer range 2 to 40        := 10;
    WDT_OUT   : in integer range 2 to 40        := 10;
    WDT_OUT_2 : in std_logic_vector(5 downto 0) := "111111";  -- uscita width *2 -1
    WDT_OUT_1 : in std_logic_vector(7 downto 0) := "10000000";  -- uscita width
    S_MAX     : in integer range 2 to 31        := 10
    );
  port (
    CLK  : in  std_logic;
    RST  : in  std_logic;
    HIN  : in  std_logic_vector((2*WDT_OUT - 1) downto 0);
    EN   : in  std_logic;
    HOUT : out std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
    P    : in  std_logic_vector(7 downto 0)
    );
end rotwdt;

architecture behavior of rotwdt is

  signal a : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal b : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal c : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal d : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal e : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal f : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal g : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');
  signal h : std_logic_vector((2*WDT_OUT - 1) downto 0) := (others => '0');

begin

  a <= HIN((2*WDT_OUT - 1) downto 0) when P(0) = '0' else HIN((2*WDT_OUT - 2) downto 0) & HIN((2*WDT_OUT - 1));  -- 1


  rot2 : if (2*WDT_OUT >= 2) generate
    b <= a((2*WDT_OUT - 1) downto 0) when P(1) = '0' else a((2*WDT_OUT - 3) downto 0) & a((2*WDT_OUT - 1) downto (2*WDT_OUT - 2));  -- 2
  end generate rot2;

  rot2_n : if (2*WDT_OUT < 2) generate
    b <= a;                             -- 2
  end generate rot2_n;

  rot4 : if (2*WDT_OUT >= 4) generate
    c <= b((2*WDT_OUT - 1) downto 0) when P(2) = '0' else b((2*WDT_OUT - 5) downto 0) & b((2*WDT_OUT - 1) downto (2*WDT_OUT - 4));  -- 4
  end generate rot4;

  rot4_n : if (2*WDT_OUT < 4) generate
    c <= b;                             -- 4
  end generate rot4_n;

  rot8 : if (2*WDT_OUT >= 8) generate
    d <= c((2*WDT_OUT - 1) downto 0) when P(3) = '0' else c((2*WDT_OUT - 9) downto 0) & c((2*WDT_OUT - 1) downto (2*WDT_OUT - 8));  -- 8
  end generate rot8;

  rot8_n : if (2*WDT_OUT < 8) generate
    d <= c;                             -- 8
  end generate rot8_n;

  rot16 : if (2*WDT_OUT >= 16) generate
    e <= d((2*WDT_OUT - 1) downto 0) when P(4) = '0' else d((2*WDT_OUT - 17) downto 0) & d((2*WDT_OUT - 1) downto (2*WDT_OUT - 16));  -- 16
  end generate rot16;

  rot16_n : if (2*WDT_OUT < 16) generate
    e <= d;                             -- 16
  end generate rot16_n;

  rot32 : if (2*WDT_OUT >= 32) generate
    f <= e((2*WDT_OUT - 1) downto 0) when P(5) = '0' else e((2*WDT_OUT - 33) downto 0) & e((2*WDT_OUT - 1) downto (2*WDT_OUT - 32));  -- 32
  end generate rot32;

  rot32_n : if (2*WDT_OUT < 32) generate
    f <= e;
  end generate rot32_n;
  
  rot64 : if (2*WDT_OUT >= 64) generate
    g <= f((2*WDT_OUT - 1) downto 0) when P(6) = '0' else f((2*WDT_OUT - 65) downto 0) & f((2*WDT_OUT - 1) downto (2*WDT_OUT - 64));  -- 64
  end generate rot64;

  rot64_n : if (2*WDT_OUT < 64) generate
    g <= f;
  end generate rot64_n;

  rot128 : if (2*WDT_OUT >= 128) generate
    h <= g((2*WDT_OUT - 1) downto 0) when P(7) = '0' else g((2*WDT_OUT - 129) downto 0) & g((2*WDT_OUT - 1) downto (2*WDT_OUT - 128));  -- 64
  end generate rot128;

  rot128_n : if (2*WDT_OUT < 128) generate
    h <= g;
  end generate rot128_n;

  process (CLK, RST, EN)
  begin
    if RST = '1' then
      HOUT <= (others => '0');
    elsif rising_edge(CLK) and EN = '1' then
      HOUT <= h;
    end if;
  end process;


end;
