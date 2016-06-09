LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.numeric_std.all;

--Pong game. Uses Ps/2 keyboard and vga.
--Controls: Key0 resets. Left player uses keys W and S, right player uses O and L.


ENTITY pong IS

   PORT(pixel_row_in, pixel_col_in		: IN std_logic_vector(9 DOWNTO 0);
        Red,Green,Blue 				: OUT std_logic_vector(9 downto 0);
        Vert_sync, lpad_up, lpad_dn, rpad_up, rpad_dn, resetn, clock_50	: IN std_logic);	
		
END pong;

architecture a of pong is

component char_rom
	PORT( 	character_address :IN STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			font_row, font_col : IN STD_LOGIC_VECTOR( 2 DOWNTO 0 );
			rom_mux_output : OUT STD_LOGIC;
			clock : in std_logic); 
end component;

signal char_addr : std_logic_vector(5 downto 0);
signal font_r : std_logic_vector(2 downto 0);
signal font_c : std_logic_vector(2 downto 0);
signal mux_out : std_logic;

constant draw_on : std_logic_vector(9 downto 0) := (others => '1');
constant draw_off : std_logic_vector(9 downto 0) := (others => '0');

constant topbar_y1 : integer := 50;
constant topbar_y2 : integer := 70;

constant botbar_y1 : integer := 410;
constant botbar_y2 : integer := 430;

constant lpad_x1 : integer := 15;
constant lpad_x2 : integer := 30;
signal lpad_y1 : integer range 0 to 480 := 100;
signal lpad_y2 : integer range 0 to 480 := 130;

constant rpad_x1 : integer := 610;
constant rpad_x2 : integer := 625;
signal rpad_y1 : integer range 0 to 480 := 100;
signal rpad_y2 : integer range 0 to 480 := 130;

signal ball_x1 : integer range 0 to 640 := 320;
signal ball_x2 : integer range 0 to 640 := 330;
signal ball_y1 : integer range 0 to 480 := 240;
signal ball_y2 : integer range 0 to 480 := 250;

signal ball_yvel : integer range -5 to 5 := 2;
signal ball_xvel : integer range -5 to 5 := 2;

signal lpad_vel : integer range -5 to 5 := 2;
signal rpad_vel : integer range -5 to 5 := 2;

signal disp_en : std_logic_vector(9 downto 0);

signal pixel_row : integer range 0 to 480;
signal pixel_col : integer range 0 to 640;

signal l_score : integer range 0 to 15 := 0;
signal r_score : integer range 0 to 15 := 0;

signal l_win : std_logic := '0';
signal r_win : std_logic := '0';
signal game_play : std_logic := '1';

signal game_clock : std_logic;

begin  

c1 : char_rom port map(	character_address => char_addr,
					font_row => font_r,
					font_col => font_c,
					rom_mux_output => mux_out,
					clock => clock_50);

game_clock <= (game_play or not(resetn)) and vert_sync;

red <= disp_en;
green <= disp_en;
blue <= disp_en;

pixel_row <= to_integer(unsigned(pixel_row_in));
pixel_col <= to_integer(unsigned(pixel_col_in));

----------------display logic-------------------
font_r <= pixel_row_in(4 downto 2);
font_c <= pixel_col_in(4 downto 2);

process(pixel_row_in, pixel_col_in)
begin

if pixel_row < 32 then	
	
	if pixel_col < 32 then --display left player's score
		char_addr <= std_logic_vector(to_unsigned(l_score + 48, 6));		
	elsif pixel_col > 607 then --display right player's score
		char_addr <= std_logic_vector(to_unsigned(r_score + 48, 6));	
	else
		if game_play = '0' then
			case pixel_col is 
				when 192 to 223 => char_addr <= ("011111" and (char_addr'range => l_win));
				when 224 to 255 => char_addr <= "010111";
				when 256 to 287 => char_addr <= "001001";
				when 288 to 319 => char_addr <= "001110";
				when 320 to 351 => char_addr <= "001110";
				when 352 to 383 => char_addr <= "000101";
				when 384 to 415 => char_addr <= "010010";
				when 416 to 447 => char_addr <= ("011110" and (char_addr'range => r_win));
				when others => char_addr <= "000000";
			end case;
		else
			disp_en <= draw_off;
		end if;
	end if;
	
	if mux_out = '1' then
		disp_en <= draw_on;
	else
		disp_en <= draw_off;
	end if;
	
else --display the rest of the game

	if ((pixel_row >= topbar_y1) and (pixel_row <= topbar_y2)) then --draw top boundary
		disp_en <= draw_on;	
	elsif ((pixel_row >= botbar_y1) and (pixel_row <= botbar_y2)) then --draw bottom boundary
		disp_en <= draw_on;
	elsif ((pixel_row >= lpad_y1) and (pixel_row <= lpad_y2) and (pixel_col >= lpad_x1) and (pixel_col <= lpad_x2)) then --draw left paddle
		disp_en <= draw_on;
	elsif ((pixel_row >= rpad_y1) and (pixel_row <= rpad_y2) and (pixel_col >= rpad_x1) and (pixel_col <= rpad_x2)) then --draw right paddle
		disp_en <= draw_on;
	elsif ((pixel_row >= ball_y1) and (pixel_row <= ball_y2) and (pixel_col >= ball_x1) and (pixel_col <= ball_x2)) then --draw ball
		disp_en <= draw_on;
	else
		disp_en <= draw_off;--draw nothing
	end if;
end if;
end process;

----------------game logic-----------------

process
begin
	wait until game_clock ='1';
	
	if resetn = '0' then
		lpad_y1 <= 100;
		lpad_y2 <= 130;

		rpad_y1 <= 100;
		rpad_y2 <= 130;
		
		ball_x1 <= 320;
		ball_x2 <= 330;
		ball_y1 <= 240;
		ball_y2 <= 250;
		
		ball_yvel <= 2;
		ball_xvel <= 2;
		
		lpad_vel <= 2;
		rpad_vel <= 2;
		
		l_score <= 0;
		r_score <= 0;
		
		l_win <= '0';
		r_win <= '0';
		game_play <= '1';
	else
	
		ball_x1 <= ball_x1 + ball_xvel; --move the ball
		ball_y1 <= ball_y1 + ball_yvel;
		ball_x2 <= ball_x2 + ball_xvel;
		ball_y2 <= ball_y2 + ball_yvel;
		
	
		---------------top and bottom bar collision----------------
	
	
		if ball_y1 < topbar_y2 then --check top and bottom collisions and bounce
			ball_yvel <= -ball_yvel;
			ball_y1 <= ball_y1 + (topbar_y2 - ball_y1 + 5) + ball_yvel;
			ball_y2 <= ball_y2 + (topbar_y2 - ball_y1 + 5) + ball_yvel;
		elsif ball_y2 > botbar_y1 then
			ball_yvel <= -ball_yvel;
			ball_y1 <= ball_y1 - (ball_y2 - botbar_y1 + 5) - ball_yvel;
			ball_y2 <= ball_y2 - (ball_y2 - botbar_y1 + 5) - ball_yvel;
		end if;
		
		
		---------------paddle collision and scoring-----------------
		
		
		if (ball_x1 < lpad_x2) and ((ball_y2 < lpad_y1) or (ball_y1 > lpad_y2)) then --check left out of bounds and reset
			ball_x1 <= 320;
			ball_x2 <= 330;
			ball_y1 <= 240;
			ball_y2 <= 250;
			
			if r_score = 9 then
				r_win <= '1';
				game_play <= '0';
				r_score <= r_score + 1;
			else
				r_score <= r_score + 1;
			end if;
			
			if lpad_vel < 4 then --speed up the game after out of bounds
				ball_xvel <= -(abs(ball_xvel) + 1);
				ball_yvel <= abs(ball_yvel) + 1;
				lpad_vel <= lpad_vel + 1;
				rpad_vel <= rpad_vel + 1;
			else 
				ball_xvel <= -ball_yvel;
				ball_yvel <= -ball_xvel;
			end if;
			
		elsif ball_x1 < lpad_x2 then --check left collision and bounce
			ball_xvel <= -ball_xvel;
			ball_x1 <= ball_x1 + (lpad_x2 - ball_x1 + 5) + ball_xvel;
			ball_x2 <= ball_x2 + (lpad_x2 - ball_x1 + 5) + ball_xvel;
		end if;
		
		if (ball_x2 > rpad_x1) and ((ball_y2 < rpad_y1) or (ball_y1 > rpad_y2)) then --check right out of bounds and reset
			ball_x1 <= 320;
			ball_x2 <= 330;
			ball_y1 <= 240;
			ball_y2 <= 250;
			
			if l_score = 9 then
				l_win <= '1';
				game_play <= '0';
				l_score <= l_score + 1;
			else
				l_score <= l_score + 1;
			end if;
			
			if lpad_vel < 4 then --same as left out of bounds
				ball_xvel <= -(abs(ball_xvel) + 1);
				ball_yvel <= abs(ball_yvel) + 1;
				lpad_vel <= lpad_vel + 1;
				rpad_vel <= rpad_vel + 1;
			else
				ball_xvel <= -ball_yvel;
				ball_yvel <= -ball_xvel;
			end if;
			
		elsif ball_x2 > rpad_x1 then --check right collision and bounce
			ball_xvel <= -ball_xvel;
			ball_x1 <= ball_x1 - (ball_x2 - rpad_x1 + 5) - ball_xvel;
			ball_x2 <= ball_x2 - (ball_x2 - rpad_x1 + 5) - ball_xvel;
		end if;
		
		--------------paddle movement--------------
		
		if lpad_up = '1' and lpad_dn = '0' then --move left paddle up
			
			if lpad_y1 > topbar_y2 then --check if not colliding
				lpad_y1 <= lpad_y1 - lpad_vel;
				lpad_y2 <= lpad_y2 - lpad_vel;
			end if;
			
		elsif lpad_up = '0' and lpad_dn = '1' then --move left paddle down
		
			if lpad_y2 < botbar_y1 then --check if not colliding
				lpad_y1 <= lpad_y1 + lpad_vel;
				lpad_y2 <= lpad_y2 + lpad_vel;
			end if;
			
		end if;
		
		if rpad_up = '1' and rpad_dn = '0' then --move right paddle up
			
			if rpad_y1 > topbar_y2 then
				rpad_y1 <= rpad_y1 - rpad_vel;
				rpad_y2 <= rpad_y2 - rpad_vel;
			end if;
			
		elsif rpad_up = '0' and rpad_dn = '1' then --move right paddle down
		
			if rpad_y2 < botbar_y1 then
				rpad_y1 <= rpad_y1 + rpad_vel;
				rpad_y2 <= rpad_y2 + rpad_vel;
			end if;
			
		end if;
	end if;
end process;

END a;

