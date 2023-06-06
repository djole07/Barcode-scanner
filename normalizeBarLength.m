function [value] = normalizeBarLength(arr1, arr2, arr3 ,arr4)
% arr1,arr2,arr3,arr4 predstavljaju nizove vrednosti u pikselima za
% segmente duzine 1, 2, 3 ili 4 linije ('bar').
% Ideja je da nadjemo koliko traje linija duzine 1 (1 bar length) i onda
% cemo duzine ostalih naci tako sto cemo podeliti broj piksela u tom
% nekom segmentu sa ovom jedinicnom vredonsti
% Primer (| predstavlja crnu vrednost piksela, a . belu)
% |||...|||......||||||...|||||||||
% Ako smo dobili da je jedinicna duzina jednaka 3 piksela, onda bi izraz
% iznad imao vrednosti 1, 1, 2, 2, 1, 3
    arr1_mean = mean(arr1);
    arr2_mean = mean(arr2);
    arr3_mean = mean(arr3);
    arr4_mean = mean(arr4);
    
    % Zelimo da dobijemo srednju vrednost ne bismo li uticali na sum koji
    % moze da se javi na slici
    normalized_arr = [arr1_mean, arr2_mean/2, arr3_mean/3, arr4_mean/4];
    value = mean(normalized_arr);
end

