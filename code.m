clc, clear, close all
%%
% Koristimo EAN-13 format barkoda
% Svaki broj je predstavljen sa 7 bitova

% primer_foreground1.png pravi problem jer su linije svetle
img = imread('real10.jpg');

figure(1)
imshow(img)
title('Originalna slika')


[y,x] = ginput(2);
x = round(x);
y = round(y);
I = img(min(x):max(x), min(y):max(y));

figure(2)
imshow(I);
title('Izrezana slika');

img_gray = im2gray(I);     % pretvorimo postojecu sliku u monohromatsku
img_double = im2double(img_gray);

Iblur = imgaussfilt(img_double,1.5);
img_double = imsharpen(Iblur,'Radius',2,'Amount',1);

level = graythresh(img_double);
img_b = imbinarize(img_double, level);

img_final = im2uint8(img_b);

figure(3)
imshow(img_final);
title('Finalna binarizovana slika')

se = strel('square', 4);
afterOpening = imopen(img_b, se);

%% 2D FFT za detekciju rotacije
F = fft2(img_final);
F = fftshift(F); % Center FFT

F = abs(F); % Get the magnitude
F = log(F+1); % Use log, for perceptual scaling, and +1 since log(0) is undefined
F = mat2gray(F); % Use mat2gray to scale the image between 0 and 1
img_freq = abs(F);

Iblur = imgaussfilt(img_freq,1.5);
img_freq = imsharpen(Iblur,'Radius',2,'Amount',1);


tmp = imbinarize(img_freq, 0.75);
% tmp = im2uint8(tmp);
figure, imshow(img_freq,[]), title('Spektar slike') % Display the result
figure, imshow(tmp), title('Prikaz spektra kog smo binarizovali');
%% Odredjivanje ugla
[x,y] = find(tmp == true);
X = [ones(length(x),1) x];
Y = [ones(length(y),1) y];

b = X\y;
b2 = Y\x;

yCalc = X*b;
xCalc = Y*b2;

figure
scatter(y,x);
hold on
plot(y, xCalc, '-')
legend('Ulazni podaci', 'Aproksimacija prave');

% k = b(2);   % nagib  krive
% alfa = atand(k);
% angle = 90 + alfa;

k = b2(2);
alfa = atand(k);
angle = alfa;

% J = imrotate(img_final, -angle,"nearest", "crop");
J = imrotate(img_final, angle,"nearest", "loose");
figure
imshow(J)
%% Original slika, rotirana, selektovan deo gde je barkod i binarizovana
% J = imrotate(img_double, angle,"nearest", "crop");
J = ~imrotate(~img_final, angle,"nearest", "loose");
% Razlog za ovu duplu negaciju je jer ako samo crop-ujemo onda ce matalb
% dodati crnu pozadinu tamo gde nema slike, a posto mi hocemo da ta
% pozadina bude bela onda negiramo pocetnu sliku, on doda crnu pozadinu, i
% onda sve ponovo negiramo.

% a = im2double(afterOpening);
% J = J .* a;
figure
imshow(J);
title('Slika nakon rotacije');
% 
% [y,x] = ginput(2);
% x = round(x);
% y = round(y);
% I = J(min(x):max(x), min(y):max(y));

Iblur = imgaussfilt(im2double(J),2);

level = graythresh(Iblur);
img_b = imbinarize(Iblur, level);
figure
imshow(img_b);
title('Slika nakon binarizacije')
%% (visak) Neki kod za izdvajanje linija barkoda (rizicno)
% se = strel('square', round(size(I,1)/20));
% I = imbinarize(Iblur, 0.4);
% J = I;
% afterOpening = imclose(J, se);
% K = afterOpening - J;
% K = ~K;
% figure
% imshow(K,[]);

%% (visak, reseno u liniji 80, gde smo prosledili negirano img_final cime
% smo u startu obrisali coskove. Najbolje probaj sa i bez te negacije, i videces
% da kada se stavi negacija obrise se ono sto matlab doda nakon  rotacije
% slike.)
% 
% Brisanje pozadine, druga verzija
% y = imfill(J);
% imshow(J);

%% detekcija %ivica
% ivice = edge(img_final, 'canny');
% imshow(ivice)

%% Uzimanje n semplova sa slike
% [y, x] = ginput(1);
% y = round(y);
% x = round(x);
% 
% % presecamo sliku po x kordinati na npr 5 mesta
% num_samples = 5;
% height = size(img_final, 1);
% arr_sample = linspace(0, height, num_samples);
% 
% % prikaz linije koja preseca barkod
% % img_with_stripe = img_final;
% % img_with_stripe(i, :) = 0;
% % imshow(img_with_stripe);
% 
% img_segment = img_final(x-5:x+5, :);    % vizuelizacija segmenta koja smo odsekli
% imshow(img_segment);

%% recimo da smo kliknuli na sliku i da smo ucitali neko x i y
imshow(img_b,[]);
[y, x] = ginput(1);

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
first_value = 1;
code_values = round(vertcat(s.length)/normalize_bar);


barcode = [];
for i=1:length(code_values)
    value = rem(i, 2);
    arr = repmat(value, 1, code_values(i));
    barcode = cat(2, barcode, arr);
end

if(length(barcode) > 95) 
    f = errordlg('Neuspelo citanje barkoda','Neuspesno');
end



%% Dekodiranje barkoda
% Gledamo parnost svake cifre. Cifra se sastoji od 7 segmenata.
% 
% 3 areas for the start marker (101)
% 42 areas (seven per digit) to encode digits 2–7, and to encode digit 1 indirectly, as described in the following section
% 5 areas for the center marker (01010)
% 42 areas (seven per digit) to encode digits 8–13
% 3 areas for the end marker (101)

barcode_center = barcode(1+3:end-3);    % zaobilazimo granicnik sa pocetka i kraja
prvi_deo = barcode_center(1:42);
drugi_deo = barcode_center(43+5:end);   % zaobidjemo srednji granicnik

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
               
if(parity_str == "GGGGGG")
    angle = 180 + angle;
    barcode = barcode(end:-1:1);
    digits_matrix = getBarcodeDigitsMatrix(barcode);
    digits_left = digits_matrix(1:6, :);
    digits_right = digits_matrix(7:end, :);
    
    parity_left = findParityArray(digits_left);
    parity_str = print_parity(parity_left, true);
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
    
disp("Barkod sa slike je " + s)

msgbox("Barkod sa slike je " + s + " i je rotiran za " + abs(round(angle)) + "°");

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