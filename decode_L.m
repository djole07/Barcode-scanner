function num = decode_L(number_code)
    numbers = [0 0 0 1 1 0 1;
                0 0 1 1 0 0 1;
                0 0 1 0 0 1 1;
                0 1 1 1 1 0 1;
                0 1 0 0 0 1 1;
                0 1 1 0 0 0 1;
                0 1 0 1 1 1 1;
                0 1 1 1 0 1 1;
                0 1 1 0 1 1 1;
                0 0 0 1 0 1 1];
    % ideja je da prvo uporedimo 2 nas kod sa matricom numbers, koja
    % predstavlja kodirane brojeve. Kao rezultat cemo dobiti novu martricu
    % koja ce sa 1 oznacavati mesta kgde imamo poklapanja naseg niza sa
    % sa matricom numbers. Ukoliko saberemo po vrstama tu matricu, onda
    % tamo gde se javi broj 7, odnosno gde su nam se svi elementi poklopili
    % znaci da je to indeks sa zeljenim brojem. Oduzimanjem sa 1 dobijamo
    % konacan broj
    tmp = sum((numbers == number_code),2);
    num = find(tmp == 7) - 1;
end

