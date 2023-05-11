function num = calculate_number(letter, number_code)
    if letter == 'L'
        num = decode_L(number_code);
    end
    if letter == 'G'
        num = decode_G(number_code);
    end
    if letter == 'R'
        num = decode_R(number_code);
    end
    
end

