function [parity_arr] = findParityArray(digits_matrix)
    % digits_matrix predstavlja cifre iz barkoda kojih ima 6, gde je svaka
    % cifra predstavljena sa 7 bitova. Cifre se nalze u redovima martrice,
    % dok se u kolonama nalaze bitovi koji opisuju datu cifru

    parity_arr = zeros(1, size(digits_matrix, 1));

    % Ako imamo paran broj jedinica, upisujemo 0 u niz, a kao imamo neparan onda
    % upisujemo 1
    for i=1:length(parity_arr)
        parity_arr(i) = rem(sum(digits_matrix(i, :)), 2);
        % sum ce nam vratiti broj jedinica u nizu, i onda sa rem odredimo da li
        % ih ima paran broj (0 - ima ih, 1 - nema ih)
    end
end

