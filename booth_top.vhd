----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.04.2020 19:07:39
-- Design Name: 
-- Module Name: booth_top - Behavioral
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
use ieee.numeric_std.all;               -- Needed for shifts
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity booth_top is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           mult1 : in STD_LOGIC_VECTOR (7 downto 0);
           mult2 : in STD_LOGIC_VECTOR (7 downto 0);
           start : in std_logic;
           product_mon : out std_logic_vector(15 downto 0);
           Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0);-- 4 Anode signals
           LED_out : out STD_LOGIC_VECTOR (6 downto 0));-- Cathode patterns of 7-segment display
end booth_top;

architecture Behavioral of booth_top is

signal acc_extended : std_logic_vector(20 downto 0);    -- Extended Accumulator
signal acc          : std_logic_vector(9 downto 0);     -- Accumulator      
signal q            : std_logic_vector(9 downto 0);     -- q <= multiplier gets shifted
signal q_1          : std_logic;                        -- LSB[q] ; Initiallizaed to '0' at START
signal count_reset  : std_logic;
signal count        : std_logic_vector(3 downto 0);
signal booth_input  : std_logic_vector(2 downto 0);
signal partial_prod : std_logic_vector(9 downto 0);
signal done         : std_logic;
signal count_en         : std_logic;
signal max          : std_logic;
signal mult1_10     : std_logic_vector(9 downto 0);  -- Sign extended Input
signal mult2_10     : std_logic_vector(9 downto 0);  -- Sign extended Input
--FSM Related
type statetype is (s0,s1,s2,s3);
signal pr_state     : statetype;
signal nx_state     : statetype;
--------------------------------------
-- Seven Segment Related
signal prod : std_logic_vector(15 downto 0);
signal one_second_counter: STD_LOGIC_VECTOR (27 downto 0);
-- counter for generating 1-second clock enable
signal one_second_enable: std_logic;
-- one second enable for counting numbers
signal displayed_number: STD_LOGIC_VECTOR (15 downto 0);
-- counting decimal number to be displayed on 4-digit 7-segment display
signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
-- creating 10.5ms refresh period
signal LED_activating_counter: std_logic_vector(1 downto 0);
-- the other 2-bit for creating 4 LED-activating signals
-- count         0    ->  1  ->  2  ->  3
-- activates    LED1    LED2   LED3   LED4
-- and repeat
begin  
-------------Combinatorial Logic ---------
mult1_10 <= "00"&mult1 when mult1(7) = '0' else "11"&mult1;
mult2_10 <= "00"&mult2 when mult2(7) = '0' else "11"&mult2;
acc <=  acc_extended(20 downto 11);
q <= acc_extended(10 downto 1);
q_1 <= acc_extended(0);
product_mon <= prod;
--stage_sum <= acc + partial_prod;
booth_input <= acc_extended(2 downto 0);
max <= '1' when count = 5 else '0';
-- Partial Product Generation
partial_prod <= mult1_10 when (booth_input = "001" or booth_input = "010")  else
                not (mult1_10)+1 when (booth_input = "101" or booth_input = "110")  else
                std_logic_vector(shift_left(signed(mult1_10),1)) when (booth_input = "011")  else
                std_logic_vector(shift_left(signed(not(mult1_10)+1),1)) when (booth_input = "100") else
                (others=>'0');
-----------------Product Register--------------
product_output: process(clk,reset)
begin
    if (reset ='1') then
        prod <= (others=>'0');
    elsif(rising_edge(clk)) then
        if (max ='1') then
            prod <= acc_extended(18 downto 3);
        end if;
    end if;
end process product_output;
-----------------------------------------------
acc_gen: process(clk,reset)
begin
if (reset = '1') then
    acc_extended <= (others=>'0');
elsif(rising_edge(clk)) then
    if (count = "000") then
        acc_extended(10 downto 1) <= mult2_10;
        acc_extended(20 downto 11) <= (others=>'0');
        acc_extended(0) <= '0';
    elsif (count <= 4) then
        acc_extended <= std_logic_vector(shift_right(signed(acc_extended+(partial_prod&"00000000000")),2));
    end if;
end if;
end process acc_gen;

process (clk,count_reset,reset)
begin
if((reset or count_reset) = '1') then
count <= (others=>'0');
elsif(rising_edge(clk)) then
    if (count_en = '1') then
        count <= count + 1;
    end if;
    
end if;
end process;

----------Control Path--------------
control_fsm: process(pr_state, clk,reset,start,max,count)
begin
    case pr_state is
        when s0=>
            done <= '1';
            if (start ='1') then
                nx_state <= s1;
                count_en <= '1';
                count_reset <= '1';
             else 
                nx_state <= s0;
                count_en <= '0';
                count_reset <= '0';
             end if;
         when s1=>
            count_en <= '1';
            count_reset <= '0';
            done <= '0';
            if (count = 4) then
                nx_state <= s2;
            else
                nx_state <= s1;
            end if;
         when s2=>
            count_en <= '0';
            count_reset <= '0';
            done <= '1';
            if (start = '0') then
                nx_state <= s0;
            else
                nx_state <= s2;
             end if;
          when others=>
          count_en <= '0';
          done <= '0';
          count_reset <= '0';
          nx_state <= s0;
    end case;
end process control_fsm;      

-- FSM Flip Flops
conff : process(clk,reset)
begin
    if (reset = '1') then
        pr_state <= s0;
    elsif(rising_edge(clk)) then
        pr_state <= nx_state;
    end if;
end process;
    
-- Seven Segment Related

process(LED_BCD)
begin
    case LED_BCD is
    when "0000" => LED_out <= "0000001"; -- "0"     
    when "0001" => LED_out <= "1001111"; -- "1" 
    when "0010" => LED_out <= "0010010"; -- "2" 
    when "0011" => LED_out <= "0000110"; -- "3" 
    when "0100" => LED_out <= "1001100"; -- "4" 
    when "0101" => LED_out <= "0100100"; -- "5" 
    when "0110" => LED_out <= "0100000"; -- "6" 
    when "0111" => LED_out <= "0001111"; -- "7" 
    when "1000" => LED_out <= "0000000"; -- "8"     
    when "1001" => LED_out <= "0000100"; -- "9" 
    when "1010" => LED_out <= "0000010"; -- a
    when "1011" => LED_out <= "1100000"; -- b
    when "1100" => LED_out <= "0110001"; -- C
    when "1101" => LED_out <= "1000010"; -- d
    when "1110" => LED_out <= "0110000"; -- E
    when "1111" => LED_out <= "0111000"; -- F
    when others => LED_out <= "0111000"; -- F
    end case;
end process;

-- 7-segment display controller
-- generate refresh period of 10.5ms
process(clk,reset)
begin 
    if(reset='1') then
        refresh_counter <= (others => '0');
    elsif(rising_edge(clk)) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;

 LED_activating_counter <= refresh_counter(19 downto 18);
-- 4-to-1 MUX to generate anode activating signals for 4 LEDs 
process(LED_activating_counter)
begin
    case LED_activating_counter is
    when "00" =>
        Anode_Activate <= "0111"; 
        -- activate LED1 and Deactivate LED2, LED3, LED4
        LED_BCD <= prod(15 downto 12);
        -- the first hex digit of the 16-bit number
    when "01" =>
        Anode_Activate <= "1011"; 
        -- activate LED2 and Deactivate LED1, LED3, LED4
        LED_BCD <= prod(11 downto 8);
        -- the second hex digit of the 16-bit number
    when "10" =>
        Anode_Activate <= "1101"; 
        -- activate LED3 and Deactivate LED2, LED1, LED4
        LED_BCD <= prod(7 downto 4);
        -- the third hex digit of the 16-bit number
    when "11" =>
        Anode_Activate <= "1110"; 
        -- activate LED4 and Deactivate LED2, LED3, LED1
        LED_BCD <= prod(3 downto 0);
        -- the fourth hex digit of the 16-bit number    
    when others =>
           Anode_Activate <= "1110"; 
    -- activate LED4 and Deactivate LED2, LED3, LED1
    LED_BCD <= prod(3 downto 0);
    -- the fourth hex digit of the 16-bit number        
    end case;
end process;





end Behavioral;
