----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.04.2020 20:04:28
-- Design Name: 
-- Module Name: testbench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity testbench is
--  Port ( );
end testbench;

architecture Behavioral of testbench is

component booth_top is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           mult1 : in STD_LOGIC_VECTOR (7 downto 0);
           mult2 : in STD_LOGIC_VECTOR (7 downto 0);
           start : in STD_LOGIC;
           product_mon : out std_logic_vector(15 downto 0);
           Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0);-- 4 Anode signals
           LED_out : out STD_LOGIC_VECTOR (6 downto 0));-- Cathode patterns of 7-segment display
end component;

signal clk : std_logic;
signal reset : std_logic;
signal mult1 : std_logic_vector(7 downto 0);
signal mult2 : std_logic_vector(7 downto 0);
signal Anode_Activate  : std_logic_vector(3 downto 0);
signal start : std_logic;
signal product_mon : std_logic_vector(15 downto 0);
signal LED_out : STD_LOGIC_VECTOR (6 downto 0);

begin

uut : booth_top port map(
    clk => clk,
    reset => reset,
    mult1 =>mult1,
    mult2 => mult2,
    start => start,
    product_mon => product_mon,
    Anode_Activate => Anode_Activate,
    LED_out => LED_out
    );
    
clk_gen: process
begin
clk <= '1';
wait for 10 ns;
clk <= '0';
wait for 10 ns;
end process clk_gen;


test: process
begin
reset <= '1';
start <= '0';
mult1 <= (others=>'0');
mult2 <= (others=>'0');
wait for 100 ns;
reset <= '0';
-- TEST CASE : 1 -40 x 21 = -840

mult1 <= "11011000";
mult2 <= "00010101";
start <= '1';
wait for 120 ns;
start <= '0';

wait for 100 ns;
-- TEST CASE :  13 x -6 = -78
mult1 <= "00001101";
mult2 <= "11111010";
wait for 40 ns;
start <= '1';
wait for 120 ns;
start <= '0';
wait for 100 ns;

-- TEST CASE :  127 x 127 - = 16129
mult1 <= x"7F";
mult2 <= x"7F";
wait for 40 ns;
start <= '1';
wait for 120 ns;
start <= '0';

wait for 100 ns;
-- TEST CASE :  127 x -128 - = -16129
mult1 <= x"7F";
mult2 <= x"80";
wait for 40 ns;
start <= '1';
wait for 120 ns;
start <= '0';

wait for 100 ns;
-- TEST CASE :  -105 x 72 - = -7560
mult1 <= x"97";
mult2 <= x"48";
wait for 40 ns;
start <= '1';
wait for 120 ns;
start <= '0';

wait for 100 ns;
-- TEST CASE :  -105 x -127 - = -13335
mult1 <= x"97";
mult2 <= x"81";
wait for 40 ns;
start <= '1';
wait for 120 ns;
start <= '0';

wait for 100 ns;
-- TEST CASE :  -105 x -127 - = -13335
mult1 <= x"0A";
mult2 <= x"0A";
wait for 40 ns;
start <= '1';
wait for 120 ns;
start <= '0';

wait;
end process;


end Behavioral;
