function [digitsMatrix] = getBarcodeDigitsMatrix(barcode_arr)
    barcode_center = barcode_arr(1+3:end-3);    % zaobilazimo granicnik sa pocetka i kraja
    first_half = barcode_center(1:42);
    second_half = barcode_center(43+5:end);     % zaobidjemo srednji granicnik
    
    %% Izdvajanje levih cifri binarno
    % prvi_deo je niz koji mi treba da prebacimo u matricu 6x7 gde imamo 6
    % cifri kodiranih binarno sa po 7 bita
    R = reshape(first_half, 7, []);         % imamo 7 bitova po cifri pa cemo niz podeliti na podnizove od po 7 
    digits_left = zeros(6, 7);              % cifre iz levog dela
                                            % cifre se nalaze u redovima
    for i=1:6
        digits_left(i, :) = R(:, i);
    end
    
    % digits_left(2, :);   % druga cifra
    
    %% Izdvajanje druge cifre binarno
    R = reshape(second_half, 7, []);    % imamo 7 bitova po cifri pa cemo niz prebaciti u matricu 
    digits_right = zeros(6, 7);         % cifre iz desnog dela
    
    for i=1:6
        digits_right(i, :) = R(:, i);
    end

    digitsMatrix = [digits_left;digits_right];
end

