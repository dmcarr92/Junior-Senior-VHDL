----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:06:07 11/04/2015 
-- Design Name: 
-- Module Name:    Top_Level - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top_Level is
	Port(
		system_clk : in std_logic;
		TDR_enable_top : in std_logic);
end Top_Level;

architecture Behavioral of Top_Level is


signal start_signal : std_logic := '0';
signal nibble_ready_signal : std_logic := '0';
signal adc_done_signal : std_logic := '0';


component TDR_Prototype is
	Port(
		clk : in  std_logic;			-- Papilio: 32 MHz; Later we will be using one ~600 MHz --
		TDR_enable : in std_logic;		-- Single-bit enable signal from CPU --
		Done : out std_logic;			-- Output to signal test completion to CPU --
		Pulse_enable : out std_logic;	-- Enable output to switch on/off the TDR pulse --
		ADC_enable : out std_logic;
		ADC_nibble_ready : in std_logic;
		ADC_done : in std_logic);
end component;



component ADC128S102_Interface is
	Port(
		clk : in std_logic;     -- 32 MHz
		Start : in std_logic;
		SCLK : out std_logic;   -- 8 MHz
		CS : out std_logic;
		DOUT : in std_logic;
		DIN : out std_logic;
		Nibble_ready : out std_logic;
		Nibble_out : out std_logic_vector(3 downto 0);
		Data_done : out std_logic);
end component;



begin



Prototype : TDR_Prototype
	Port map(	
		clk => system_clk,
		TDR_enable => TDR_enable_top,
		Done => open,
		Pulse_enable => open,
		ADC_enable => start_signal,
		ADC_nibble_ready => nibble_ready_signal,
		ADC_done => adc_done_signal);



ADC : ADC128S102_Interface
	Port map(
		clk => system_clk,
		Start => start_signal,
		SCLK => open,
		CS => open,
		DOUT => '1',
		DIN =>open,
		Nibble_ready => nibble_ready_signal,
		Nibble_out => open,
		Data_done => adc_done_signal);
		
		
		
end Behavioral;

