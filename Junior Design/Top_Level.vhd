-- Engineer:	    Dillon Carr
-- Create Date:    20:38:29 04/30/2015
-- Module Name:    Top_Level - Behavioral 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_Level is

	Port(
	
		GO_top : in std_logic;
		system_clk : in std_logic; -- 32 MHz
		team_sw_top : in std_logic;
		arduino_in_top : in std_logic;
		IR_in_L_top : in std_logic;
		IR_out_L_top : out std_logic;
		IR_in_R_top : in std_logic;
		IR_out_R_top : out std_logic;
		SCLK_top : out std_logic; -- 8 MHz
		CS_top : out std_logic;
		DOUT_top : in std_logic;
		DIN_top : out std_logic;
		L_motor_f_top : out std_logic;
		L_motor_b_top : out std_logic;
		R_motor_f_top : out std_logic;
		R_motor_b_top : out std_logic);
end Top_Level;

architecture Behavioral of Top_Level is

signal r : std_logic_vector(15 downto 0) := (others => '0');
signal g : std_logic_vector(15 downto 0) := (others => '0');
signal b : std_logic_vector(15 downto 0) := (others => '0');
signal c : std_logic_vector(15 downto 0) := (others => '0');
signal lt : std_logic_vector(11 downto 0) := (others => '0');
signal md : std_logic_vector(11 downto 0) := (others => '0');
signal rt : std_logic_vector(11 downto 0) := (others => '0');

component Arduino_Interface is

	Port(
 
		clk : in  std_logic; -- 32 MHz
		arduino_in : in std_logic;
		red_intensity : out std_logic_vector(15 downto 0);
		green_intensity : out std_logic_vector(15 downto 0);
		blue_intensity : out std_logic_vector(15 downto 0);
		clear_intensity : out std_logic_vector(15 downto 0));
end component;

component IR_RX_TX is

	Port(
	
		clk : in std_logic; -- 32 MHz
		IR_in : in std_logic;
		IR_out : out std_logic);
end component;

component ADC128S102_Interface

	Port(
	
		clk : in std_logic;   -- 32 MHz
		SCLK : out std_logic; -- 8 MHz
		CS : out std_logic;
		DOUT : in std_logic;
		DIN : out std_logic;
		L_sensor : out std_logic_vector(11 downto 0);
		M_sensor : out std_logic_vector(11 downto 0);
		R_sensor : out std_logic_vector(11 downto 0));
end component;

component Motor_Control

	Port(
	
		clk : in std_logic;
		GO : in std_logic;
		team_switch : in std_logic;
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
end component;

begin

Light_Sensor : Arduino_Interface

	Port map(
	
		clk => system_clk,
		arduino_in => arduino_in_top,
		red_intensity => r,
		green_intensity => g,
		blue_intensity => b,
		clear_intensity => c);

IR_L : IR_RX_TX

	Port map(
	
		clk => system_clk,
		IR_in => IR_in_L_top,
		IR_out => IR_out_L_top);
		
IR_R : IR_RX_TX

	Port map(
	
		clk => system_clk,
		IR_in => IR_in_R_top,
		IR_out => IR_out_R_top);

Proximity_Sensor : ADC128S102_Interface

	Port map(
	
		clk => system_clk,
		SCLK => SCLK_top,
		CS => CS_top,
		DOUT => DOUT_top,
		DIN => DIN_top,
		L_sensor => lt,
		M_sensor => md,
		R_sensor => rt);

Navigation_Logic : Motor_Control

	Port map(
	
		clk => system_clk,
		GO => GO_top,
		team_switch => team_sw_top,
		left_distance => lt,
		middle_distance => md, 
		right_distance => rt, 
		red_intensity => r,
		green_intensity => g,
		blue_intensity => b,
		clear_intensity => c,
		L_motor_f => L_motor_f_top,
		L_motor_b => L_motor_b_top,
		R_motor_f => R_motor_f_top,
		R_motor_b => R_motor_b_top);

end Behavioral;