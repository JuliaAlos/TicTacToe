library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digit_div is
    port (
        num: in std_logic_vector (3 downto 0);
        digitU, digitT: out std_logic_vector (3 downto 0)
    );
end digit_div;

architecture dev5 of digit_div is
begin

    digitT <= std_logic_vector(unsigned(num) / 10);
    digitU <= std_logic_vector(unsigned(num) mod 10);

end dev5;