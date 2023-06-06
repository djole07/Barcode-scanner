function num = decode_R(number_code)

    numbers = [1 1 1 0 0 1 0;
                1 1 0 0 1 1 0;
                1 1 0 1 1 0 0;
                1 0 0 0 0 1 0;
                1 0 1 1 1 0 0;
                1 0 0 1 1 1 0;
                1 0 1 0 0 0 0;
                1 0 0 0 1 0 0;
                1 0 0 1 0 0 0
                1 1 1 0 1 0 0;
                ];
    % ista ideja kao i kod decode_L
    tmp = sum((numbers == number_code),2);
    num = find(tmp == 7) - 1;
end
