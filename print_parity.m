function s = print_parity(parity_arr, isPrinted)
% Stampa parnost u standardizovanom formatu. isPrinted omogucava ispis na
% konzolu
    A = parity_arr;
    C = cell(size(A));
    C(A==0)={'G'};
    C(A==1)={'L'};
    s = join(C);
    s = string(s);  % do sad smo imali niz karaktera
    s = strrep(s, ' ', '');
    if isPrinted
        disp("Parnost prvog dela je " + s)
    end
    
end

