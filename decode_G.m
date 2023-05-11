function num = decode_G(number_code)
    numbers = [0 1 0 0 1 1 1;
                0 1 1 0 0 1 1;
                0 0 1 1 0 1 1;
                0 1 0 0 0 0 1;
                0 0 1 1 1 0 1;
                0 1 1 1 0 0 1;
                0 0 0 0 1 0 1;
                0 0 1 0 0 0 1;
                0 0 0 1 0 0 1;
                0 0 1 0 1 1 1;
                ];
    % ista ideja kao i kod decode_L
    tmp = sum((numbers == number_code),2);
    num = find(tmp == 7) - 1;
end

