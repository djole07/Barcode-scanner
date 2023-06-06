clc, clear, close all
%%
try
    % Koristimo EAN-13 format barkoda
    % Svaki broj je predstavljen sa 7 bitova

    % primer_foreground1.png pravi problem jer su linije svetle

    waitfor(msgbox('Izaberite zeljenu sliku ciji barkod zelite da skenirate.'));

    [file,path] = uigetfile({'*.jpg';'*.jpeg';'*.png';'*.*'},...
                              'File Selector');
    if isequal(file,0)
       disp('User selected Cancel');
    else
       disp(['User selected ', fullfile(path, file)]);
    end

    img = imread(fullfile(path, file));

    dlgTitle    = 'Pitanje';
    dlgQuestion = 'Da li želite da prikažete svaku figuru programa?';
    choice = questdlg(dlgQuestion,dlgTitle,'Da','Ne', 'Da');

    showFigures = false;
    if(choice == "Da")
        showFigures = true;
    end

    figure(1)
    imshow(img)
    title('Originalna slika')

    waitfor(msgbox('Izaberite region gde se nalazi barkod.'));

    % message = {'Obuhvatite ceo barkod dijagonalno sa 2 tacke'};
    % msgbox(message,'')

    % h_rect = imrect();
    % % Rectangle position is given as [xmin, ymin, width, height]
    % pos_rect = h_rect.getPosition();
    % % Round off so the coordinates can be used as indices
    % pos_rect = round(pos_rect);
    % % Select part of the image
    % I = img(pos_rect(2) + (0:pos_rect(4)), pos_rect(1) + (0:pos_rect(3)));
    h = drawrectangle();
    pos = round(h.get.Position);
    I = img(pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3));

    % 
    % [y,x] = ginput(2);
    % x = round(x);
    % y = round(y);
    % I = img(min(x):max(x), min(y):max(y));

    if(showFigures)
        figure(2)
        imshow(I);
        title('Izrezana slika');
    end

    img_gray = im2gray(I);     % pretvorimo postojecu sliku u monohromatsku
    img_double = im2double(img_gray);

    Iblur = imgaussfilt(img_double,1.5);
    img_double = imsharpen(Iblur,'Radius',2,'Amount',1); 

    level = graythresh(img_double);
    img_b = imbinarize(img_double, level);

    img_final = im2uint8(img_b);

    if(showFigures)
        figure(3)
        imshow(img_final);
        title('Finalna binarizovana slika')
    end

    se = strel('square', 4);
    afterOpening = imopen(img_b, se);

    %% 2D FFT za detekciju rotacije
    F = fft2(img_final);
    F = fftshift(F); % Center FFT
    
    
    F = abs(F); % Get the magnitude
    F = log(F+1); % Use log, for perceptual scaling, and +1 since log(0) is undefined
    F = mat2gray(F); % Use mat2gray to scale the image between 0 and 1
    img_freq = abs(F);
    
    tmp = imbinarize(img_freq, 0.75);
    if(showFigures)
        figure, imshow(img_freq,[]), title('Spektar slike') % Display the result
        figure, imshow(tmp), title('Prikaz spektra kog smo binarizovali');
    end
    
    Iblur = imgaussfilt(img_freq,1.5);
    img_freq = imsharpen(Iblur,'Radius',2,'Amount',1);

    if(showFigures)
        figure, imshow(img_freq), title('Prikaz spektra kog smo binarizovali izostren');
    end
    
    tmp = imbinarize(img_freq, 0.75);
    % tmp = im2uint8(tmp);
    if(showFigures)
        figure, imshow(tmp), title('Prikaz spektra kog smo binarizovali izostren');
    end
    %% Odredjivanje ugla
    [x,y] = find(tmp == true);
    X = [ones(length(x),1) x];
    Y = [ones(length(y),1) y];

    b = X\y;
    b2 = Y\x;

    yCalc = X*b;
    xCalc = Y*b2;

    if(showFigures)
        figure
        scatter(y,x);
        hold on
        plot(y, xCalc, '-')
        legend('Ulazni podaci', 'Aproksimacija prave');
    end

    % k = b(2);   % nagib  krive
    % alfa = atand(k);
    % angle = 90 + alfa;

    k = b2(2);
    alfa = atand(k);
    angle = alfa;

    % J = imrotate(img_final, -angle,"nearest", "crop");
    J = imrotate(img_final, angle,"nearest", "loose");

    if(showFigures)
        figure
        imshow(J)
    end
    %% Original slika, rotirana, selektovan deo gde je barkod i binarizovana
    % J = imrotate(img_double, angle,"nearest", "crop");
    J = ~imrotate(~img_final, angle,"nearest", "loose");
    % Razlog za ovu duplu negaciju je jer ako samo crop-ujemo onda ce matalb
    % dodati crnu pozadinu tamo gde nema slike, a posto mi hocemo da ta
    % pozadina bude bela onda negiramo pocetnu sliku, on doda crnu pozadinu, i
    % onda sve ponovo negiramo.

    if(showFigures)
        figure
        imshow(J);
        title('Slika nakon rotacije');
    end


    Iblur = imgaussfilt(im2double(J),2);

    level = graythresh(Iblur);
    img_b = imbinarize(Iblur, level);

    if(showFigures)
        figure
        imshow(img_b);
        title('Slika nakon binarizacije')
    end
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
    center = round(size(img_b,1) / 2);
    step = size(img_b, 1) / 10;
    slices = [center, center - step, center + step];
    for i=1:length(slices)-1
        x = slices(i);
        [isFinish, angle, code] = isBarcodeDecoded(img_b, x, angle, false);
        if(isFinish == true)
            break;
        end
    end

catch
    isFinish = false;
end

if(isFinish == true)
    msgbox("Barkod sa slike je " + code + " i je rotiran za " + abs(round(angle)) + "°");
else
    msgbox("Nazalost, barkod nije procitan.");
end
close all
