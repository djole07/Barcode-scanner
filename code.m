clc, clear, close all
%%
% Koristimo EAN-13 format barkoda
% Svaki broj je predstavljen sa 7 bitova

% primer_foreground1.png pravi problem jer su linije svetle
img = imread('primer_color1.png');
img_gray = im2gray(img);     % pretvorimo postojecu sliku u monohromatsku
img_double = im2double(img_gray);
img_b = imbinarize(img_double, 0.5);
img_final = im2uint8(img_b);

imshow(img_final);

%% detekcija ivica
ivice = edge(img_final, 'canny');
imshow(ivice)

%%
imshow(img_final);
[y, x] = ginput(1);
y = round(y);
x = round(x);

% presecamo sliku po x kordinati na npr 5 mesta
num_samples = 5;
height = size(img_final, 1);
arr_sample = linspace(0, height, num_samples);

% prikaz linije koja preseca barkod
% img_with_stripe = img_final;
% img_with_stripe(i, :) = 0;
% imshow(img_with_stripe);

img_segment = img_final(x-5:x+5, :);    % vizuelizacija segmenta koja smo odsekli
imshow(img_segment);

%% recimo da smo kliknuli na sliku i da smo ucitali neko i i j
x = 230;
img_line = img_final(x, :); % predstavlja samo sliku na toj liniji koja preseca barkod
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

one_bar_arr = duzine_sort(1:35);    % rucno odvojeno
one_bar_mean = mean(one_bar_arr);
two_bar_arr =  duzine_sort(36:49);
two_bar_mean = mean(two_bar_arr);
three_bar_arr = duzine_sort(50:57);
three_bar_mean = mean(three_bar_arr);
four_bar_arr = duzine_sort(58:end);
four_bar_mean = mean(four_bar_arr);

normalize_arr = [one_bar_mean, two_bar_mean/2, three_bar_mean/3, four_bar_mean/4];
normalize_bar = mean(normalize_arr);

first_value = 1;
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

barcode_center = barcode(1+3:end-3);    % granicnika
prvi_deo = barcode_center(1:42);
drugi_deo = barcode_center(43+5:end);   % zaobidjemo srednji granicnik


%% Izdvajanje levih cifri
R = reshape(prvi_deo, 7, []);   % imamo 7 bitova po cifri pa cemo niz podeliti na podnizove od po 7 
digits_left = zeros(6, 7);      % cifre iz levog dela

for i=1:6
    digits_left(i, :) = R(:, i);
end

% digits_left(2, :);   % druga cifra
%% Izdvajanje druge cifre
R = reshape(drugi_deo, 7, []);  % imamo 7 bitova po cifri pa cemo 
digits_right = zeros(6, 7);     % cifre iz desnog dela

for i=1:6
    digits_right(i, :) = R(:, i);
end

% digits_right(2, :);   % druga cifra

%% Ispitivanje parnosti prvog dela
% Od parnosti prvog dela nam znaci koja ce biti prva cifra, i kako da
% kodiramo ostale cifre

% Ako imamo neparan broj jedinica onda je parnost L, a ako je paran onda je
% parnost G

parity_left = zeros(1, size(digits_left, 1));

% Ako imamo paran broj nula, upisujemo 0 u niz, a kao imamo neparan onda
% upisujemo 1
for i=1:length(parity_left)
    parity_left(i) = rem(sum(digits_left(i, :)), 2);
    % sum ce nam vratiti broj jedinica u nizu, i onda sa rem odredimo da li
    % ih ima paran broj (0 - ima ih, 1 - nema ih)
end

%% Stampamo parnost
parity_str = print_parity(parity_left, true);
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
disp("Barkod sa slike je " + join(string(barcode_final)))

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
    disp("Dati barkod je ispravan.");
else
    disp("Nazalost, barkod nije ispravan.");
end