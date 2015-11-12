-- Engineer:	    Dillon Carr
-- Create Date:    18:12:21 03/06/2015 
-- Module Name:    IR_RX_TX - Behavioral 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IR_RX_TX is

	Port(
	
		clk : in std_logic; -- 32 MHz
		IR_in : in std_logic;
		IR_out : out std_logic);
end IR_RX_TX;

architecture Behavioral of IR_RX_TX is

signal slow_clk : std_logic := '0';
signal slow_clk_ctr : std_logic_vector(15 downto 0) := (others => '0');
signal start_det : std_logic := '0';
signal bits_in : std_logic_vector(3 downto 0) := (others => '0');
signal bits_out : std_logic_vector(3 downto 0) := (others => '0');
signal data_reg : std_logic_vector(9 downto 0) := (others => '0');
signal inv_data : std_logic_vector(7 downto 0) := (others => '0');
signal IR_out_unmod : std_logic := '1';
signal mod_sig : std_logic := '0';
signal mod_sig_ctr : std_logic_vector(9 downto 0) := (others => '0');
signal start_det_d1 : std_logic := '0';
signal start_det_d2 : std_logic := '0';
signal start_det_d3 : std_logic := '0';
signal start_det_d4 : std_logic := '0';

begin

IR_out <= IR_out_unmod AND mod_sig;

-- generate slow_clk with f = 300.3 Hz
process(clk)
begin

	if rising_edge(clk) then
	
		if unsigned(slow_clk_ctr) < 53280 then
		
			slow_clk_ctr <= std_logic_vector(unsigned(slow_clk_ctr) + 1);
		else
		
			slow_clk <= NOT slow_clk;
			slow_clk_ctr <= "0000000000000000";
		end if;
	end if;
end process;

-- generate modulating signal with f = 38 kHz
process(clk)
begin

	if rising_edge(clk) then
	
		if unsigned(mod_sig_ctr) < 421 then
		
			mod_sig_ctr <= std_logic_vector(unsigned(mod_sig_ctr) + 1);
		else
		
			mod_sig <= NOT mod_sig;
			mod_sig_ctr <= "0000000000";
		end if;
	end if;
end process;

-- generate delayed start_det signals to allow for delay between receiving and re-transmitting
process(slow_clk)
begin

	if rising_edge(slow_clk) then
	
		start_det_d1 <= start_det;
		start_det_d2 <= start_det_d1;
		start_det_d3 <= start_det_d2;
		start_det_d4 <= start_det_d3;
	end if;
end process;

-- process controlling start_det and bits_in
-- also controls when the value in IR_in is passed to its register
process(slow_clk)
begin

	if rising_edge(slow_clk) then
	
		if bits_in = "0000" then
		
			if IR_in = '1' then
			
				start_det <= '1';
				data_reg(to_integer(unsigned(bits_in))) <= IR_in;
				bits_in <= std_logic_vector(unsigned(bits_in) + 1);
			end if;
		elsif bits_in = "1001" then
		
			start_det <= '0';
			bits_in <= "0000";
		else
		
			data_reg(to_integer(unsigned(bits_in))) <= IR_in;
			bits_in <= std_logic_vector(unsigned(bits_in) + 1);
		end if;
	end if;
end process;

-- passes relevant data into inv_data (discards the start and stop bits)
process(start_det)
begin

	if falling_edge(start_det) then
	
		inv_data(0) <= data_reg(1);
		inv_data(1) <= data_reg(2);
		inv_data(2) <= data_reg(3);
		inv_data(3) <= data_reg(4);
		inv_data(4) <= data_reg(5);
		inv_data(5) <= data_reg(6);
		inv_data(6) <= data_reg(7);
		inv_data(7) <= data_reg(8);
	end if;
end process;

-- process controlling IR_out and the bits_out counter
process(slow_clk)
begin

	if rising_edge(slow_clk) then
	
		if start_det_d4 = '1' AND start_det_d3 = '0' then
	
			IR_out_unmod <= '0';
			bits_out <= std_logic_vector(unsigned(bits_out) + 1);
		elsif bits_out = "1001" then
		
			IR_out_unmod <= '1';
			bits_out <= "0000";
	
		elsif bits_out = "0000" then
		
			IR_out_unmod <= '1';
		else
		
			IR_out_unmod <= inv_data(to_integer(unsigned(bits_out) - 1));
			bits_out <= std_logic_vector(unsigned(bits_out) + 1);
		end if;
	end if;
end process;

end Behavioral;