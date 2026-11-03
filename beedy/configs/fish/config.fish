function fish_greeting
    if test (tput cols 2>/dev/null || echo 80) -ge 70
        fastfetch
    end
end