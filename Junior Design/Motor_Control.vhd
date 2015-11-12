-- Engineer: 	    Dillon Carr
-- Create Date:    17:40:12 04/30/2015
-- Module Name:    Motor_Control - Behavioral 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Motor_Control is

	Port(
	
		clk : in std_logic;
		GO : in std_logic;
		team_switch : in std_logic; -- ON indicates RED team, OFF indicates GREEN team
		left_distance : in std_logic_vector(11 downto 0);
		middle_distance : in std_logic_vector(11 downto 0); 
		right_distance : in std_logic_vector(11 downto 0); 
		red_intensity : in std_logic_vector(15 downto 0);
		green_intensity : in std_logic_vector(15 downto 0); 
		blue_intensity : in std_logic_vector(15 downto 0); 
		clear_intensity : in std_logic_vector(15 downto 0);
		L_motor_f : out std_logic;
		L_motor_b : out std_logic;
		R_motor_f : out std_logic;
		R_motor_b : out std_logic);
end Motor_Control;

architecture Behavioral of Motor_Control is

signal slow_clk : std_logic := '0'; -- 1 kHz
signal slow_clk_ctr : std_logic_vector(23 downto 0) := (others => '0');
signal beacon_ahead : std_logic := '0';
signal beacon_left : std_logic := '0';
signal beacon_right : std_logic := '0';
signal last_direction : std_logic_vector(1 downto 0) := (others => '0');
signal obstacle_sensed : std_logic := '0';
signal obstacle_sensed_d1 : std_logic := '0';
signal obstacle_sensed_d2 : std_logic := '0';
signal in_IR_range : std_logic := '0';
signal light_sum : std_logic_vector(15 downto 0) := (others => '0');
signal four_inches : std_logic_vector(11 downto 0) := "001101011111";
signal IR_range_val : std_logic_vector(15 downto 0) := (others => '0');
signal beacon_range_val : std_logic_vector(15 downto 0) := (others => '0');

begin

IR_range_val <= "0001000000000000" when team_switch = '0' else "0000000010000000";
beacon_range_val <= "0000000001000000" when team_switch = '0' else "0000000000010000";	
			
-- generate slow_clk with frequency 1 kHz
process(clk)
begin

	if rising_edge(clk) then
	
		if unsigned(slow_clk_ctr) = 16000000 then
		
			slow_clk <= NOT slow_clk;
			slow_clk_ctr <= "000000000000000000000001";
		else
		
			slow_clk_ctr <= std_logic_vector(unsigned(slow_clk_ctr) + 1);
		end if;
	end if;
end process;

-- logic to control beacon locator flags and in_IR_range flag
process(slow_clk)
begin
	
	if rising_edge(slow_clk) AND GO = '1' then
			
		obstacle_sensed_d2 <= obstacle_sensed_d1;
		obstacle_sensed_d1 <= obstacle_sensed;
		light_sum <= std_logic_vector(unsigned(red_intensity) + unsigned(green_intensity) + unsigned(blue_intensity) + unsigned(clear_intensity));
		if (obstacle_sensed_d2 = '0') AND (obstacle_sensed_d1 = '0') AND (obstacle_sensed = '0') then
		
			if unsigned(light_sum) > unsigned(IR_range_val) then
			
				in_IR_range <= '1';
				beacon_ahead <= '1';
				beacon_left <= '0';
				beacon_right <= '0';
			elsif unsigned(light_sum) > unsigned(beacon_range_val) then
				
				in_IR_range <= '0';
				beacon_ahead <= '1';
				beacon_left <= '0';
				beacon_right <= '0';
			elsif last_direction = "10" then
			
				in_IR_range <= '0';
				beacon_ahead <= '0';
				beacon_left <= '1';
				beacon_right <= '0';
			elsif last_direction = "01" then
			
				in_IR_range <= '0';
				beacon_ahead <= '0';
				beacon_left <= '0';
				beacon_right <= '1';
			else
			
				in_IR_range <= '0';
				beacon_ahead <= '1';
				beacon_left <= '0';
				beacon_right <= '0';
			end if;
		end if;
	end if;
end process;

-- process with logic for motor outputs
process(slow_clk)
begin

	if falling_edge(slow_clk) AND GO = '1' then
	
		if in_IR_range = '1' then -- light strong enough to indicate that we are within IR range
			
			obstacle_sensed <= '0';
			L_motor_f <= '0';
			L_motor_b <= '0';
			R_motor_f <= '0';
			R_motor_b <= '0';
			last_direction <= "00";
		elsif beacon_ahead = '1' then -- beacon tower last sensed ahead, or not at all
		
			if (middle_distance > four_inches) AND (left_distance > four_inches) AND (right_distance > four_inches) then
		
				obstacle_sensed <= '1'; -- obstacle sensed directly ahead 
				L_motor_f <= '0';
				L_motor_b <= '1';
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= "00"; -- pivot left, clear last_direction
				
			elsif left_distance > four_inches then
		
				obstacle_sensed <= '1'; -- obstacle sensed on the left
				L_motor_f <= '1';
				L_motor_b <= '0';
				R_motor_f <= '0';
				R_motor_b <= '1';
				last_direction <= "10"; -- pivot right, indicate beacon last sensed to the left
			elsif right_distance > four_inches then
		
				obstacle_sensed <= '1'; -- obstacle sensed on the right
				L_motor_f <= '0';
				L_motor_b <= '1';
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= "01"; -- pivot left, indicate beacon last sensed to the right
			else

				obstacle_sensed <= '0'; -- no obstacle sensed
				L_motor_f <= '1';
				L_motor_b <= '0';
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= "00"; -- drive forward, clear last_direction
			end if;
		elsif beacon_left = '1' then -- beacon tower last sensed to the left
		
			if (middle_distance > four_inches) AND (left_distance > four_inches) AND (right_distance > four_inches) then
		
				obstacle_sensed <= '1'; -- obstacle sensed directly ahead
				L_motor_f <= '0';
				L_motor_b <= '1';
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= "00"; -- pivot left, clear last_direction
				
			elsif left_distance > four_inches then
		
				obstacle_sensed <= '1'; -- obstacle sensed on the left
				L_motor_f <= '1';
				L_motor_b <= '0';
				R_motor_f <= '0';
				R_motor_b <= '1';
				last_direction <= "10"; -- pivot right, indicate beacon last sensed to the left
			elsif right_distance > four_inches then
		
				obstacle_sensed <= '1'; -- obstacle sensed on the right
				L_motor_f <= '0';
				L_motor_b <= '1';
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= "01"; -- pivot left, indicate beacon last sensed to the right
			else

				obstacle_sensed <= '0'; -- no obstacle sensed
				L_motor_f <= '0';
				L_motor_b <= '1'; -- no obstacle sensed
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= last_direction; -- pivot left, hold last_direction
			end if;
		else -- beacon tower last sensed to the right
		
			if (middle_distance > four_inches) AND (left_distance > four_inches) AND (right_distance > four_inches) then
		
				obstacle_sensed <= '1'; -- obstacle sensed directly ahead
				L_motor_f <= '1';
				L_motor_b <= '0';
				R_motor_f <= '0';
				R_motor_b <= '1';
				last_direction <= "00"; -- pivot right, clear last_direction
				
			elsif left_distance > four_inches then
		
				obstacle_sensed <= '1'; -- obstacle sensed on the left
				L_motor_f <= '1';
				L_motor_b <= '0';
				R_motor_f <= '0';
				R_motor_b <= '1';
				last_direction <= "10"; -- pivot right, indicate beacon last sensed to the left
			elsif right_distance > four_inches then
		
				obstacle_sensed <= '1'; -- obstacle sensed on the right
				L_motor_f <= '0';
				L_motor_b <= '1';
				R_motor_f <= '1';
				R_motor_b <= '0';
				last_direction <= "01"; -- pivot left, indicate beacon last sensed to the right
			else

				obstacle_sensed <= '0'; -- no obstacle sensed
				L_motor_f <= '1';
				L_motor_b <= '0';
				R_motor_f <= '0';
				R_motor_b <= '1';
				last_direction <= last_direction; -- pivot right, hold last_direction
			end if;
		end if;
	end if;
end process;

end Behavioral;