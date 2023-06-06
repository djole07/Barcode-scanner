function varargout = Barcode_application(varargin)
% BARCODE_APPLICATION MATLAB code for Barcode_application.fig
%      BARCODE_APPLICATION, by itself, creates a new BARCODE_APPLICATION or raises the existing
%      singleton*.
%
%      H = BARCODE_APPLICATION returns the handle to a new BARCODE_APPLICATION or the handle to
%      the existing singleton*.
%
%      BARCODE_APPLICATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BARCODE_APPLICATION.M with the given input arguments.
%
%      BARCODE_APPLICATION('Property','Value',...) creates a new BARCODE_APPLICATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Barcode_application_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Barcode_application_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Barcode_application

% Last Modified by GUIDE v2.5 06-Jun-2023 10:51:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Barcode_application_OpeningFcn, ...
                   'gui_OutputFcn',  @Barcode_application_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Barcode_application is made visible.
function Barcode_application_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Barcode_application (see VARARGIN)


% Choose default command line output for Barcode_application
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Barcode_application wait for user response (see UIRESUME)
% uiwait(handles.figure1);
set(findobj('Tag','text_barcode'),'String', "");
axes(handles.axes_image);
axis off;       % ne prikazuje prazan koordinatni sistem pri pokretanju aplikacije




% --- Outputs from this function are returned to the command line.
function varargout = Barcode_application_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% Deo koda za izvrsavanje odabira slike
function photo_selector_Callback(hObject, eventdata, handles)
% hObject    handle to photo_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla reset;      % briše prethodno prikazanu figuru
axis off;       % ne prikazuje prazan koordinatni sistem
set(findobj('Tag','text_barcode'),'String', "");    % briše prethodni ispis na polju gde treba da se ispiše vrednost barkoda
        
[file,path] = uigetfile( ...
{'*.jpg;*.jpeg;*.png;*.jpg;*.jpeg;*.png',...
    'Image Files (*.jpg;*.jpeg;*.png)';
   '*.*',  'All Files (*.*)'}, ...
   'Select an image');
if isequal(file,0)
%     msgbox('Niste izabrali sliku.');
        set(findobj('Tag','text_barcode'),'String',...
            "Image not selected.")
        set(findobj('Tag','text_barcode'), 'ForegroundColor', 'red')
else
    % ako je izabrao dobar fajl
    try
       
%         axes(handles.axes_image);   % nije neophodno ali priprema osu za
%         ispis na njoj. Tj. na ovoj osi bismo prikazali našu sliku
        
        img = imread(fullfile(path, file));
        imshow(img);
        
        h = drawrectangle();    % predstavja unos mišem, tj. korisnik obeležava deo slike od interesa
        pos = round(h.get.Position);
        I = img(pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3));

        img_gray = im2gray(I);     % pretvorimo postojecu sliku u monohromatsku
        img_double = im2double(img_gray);

        % Ukoliko prvo zamutimo sliku, pa je potom izostrimo dobijemo
        % potisnut sum i ivice se bolje istaknu
        Iblur = imgaussfilt(img_double,1.5);    % proizvoljno
        img_double = imsharpen(Iblur,'Radius',2,'Amount',1);

        level = graythresh(img_double);
        img_b = imbinarize(img_double, level);

        img_final = im2uint8(img_b);

        %% 2D FFT za detekciju rotacije
        F = fft2(img_final);
        F = fftshift(F); % Center FFT

        F = abs(F); % Get the magnitude
        F = log(F+1); % Use log, for perceptual scaling, and +1 since log(0) is undefined
        F = mat2gray(F); % Use mat2gray to scale the image between 0 and 1
        img_freq = abs(F);

        
        Iblur = imgaussfilt(img_freq,1.5);  % proizvoljno
        img_freq = imsharpen(Iblur,'Radius',2,'Amount',1);  % proizvoljno


        tmp = imbinarize(img_freq, 0.75);   % 0,75 je odredjeno eksperimentalno
        
        %% Odredjivanje ugla
        [x,y] = find(tmp == true);
        Y = [ones(length(y),1) y];

        b = Y\x;

        k = b(2);
        alfa = atand(k);
        angle = alfa;

        %% Original slika, rotirana, selektovan deo gde je barkod i binarizovana
        % J = imrotate(img_double, angle,"nearest", "crop");
        J = ~imrotate(~img_final, angle,"nearest", "loose");
        % Razlog za ovu duplu negaciju je jer ako samo crop-ujemo onda ce matalb
        % dodati crnu pozadinu tamo gde nema slike, a posto mi hocemo da ta
        % pozadina bude bela onda negiramo pocetnu sliku, on doda crnu pozadinu, i
        % onda sve ponovo negiramo.
        
        Iblur = imgaussfilt(im2double(J),2);

        level = graythresh(Iblur);
        img_b = imbinarize(Iblur, level);
        %% Proveravamo barkod u 5 linija, tj. u linijama odredjenim u slices
        center = round(size(img_b,1) / 2);
        step = size(img_b, 1) / 10;
        slices = [center, center - step, center + step, center - 2*step, center + 2*step];
        for i=1:length(slices)-1
            x = slices(i);
            [isFinish, angle, code] = isBarcodeDecoded(img_b, x, angle, false);
            if(isFinish == true)
                break;
            end
        end

    catch
        isFinish = false;
%         msgbox('Greska u programu');
        set(findobj('Tag','text_barcode'),'String',...
            "Program error.")
        set(findobj('Tag','text_barcode'), 'ForegroundColor', 'red')
    end
% % 
    if(isFinish == true)
        % Ukoliko korisnik želi da dobije pop-up, to možemo uraditi
        % korišćenjem naredne linije
%         waitfor(msgbox("Barkod sa slike je " + code + " i je rotiran za " + abs(round(angle)) + "°"));
        set(findobj('Tag','text_barcode'),'String',...
            sprintf("Detected barcode is %s\nand it's rotated by %d°.", code, abs(round(angle))))
        set(findobj('Tag','text_barcode'), 'ForegroundColor', 'black')
    else
%         waitfor(msgbox("Nazalost, barkod nije procitan."));
        set(findobj('Tag','text_barcode'),'String',...
            "Unfortunately, barcode is not detected.")
        set(findobj('Tag','text_barcode'), 'ForegroundColor', 'red')
    end
    axes(handles.axes_image);
    axis off;
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
