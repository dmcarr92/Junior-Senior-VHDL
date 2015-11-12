-- Engineer: 	   Dillon Carr
-- Create Date:    15:13:36 03/27/2015
-- Module Name:    ADC128S102_Interface - Behavioral 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ADC128S102_Interface is

	Port(
	
		clk : in std_logic;   -- 32 MHz
		SCLK : out std_logic; -- 8 MHz
		CS : out std_logic;
		DOUT : in std_logic;
		DIN : out std_logic;
		L_sensor : out std_logic_vector(11 downto 0);
		M_sensor : out std_logic_vector(11 downto 0);
		R_sensor : out std_logic_vector(11 downto 0));
end ADC128S102_Interface;

architecture Behavioral of ADC128S102_Interface is

type state_type is (read_middle, read_left, read_right);
signal state : state_type := read_middle; 
signal next_state : state_type;

signal CS_sig : std_logic := '1';
signal SCLK_sig : std_logic := '0';
signal SCLK_ctr : std_logic_vector(1 downto 0) := "01";
signal SCLK_d : std_logic := '0';
signal SCLK_d_ctr : std_logic_vector(1 downto 0) := (others => '0');
signal bit_ctr : std_logic_vector(4 downto 0) := (others => '0');
signal channel_sel : std_logic_vector(2 downto 0) := (others => '0');
signal data_frame : std_logic_vector(15 downto 0) := (others => '0');

begin

CS <= CS_sig;
SCLK <= SCLK_sig;

-- process controlling CS (chip select) which is ACTIVE LOW
-- when CS falls the serial communication begins
process(SCLK_d)
begin

	if rising_edge(SCLK_d) then
	
		if unsigned(bit_ctr) = 15 then
		
			CS_sig <= '1';
		else
		
			CS_sig <= '0';
		end if;
	end if;
end process;

-- generate ADC_clk with f = 8 MHz
process(clk)
begin
	
	if rising_edge(clk) then
	
		if unsigned(SCLK_ctr) = 0 then
		
			SCLK_ctr <= std_logic_vector(unsigned(SCLK_ctr) + 1);
		else
		
			SCLK_sig <= NOT SCLK_sig;
			SCLK_ctr <= "00";
		end if;
	end if;
end process;

-- generate ADC_clk_d with f = 10.66 MHz, offset from ADC_clk by one system clock cycle
process(clk)
begin
	
	if rising_edge(clk) then
	
		if unsigned(SCLK_d_ctr) = 0 then
			
			SCLK_d_ctr <= std_logic_vector(unsigned(SCLK_d_ctr) + 1);
		else
		
			SCLK_d <= NOT SCLK_d;
			SCLK_d_ctr <= "00";
		end if;
	end if;
end process;

-- state machine
-- ADC has 8 pins
-- middle sensor --> pin0
-- left sensor   --> pin1
-- right sensor  --> pin2
process(clk)
begin

	if rising_edge(clk) then
	
		state <= next_state;
	end if;
end process;

process(SCLK_d)
begin

	if rising_edge(SCLK_d) AND CS_sig = '0' then
	
		case state is
		when read_middle =>
			
			channel_sel <= "000";
			if unsigned(bit_ctr) = 15 then
			
				bit_ctr <= "00000";
				M_sensor <= data_frame(11 downto 0);
				next_state <= read_left;
			else
			
				bit_ctr <= std_logic_vector(unsigned(bit_ctr) + 1);
				next_state <= read_middle;
			end if;
		when read_left =>
		
			channel_sel <= "001";
			if unsigned(bit_ctr) = 15 then
			
				bit_ctr <= "00000";
				L_sensor <= data_frame(11 downto 0);
				next_state <= read_right;
			else
			
				bit_ctr <= std_logic_vector(unsigned(bit_ctr) + 1);
				next_state <= read_left;
			end if;
		when read_right =>
		
			channel_sel <= "010";
			if unsigned(bit_ctr) = 15 then
			
				bit_ctr <= "00000";
				R_sensor <= data_frame(11 downto 0);
				next_state <= read_middle;
			else
			
				bit_ctr <= std_logic_vector(unsigned(bit_ctr) + 1);
				next_state <= read_right;
			end if;
		end case;
	end if;
end process;

-- process defining sampling timing
-- data bits feed on the falling edge of ADC_clk so we sample on the rising edge
process(SCLK_sig)
begin

	if rising_edge(SCLK_sig) AND CS_sig = '0' then

		data_frame(to_integer(15 - unsigned(bit_ctr))) <= DOUT;
	end if;
end process;

-- process controlling channel_ctr and channel_sel
process(SCLK_sig)
begin

	if falling_edge(SCLK_sig) AND CS_sig = '0' then
	
		if unsigned(bit_ctr) = 2 then
		
			DIN <= channel_sel(2);
		elsif unsigned(bit_ctr) = 3 then
		
			DIN <= channel_sel(1);
		elsif unsigned(bit_ctr) = 4 then
		
			DIN <= channel_sel(0);
		else
		
			DIN <= '0';
		end if;
	end if;
end process;

end Behavioral;