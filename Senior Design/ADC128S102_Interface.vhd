-- Engineer: 	    Dillon Carr
-- Create Date:    15:13:36 03/27/2015
-- Module Name:    ADC128S102_Interface - Behavioral 



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity ADC128S102_Interface is
	Port(
		clk : in std_logic;     -- 32 MHz
		Start : in std_logic;
		SCLK : out std_logic;   -- 8 MHz
		CS : out std_logic;
		DOUT : in std_logic;
		DIN : out std_logic;
		Data_ready : out std_logic;
		Nibble_out : out std_logic_vector(3 downto 0));
end ADC128S102_Interface;



architecture Behavioral of ADC128S102_Interface is

type state_type is (idle, convert, output);
signal state : state_type := idle; 
signal next_state : state_type;

signal idle_flag : std_logic := '1';
signal convert_flag : std_logic := '0';
signal output_flag : std_logic := '0';

signal clk_rise : std_logic := '0';
signal clk_fall : std_logic := '0';
signal start_delay : std_logic := '0';
signal start_rise : std_logic := '0';
signal cs_sig : std_logic := '1';
signal sclk_sig : std_logic := '0';
signal sclk_sig_delay : std_logic := '0';
signal sclk_counter : std_logic_vector := "00";
signal data_bit_counter : std_logic_vector(4 downto 0) := (others => '0');
signal nibble_bus : std_logic_vector(3 downto 0) := (others => '0');
signal data_frame : std_logic_vector(15 downto 0) := (others => '0');
signal data_ready_sig : std_logic := '0';
signal channel_select : std_logic_vector(2 downto 0) := (others => '0');

begin

CS <= NOT convert_flag;
SCLK <= sclk_sig;
Data_ready <= data_ready_sig;
channel_select <= "000";



-- PROCESSES --



process(clk)
begin
	if rising_edge(clk) then
		clk_rise <= '1';
	else
		clk_rise <= '0';
	end if;
end process;



process(clk)
begin
	if falling_edge(clk) then
		clk_fall <= '1';
	else
		clk_fall <= '0';
	end if;
end process;



-- generate SCLK_sig with f = 8 MHz
process(clk_rise)
begin
	if rising_edge(clk_rise) then
		if unsigned(sclk_counter) = 1 then
			sclk_sig <= NOT sclk_sig;
			sclk_counter <= "00";
		else
			sclk_counter <= std_logic_vector(unsigned(sclk_counter) + 1);
		end if;
	end if;
end process;



process(clk_rise)
begin
	if rising_edge(clk_rise) then
		sclk_sig_delay <= sclk_sig;
	end if;
end process;



-- processes to detect rising edge of Start bit --
process(sclk_sig)
begin
	if rising_edge(sclk_sig) then
		start_delay <= Start;
	end if;
end process;



process(sclk_sig)
begin
	if rising_edge(sclk_sig) then
		if Start = '1' AND start_delay = '0' then
			start_rise <= '1';
		else
			start_rise <= '0';
		end if;
	end if;
end process;



-- state machine --
process(clk)
begin
	if rising_edge(clk) then
		state <= next_state;
	end if;
end process;



process(start_rise, sclk_sig, state)
begin
	if rising_edge(sclk_sig) then
		case state is
		when idle =>
			idle_flag <= '1';
			convert_flag <= '0';
			output_flag <= '0';
			if start_rise = '1' then
				next_state <= convert;
			else
				next_state <= idle;
			end if;
		when convert =>
			idle_flag <= '0';
			convert_flag <= '1';
			output_flag <= '0';
			if unsigned(bit_ctr) = 15 then
				next_state <= output;
			else
				next_state <= convert;
			end if;
		when output =>
			idle_flag <= '0';
			convert_flag <= '0';
			output_flag <= '1';
			if unsigned(nibble_select) = 0 then
				next_state <= idle;
			else
				next_state <= output;
			end if;
		end case;	
	end if;
end process;



process(sclk_sig)
begin
	if rising_edge(sclk_sig) then
		if convert_flag = '1' then
			bit_counter <= std_logic_vector(unsigned(bit_counter) + 1);
		elsif output_flag = '1' then
			nibble_select <= std_logic_vector(unsigned(nibble_select) - 1);
		else
			bit_counter <= "0000";
			nibble_select <= "00";
		end if;
	end if;
end process;



process(SCLK_sig_delay)
begin
	if rising_edge(SCLK_sig_delay) AND output_flag = '1' then
		if nibble_select = "10" then
			nibble_out <= data_frame(11 downto 8);
		elsif nibble_select = "01" then
			nibble_out <= data_frame(7 downto 4);
		else
			nibble_out <= data_frame(3 downto 0);
		end if;
		data_ready_sig <= '1';
	else
		data_ready_sig <= '0';
	end if;
end process;
		


-- process defining sampling timing --
-- data bits feed on the falling edge of SCLK so we sample on the rising edge --
process(SCLK_sig)
begin
	if rising_edge(SCLK_sig) AND convert_flag = '1' then
		data_frame(to_integer(15 - unsigned(bit_counter))) <= DOUT;
	end if;
end process;



-- process controlling channel_ctr and channel_sel --
process(SCLK_sig)
begin
	if falling_edge(SCLK_sig) AND CS_sig = '0' then
		if unsigned(bit_counter) = 2 then
			DIN <= channel_select(2);
		elsif unsigned(bit_counter) = 3 then
			DIN <= channel_select(1);
		elsif unsigned(bit_counter) = 4 then
			DIN <= channel_select(0);
		else
			DIN <= '0';
		end if;
	end if;
end process;



end Behavioral;