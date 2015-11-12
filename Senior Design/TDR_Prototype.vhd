-- Engineer: 	   Dillon Carr --
-- Create Date:    16:13:06 10/24/2015 --
-- Module Name:    TDR_Prototype - Behavioral --



-- This is a VHDL module designed to program an FPGA to perform a Time-Domain Reflectometry test.  It may not build because it has not yet been tested --
-- This design uses Equivalent-Time Sampling to sample at a perceived rate of 2 * (cpu clk frequeny) --
-- The code is written for the Papilio One FPGA board, which has a 32 MHz oscillator --
-- Sampling for 2 microseconds requires us to sample n times.  n = (2e-6)/(31.25e-9) = 128 --
-- When we adapt the code for a CPU with a faster clock, the ranges of sample_counter and iteration_counter will need to be updated --



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity TDR_Prototype is
	Port(
		clk : in  std_logic;			-- Papilio: 32 MHz; Later we will be using one ~600 MHz --
		TDR_enable : in std_logic;		-- Single-bit enable signal from CPU --
		Done : out std_logic;			-- Output to signal test completion to CPU --
		Pulse_enable : out std_logic;	-- Enable output to switch on/off the TDR pulse --
		ADC_enable : out std_logic);		-- Enable signal to CPU; triggers ADC conversion --
end Arduino_Interface;



architecture Behavioral of TDR_Prototype is

type state_type is(idle, pulse, sample);
signal state : state_type := idle;
signal next_state : state_type;

signal idle_flag : std_logic := '1';
signal pulse_flag : std_logic := '0';
signal sample_flag : std_logic := '0';

signal clk_rise : std_logic;
signal clk_fall : std_logic;

signal tdr_enable_delay : std_logic := '0';
signal tdr_enable_rise : std_logic := '0';

signal pulse_counter : std_logic_vector(2 downto 0) := (others => '0');			-- counts 0 - 7; Pulse width = 8 sample clks = (8 * 15.625) ns --
signal sample_counter : std_logic_vector(6 downto 0) := (others => '0');		-- counts 0 - 127; Sample state lasts 128 sample clks = (128 * 15.625) ns --
signal iteration_counter : std_logic_vector(6 downto 0) := (others => '0');	-- counts 0 - Executes 128 iterations of [Pulse->Sample] --

signal adc_sig_delay : std_logic_vector(7 downto 0) := (others => '0');

begin


Done <= idle_flag;
Pulse_enable <= pulse_flag;
ADC_enable <= adc_sig_delay(0) OR
				  adc_sig_delay(1) OR
				  adc_sig_delay(2) OR
				  adc_sig_delay(3) OR
				  adc_sig_delay(4) OR
				  adc_sig_delay(5) OR
				  adc_sig_delay(6) OR
				  adc_sig_delay(7);
 


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



process(clk_rise, clk_fall)
begin
	if rising_edge(clk_rise) OR rising_edge(clk_fall) then
		adc_sig_delay(1) <= adc_sig_delay(0);
		adc_sig_delay(2) <= adc_sig_delay(1);
		adc_sig_delay(3) <= adc_sig_delay(2);
		adc_sig_delay(4) <= adc_sig_delay(3);
		adc_sig_delay(5) <= adc_sig_delay(4);
		adc_sig_delay(6) <= adc_sig_delay(5);
		adc_sig_delay(7) <= adc_sig_delay(6);		
	end if;
end process;



-- enable_delay --
process(clk_rise)
begin
	if rising_edge(clk_rise) then
		tdr_enable_delay <= tdr_enable;
	end if;
end process;



-- tdr_enable_rise --
process(clk_rise)
begin
	if rising_edge(clk_rise) then
		if tdr_enable = '1' AND tdr_enable_delay = '0' then		-- rising edge of tdr_enable observed --
			tdr_enable_rise <= '1';
		else 
			tdr_enable_rise <= '0';
		end if;
	end if;
end process;



-- state register--
process(clk_rise)
begin
	if rising_edge(clk_rise) then
		state <= next_state;
	end if;
end process;



-- next_state logic --
process(state, clk_rise)
begin
	if rising_edge(clk_rise) then
		case state is
		when idle =>
			idle_flag <= '1';
			pulse_flag <= '0';
			sample_flag <= '0';
			if tdr_enable_rise = '1' then
				next_state <= pulse;
			else
				next_state <= idle;
			end if;
		when pulse =>
			idle_flag <= '0';
			pulse_flag <= '1';
			sample_flag <= '0';
			if unsigned(pulse_counter) = 7 then
				next_state <= sample;
			else
				next_state <= pulse;
			end if;
		when sample =>
			idle_flag <= '0';
			pulse_flag <= '0';
			sample_flag <= '1';
			if unsigned(sample_counter) = 127 then
				if unsigned(iteration_counter) = 127 then
					next_state <= idle;
				else
					next_state <= pulse;
				end if;
			else
				next_state <= sample;
			end if;
		end case;
	end if;
end process;



-- control of pulse, sample, and iteration counters --
process(clk_rise, clk_fall)
begin
	if rising_edge(clk_rise) OR rising_edge(clk_fall) then
		if pulse_flag = '1' then
			if unsigned(pulse_counter) = 7 then
				pulse_counter <= "000";
			else
				pulse_counter <= std_logic_vector(unsigned(pulse_counter) + 1);
			end if;
		elsif state_flag = '1' then
			if unsigned(sample_counter) = 127 then
				if iteration_counter = 127 then
					iteration_counter <= "0000000";
				else
					iteration_counter <= std_logic_vector(unsigned(iteration_counter) + 1);
				end if;
				sample_counter <= "0000000";
			else
				sample_counter <= std_logic_vector(unsigned(sample_counter) + 1);
			end if;
		else
			pulse_counter <= "000";
			sample_counter <= "0000000";
			iteration_counter <= "0000000";
		end if;
	end if;
end process;



-- ADC_enable logic --
-- sets ADC_enable high for one sample cycle triggering ADC conversion --
process(clk_rise, clk_fall)
begin
	if rising_edge(clk_rise) OR rising_edge(clk_fall) then
		if sample_counter = iteration_counter then
			adc_sig_delay(0) <= '1';
		else
			adc_sig_delay(0) <= '0';
		end if;
	end if;
end process;



end Behavioral;