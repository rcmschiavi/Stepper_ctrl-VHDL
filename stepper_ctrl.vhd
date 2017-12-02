-- VHDL code for stepper drivers
-- Generate clock and watch the safety end stops

-- Autor: Rodolfo Cavour Moretti Schiavi

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.NUMERIC_STD.all;

entity stepper_ctrl is
  port (
    clk_50Mhz : in  std_logic; -- System clock
	 clk_step  : out std_logic :='0'; -- Output clock for the driver generate with this logic
	 velocity_in : in std_logic_vector(3 downto 0) :="0101"; -- velocity_in with 16 options, can be increased
	 distance_in : in integer range 0 to 511 := 50; -- Millimeters that the stepper will move
	 reset : in std_logic := '1'; -- Reset for cleaning the variables
	 dir_in: in std_logic;	-- Direction of the movement, necessary because the end stop logic is inside the block
	 dir: out std_logic;	-- Output direction for the driver
	 end_stop_p,end_stop_m: in std_logic := '0'; -- End stop for direction 1 and 0
	 end_stop: out std_logic := '0' -- End stop for direction 0
	 );
end stepper_ctrl;

architecture Behavioral of stepper_ctrl is
	signal state: std_logic :='0'; -- Logic signal for the stepper clock
	signal signal_dir: std_logic:=dir_in;
	signal signal_end_stop: std_logic:='0';

begin
   PROCESS (clk_50Mhz, velocity_in, reset,dir_in)

   VARIABLE t :INTEGER RANGE 0 TO 2097151:= 0; -- Time counter
	Variable dividend_acel: INTEGER RANGE 0 TO 5000020:= 5000000;	-- Variable to apply aceleration
   CONSTANT dividend :INTEGER RANGE 0 TO 1048575:= 498047;	-- clock divider for 50MHz to reach values within the stepper necessities
	variable distance: integer range 0 to 65535 := distance_in*90; -- Convertion for 1,8 degree stepper and a step 1,75mm/rev
																						-- to change this use the following equation: distance_in*degress*step/360
  

	BEGIN
		IF (clk_50Mhz'EVENT AND clk_50Mhz='1') THEN
			IF (velocity_in > 0) and (distance > 0) and (reset='0') THEN -- Only allows movimentation if the velocity and the distance is greather than 0
				t := t + 1;
				IF (CONV_INTEGER(velocity_in)*t >= dividend_acel) THEN -- This applied logic is used to increase and decrease the clock with the velocity parameter
				   t := 0;
					state <= not state; -- Changes the clk stepper state
					distance := distance - 1; -- Decrease the distance, because on step occured
				END IF;
			END IF;
			IF (dividend_acel > dividend) and (distance > 10) then -- Verify the distance to apply aceleration
					dividend_acel := dividend_acel -1;
			END IF;
			IF(dividend_acel < 5000000) and (distance < 10) then -- Verify the distance to apply the deceleration
				dividend_acel := dividend_acel + 1;
			END IF;
		END IF;
		IF (reset = '1') then -- Reset the distance variable
			distance:=distance_in*90;
			signal_end_stop<='0';
			signal_dir<=dir_in;
		END IF;
		IF(end_stop_p='1') then -- Verify the end stop +, could be assyncronous, but will not make difference uder this velocities
			-- change the direction and "walk" a little for safety
			distance := 50; 		
			signal_dir <= '0';
		ELSIF(end_stop_m='1') then -- Verify the end stop 
		-- change the direction and "walk" a little for safety
			distance := 50;
			signal_dir <= '1';
		END IF;
	END PROCESS;
	
	-- Apply the signals to the ports
	dir<=signal_dir; 
	clk_step<=state;

end Behavioral;