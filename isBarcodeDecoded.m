function [isFinish, angle, code] = isBarcodeDecoded(img_b, x, angle, printToConsole)
    try
        x = round(x);
        img_line = img_b(x, :); % predstavlja samo sliku na toj liniji koja preseca barkod
        %img_line = im2bw(img_line);
        % Sad je u img_line kodiran tako da je prazno mesto nula, a crno mesto 1
        % 

        % 255 je bela, 0 je crna
        pocetak = 0;
        for i=1:length(img_line)
            if img_line(i)==0
                pocetak = i;
                break;
            end
        end

        kraj = 0;
        for i=length(img_line):-1:1
            if img_line(i)==0
                kraj = i;
                break;
            end
        end

        img_line_code = img_line(pocetak:kraj);     % ovde imamo samo izdvojen kod
        %% Filtriranje
        % windowSize = 2; 
        % b = (1/windowSize)*ones(1,windowSize);
        % a = 1;
        % 
        % y = round(filter(b,a,img_line_code));
        % y(y < 255/2) = 0;
        % y(y > 255/2) = 255;
        % 
        % plot(0:length(img_line_code)-1,img_line_code)
        % hold on
        % plot(0:length(img_line_code)-1,y)
        % legend('Input Data','Filtered Data')
        % 
        % img_line_code = y;
        %%
        % kod za brojanje trajanja crnog/belog segmenta
        index = 1;
        counter = 1;
        s = struct('value',{},'length',{});
        for i=2:length(img_line_code)
            if img_line_code(i) ~= img_line_code(i-1)
                s(index).value = img_line_code(i-1);
                s(index).length = counter;
                index = index + 1;
                counter = 0;
            else
                counter = counter + 1;
            end
        end
        s(index).value = img_line_code(end);
        s(index).length = counter;

        % Barkod se sastoji od 95 segmenata koji mogu da imaju vrednost 0 ili 1,
        % odnosno da ili da beli ili crni
        % recnik za duzine:
        % 1 bar = 1 segment
        % 2 bar = 2 segmenta
        % 3 bar = 3 segmetna
        % 4 bar = 4 segmenta

        % U strukturi s cuvamo da li smo naisli na crni ili beli skup segmenata i koilko
        % on traje izrazeno u pikselima. Zatim toga zelimo da odredimo koliko
        % piksela odgovara zapravo jednom segmemtu. To cemo raditi tako sto cemo
        % uzeti duzine trajanja iz strukture s, i videti koje su to grupe vrednosti
        % koje se pojavljuju. Npr. ako imamo veliki broj vrednosti oko broja 6,
        % onda je to u ovom slucaju neka srednja vrednost koja predstavlja 1
        % segment. Zatim vrednosti skoncentrisane oko 13 govore da je to vrednost
        % koja je duzine 2 segmenta.
        % Sad, kada smo nasli srednje vrednosti za 1, 2,3 i 4 bara, onda cemo i od
        % toga uzeti srednju vrednost tako sto ako imamo 3 bar, onda cemo tu
        % vrednost normalizovati tako sto cemo je podeliti sa 3, i kada napraivmo
        % tako normalizovani niz, onda iz njega izvucemo srednju vrednost, i
        % dobijamo koliko piksela u proseku ima u 1 bar.

        % Sada, preostalo je jos samo da formiramo konacan barkod tako sto znamo da
        % on sigurno sa crnom bojom (nadalje cemo to obelizavati sa brojem 1), a da
        % nakon toga sledi bela boja (broj 0) nadalje, i imamo trajanje u
        % code_values. Okretanjem boje i dodavanje potrebnog broja cifara dobijamo
        % konacan barkod kao niz

        duzine = vertcat(s.length);
        duzine_sort = sort(duzine);

        %% Nalazenje trajanje segmenata u pikselima
                % ovo moze da pravi opasan problem
        [one_bar_arr, two_bar_arr, three_bar_arr, four_bar_arr] = getBarAray(duzine_sort);
        %% Rucni rezim
        % one_bar_arr = duzine_sort(1:35);
        % two_bar_arr =  duzine_sort(36:49);
        % three_bar_arr = duzine_sort(50:57);
        % four_bar_arr = duzine_sort(58:end);

        %% Dobijanje normalizovane vrednosti za segmet trajanja 1bar
        normalize_bar = normalizeBarLength(one_bar_arr,...
                                            two_bar_arr,...
                                            three_bar_arr,...
                                            four_bar_arr);
        %% Pretvaramo vredonsti niza piksela u binaran zapis barkoda
        % U strukturi s imamo sacuvane redom duzine segmenata u pikselima
        code_values = round(vertcat(s.length)/normalize_bar);


        barcode = [];
        for i=1:length(code_values)
            value = rem(i, 2);
            arr = repmat(value, 1, code_values(i));
            barcode = cat(2, barcode, arr);
        end

        %% Dekodiranje barkoda
        % Gledamo parnost svake cifre. Cifra se sastoji od 7 segmenata.
        % 
        % 3 areas for the start marker (101)
        % 42 areas (seven per digit) to encode digits 2–7, and to encode digit 1 indirectly, as described in the following section
        % 5 areas for the center marker (01010)
        % 42 areas (seven per digit) to encode digits 8–13
        % 3 areas for the end marker (101)

        %% Izdvajanje binarno kodiranih cifri iz barkoda
        % Vraca matricu 12x7 gde imamo po 6 cifara iz prvog i 6 cifara iz drugog dela barkoda koji se kodirani binarno
        digits_matrix = getBarcodeDigitsMatrix(barcode);
        digits_left = digits_matrix(1:6, :);
        digits_right = digits_matrix(7:end, :);
        %% Ispitivanje parnosti prvog dela
        % Od parnosti prvog dela nam znaci koja ce biti prva cifra, i kako da
        % kodiramo ostale cifre

        % Ako imamo neparan broj jedinica onda je parnost L, a ako je paran onda je
        % parnost G

        parity_left = findParityArray(digits_left);
        %% Stampamo parnost
        parity_str = print_parity(parity_left, printToConsole);
        %% Odredjivanje pocetne cifre

        % Kod sifri za cifre od 0 do 9
        arr_prva_cifra = ["LLLLLL";
                           "LLGLGG";
                           "LLGGLG";
                           "LLGGGL";
                           "LGLLGG";
                           "LGGLLG";
                           "LGGGLL";
                           "LGLGLG";
                           "LGLGGL";
                           "LGGLGL"
                           ];

        if(parity_str == "GGGGGG")
            angle = 180 + angle;
            barcode = barcode(end:-1:1);
            digits_matrix = getBarcodeDigitsMatrix(barcode);
            digits_left = digits_matrix(1:6, :);
            digits_right = digits_matrix(7:end, :);

            parity_left = findParityArray(digits_left);
            parity_str = print_parity(parity_left, printToConsole);
        end

        % Sada poredimo nas parity_str sa nizom postojecih prvih vrednosti
        % Za izlaz dobijamo niz logicih 0 ili 1, gde 1 predstavlja poklapanje naseg
        % stringa
        % Ukoliko uradimo find() nad tim rezultatom dobicemo indeks na kom smo
        % imali poklapanje
        % Posto nam cifre idu od 0 do 9, onda samo oduzmemo 1 od dobijenog
        % rezultata i imamo pocetnu cifru
        arr_compare = (arr_prva_cifra == parity_str);
        pocetna_cifra = find(arr_compare == 1) - 1;

        %% Nalazenje prve grupe od 6 cifara
        % Posto imamo parnost, onda nam se cifra koduje zavisno od toga

        numbers1 = zeros(1, 6);
        for i=1:size(digits_left, 1)
            numbers1(i) = calculate_number(parity_str{1}(i), digits_left(i,:));
            % parity_str{1}(i) nam izdvaja slovo po slovo iz stringa parnosti
        end
        %% Nalazenje druge grupe cifara
        % uzeli smo pretpostavku je parnost kod druge grupe GGGGGG,  da ne proveravamo jer se u tom
        % slucaju cifra kodira R kodom
        % Svakako cemo sa cheksum-om potvrditi validnost dobijenog koda

        numbers2 = zeros(1, 6);
        for i=1:size(digits_right, 1)
            numbers2(i) = calculate_number('R', digits_right(i,:));
        end

        %% Sklapanje boda u jedan
        barcode_final = cat(2, pocetna_cifra, numbers1, numbers2);

        s = string(barcode_final);  % do sad smo imali niz karaktera
        s = join(s);
        s = strrep(s, ' ', '');

        code = s;

        if(printToConsole)
            disp("Barkod sa slike je " + s);
        end

        %% Provera cheksum-e

        partial_sum = 0;
        % uzimamo jednu cifru manje, posto poslednju cifru proveravamo sa cheksum-om
        for i=1:length(barcode_final)-1
            if rem(i ,2) == 0
                factor = 3;
            else
                factor = 1;
            end

            partial_sum = partial_sum + factor*barcode_final(i);
        end
        % checksum racunamo tako sto trazimo prvi veci broj od partial_sum deljiv
        % sa 10, i gledamo koliko treba da dodamo na partial_sum ne bismo li dosli
        % do tog broja

        % To mozemo da uradimo tako sto uzmemo moduo10 od te sume, i zatim dobijeni
        % broj uduzmemo od 10
        checksum = 10 - (rem(partial_sum, 10));

        if barcode_final(end) == checksum
            if(printToConsole)
                disp("Dati barkod je ispravan.");
            end
            isFinish = true;
        else
            if(printToConsole)
                disp("Nazalost, barkod nije ispravan.");
            end
            isFinish = false;
        end
    catch
        isFinish = false;
        code = "ERROR";
        angle = 0;
    end
end

