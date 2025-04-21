library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Elevator is
    Port ( 
        clk, reset : in STD_LOGIC;
        key , Overweight_sensor: in STD_LOGIC;
        Request_Button, Request_Floor : in STD_LOGIC_VECTOR (2 downto 0);
        Current_Floor_sensor : out STD_LOGIC_VECTOR (2 downto 0);
        Motor_Up_floor, Motor_Down_floor, Stop_Motor, Door : out STD_LOGIC
    );
end Elevator;

architecture Behavioral of Elevator is
    type State is (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10); -- Define states
    signal pr, nxt: State; -- Current and next state
    signal Current_Floor: STD_LOGIC_VECTOR(2 downto 0); -- Current floor as vector

begin

-- Sequential Process: Update current state and synchronize floor transitions
seq: process (clk)
begin
    if rising_edge(clk) then 
        if reset = '1' then 
            pr <= T1; -- Reset state
            Current_Floor <= "000"; -- Reset to ground floor
        else 
            pr <= nxt; -- Move to the next state
				
            -- Update current floor during transitions
            if nxt = T3  or nxt = T8 then
                Current_Floor <= Current_Floor + "001"; -- Move up
            elsif nxt = T5 or nxt = T10 then
                Current_Floor <= Current_Floor - "001"; -- Move down
            end if;
        end if;
    end if;
end process seq;

-- Combinational Process: Determine next state and control signals
comb: process (pr, Request_Button, Request_Floor, key, Current_Floor)
begin

    nxt <= pr; -- Default: remain in current state
	 
    case pr is
        -- Idle state
        when T1 =>
		-- Default outputs
	 Motor_Up_floor <= '0';
	 Motor_Down_floor <= '0';
	 Stop_Motor <= '1';
	 Door <= '1';
				 
            if Request_Button >= "000" then
                nxt <= T2; -- Go to request evaluation
            end if;

        -- Evaluate button request
        when T2 =>
	    Door <= '0';
            if Request_Button > Current_Floor then
                nxt <= T3; -- Move up
            elsif Request_Button = Current_Floor then
                nxt <= T4; -- Stop and open door
            else
                nxt <= T5; -- Move down
            end if;

        -- Moving up
        when T3 =>
             Motor_Up_floor <= '1'; -- Elevator moves 
	     Motor_Down_floor <= '0';
	     Stop_Motor <= '0';
				 	 
            if Request_Button = Current_Floor then
                nxt <= T4; -- Stop when target is reached
            end if;

        -- Stop and open door
        when T4 =>
            Motor_Up_floor <= '0'; 
	    Motor_Down_floor <= '0';
            Stop_Motor <= '1';
            Door <= '1';
            nxt <= T6; -- Wait for key input to move again

        -- Moving down
        when T5 =>
            Motor_Down_floor <= '1'; -- Elevator moves down
	    Motor_Up_floor <= '0'; 
            Stop_Motor <= '0';
            Door <= '0';

            if Request_Button = Current_Floor then
                nxt <= T4; -- Stop when target is reached
            end if;

        -- Wait for key input
        when T6 =>
            if key = '1' then 
                if Request_Floor >= "000" then 
			if Overweight_sensor = '0' then
                    nxt <= T7; -- Evaluate floor request
                  end if;
                end if;
				end if;

        -- Evaluate floor request
        when T7 =>
            Door <= '0';
            if Request_Floor > Current_Floor then
                nxt <= T8; -- Move up
            elsif Request_Floor = Current_Floor then
                nxt <= T9; -- Open door at the requested floor
            else
                nxt <= T10; -- Move down
            end if;

        -- Moving up to the requested floor
        when T8 =>
            Motor_Up_floor <= '1';
	    Motor_Down_floor <= '0';
            Stop_Motor <= '0';

            if Request_Floor = Current_Floor then
                nxt <= T9; -- Stop when target is reached
            end if;

        -- Open door at the requested floor
        when T9 =>
	    Motor_Up_floor <= '0'; 
	    Motor_Down_floor <= '0';
            Stop_Motor <= '1';
            Door <= '1';
            nxt <= T1; -- Go back to idle state

        -- Moving down to the requested floor
        when T10 =>
            Motor_Down_floor <= '1';
	    Motor_Up_floor <= '0'; 
            Stop_Motor <= '0';
            Door <= '0';

            if Request_Floor = Current_Floor then
                nxt <= T9; -- Stop when target is reached
            end if;

    end case;
end process comb;

-- Output current floor to the sensor
Current_Floor_sensor <= Current_Floor;

end Behavioral;