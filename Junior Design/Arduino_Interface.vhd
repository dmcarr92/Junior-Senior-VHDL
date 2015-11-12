-- Engineer: 	    Dillon Carr
-- Create Date:    16:13:06 03/20/2015 
-- Module Name:    Arduino_Interface - Behavioral 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Arduino_Interface is

	Port(
 
		clk : in  std_logic; -- 32 MHz
		arduino_in : in std_logic;
		red_intensity : out std_logic_vector(15 downto 0);
		green_intensity : out std_logic_vector(15 downto 0);
		blue_intensity : out std_logic_vector(15 downto 0);
		clear_intensity : out std_logic_vector(15 downto 0));
end Arduino_Interface;

architecture Behavioral of Arduino_Interface is

type state_type is (idle, RED_high, RED_low, GREEN_high, GREEN_low, BLUE_high, BLUE_low, CLEAR_high, CLEAR_low);
signal state : state_type := idle;
signal next_state : state_type;

signal state_ctr : std_logic_vector(2 downto 0) := (others => '0');
signal arduino_sig : std_logic := '1';
signal arduino_sig_d : std_logic := '1';
signal dclk : std_logic := '0'; -- 19.2 kHz (twice the Arduino's baud rate)
signal dclk_ctr : std_logic_vector(10 downto 0) := (others => '0');
signal bit_ctr : std_logic_vector(3 downto 0) := (others => '0');
signal data_reg : std_logic_vector(9 downto 0) := (others => '0');
signal r_intensity : std_logic_vector(15 downto 0) := (others => '0');
signal g_intensity : std_logic_vector(15 downto 0) := (others => '0');
signal b_intensity : std_logic_vector(15 downto 0) := (others => '0');
signal c_intensity : std_logic_vector(15 downto 0) := (others => '0');

begin

red_intensity <= r_intensity;
green_intensity <= g_intensity;
blue_intensity <= b_intensity;
clear_intensity <= c_intensity;

-- state machine
process(clk)
begin

	if rising_edge(clk) then
	
		arduino_sig_d <= arduino_sig;
		arduino_sig <= arduino_in;
		state <= next_state;
	end if;
end process;

process(clk)
begin

	if rising_edge(clk) then
	
		case state is
		when idle =>
			
			if arduino_sig_d = '1' AND arduino_sig = '0' then
				
				if state_ctr = "000" then
					
					next_state <= RED_high;
				elsif state_ctr = "001" then
					
					next_state <= RED_low;
				elsif state_ctr = "010" then
					
					next_state <= BLUE_high;
				elsif state_ctr = "011" then
					
					next_state <= BLUE_low;
				elsif state_ctr = "100" then
					
					next_state <= GREEN_high;
				elsif state_ctr = "101" then
					
					next_state <= GREEN_low;
				elsif state_ctr = "110" then
					
					next_state <= CLEAR_high;
				else
					
					next_state <= CLEAR_low;
				end if;
			end if;
		when RED_high =>
		
			if unsigned(bit_ctr) = 10 then
					
				r_intensity(15 downto 8) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= RED_high;
			end if;
		when RED_low =>
			
			if unsigned(bit_ctr) = 10 then
					
				r_intensity(7 downto 0) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= RED_low;
			end if;
		when BLUE_high =>
		
			if unsigned(bit_ctr) = 10 then
					
				b_intensity(15 downto 8) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= BLUE_high;
			end if;
		when BLUE_low =>
		
			if unsigned(bit_ctr) = 10 then
					
				b_intensity(7 downto 0) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= BLUE_low;
			end if;
		when GREEN_high =>
		
			if unsigned(bit_ctr) = 10 then
					
				g_intensity(15 downto 8) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= GREEN_high;
			end if;
		when GREEN_low =>

			if unsigned(bit_ctr) = 10 then
					
				g_intensity(7 downto 0) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= GREEN_low;
			end if;
		when CLEAR_high =>
		
			if unsigned(bit_ctr) = 10 then
					
				c_intensity(15 downto 8) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= CLEAR_high;
			end if;
		when CLEAR_low =>
			
			if unsigned(bit_ctr) = 10 then
					
				c_intensity(7 downto 0) <= data_reg(8 downto 1);
				state_ctr <= std_logic_vector(unsigned(state_ctr) + 1);
				next_state <= idle;
			else
				
				next_state <= CLEAR_low;
			end if;
		end case;
	end if;
end process;

process(clk)
begin

	if rising_edge(clk) then 
	
		if state /= idle then
	
			if unsigned(dclk_ctr) = 1664 then
		
				dclk <= NOT dclk;
				dclk_ctr <= "00000000001";
			else
		
				dclk_ctr <= std_logic_vector(unsigned(dclk_ctr) + 1);
			end if;
		else
		
			dclk_ctr <= (others => '0');
		end if;
	end if;
end process;

process(dclk)
begin

	if rising_edge(dclk) then
	
		data_reg(to_integer(9 - unsigned(bit_ctr))) <= arduino_in;
		bit_ctr <= std_logic_vector(unsigned(bit_ctr) + 1);
	end if;
end process;

end Behavioral;