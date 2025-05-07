clc;
clear;
clear all;

%% Define Variable
lokasi = readtable('SPKLU-LOKASI.csv', 'PreserveVariableNames', true);
mesin = readtable('SPKLU-MESIN.csv', 'PreserveVariableNames', true);
konektor = readtable('SPKLU-KONEKTOR.csv', 'PreserveVariableNames', true);

%% Sebaran SPKLU (Pakai Map)
disp(lokasi.Properties.VariableNames)

% Coba konversi Latitude & Longitude ke angka
lat = str2double(string(lokasi.("Latitude")));
lon = str2double(string(lokasi.("Longitude")));

invalidRows = ...
    isnan(lat) | isnan(lon) | ...
    lat < -90 | lat > 90 | ...
    lon < -180 | lon > 180;

lokasiClean = lokasi(~invalidRows, :);
latClean = lat(~invalidRows);
lonClean = lon(~invalidRows);

% Plot peta
geoscatter(latClean, lonClean, 'filled')
geobasemap streets
title('Sebaran SPKLU di Indonesia')

%% Bar Chart - Jumlah SPKLU per Badan Usaha (PLN diskalakan 10x)
badanUsaha = string(lokasiClean.("Badan Usaha"));

% Ganti nama 
badanUsaha(badanUsaha == "PERUSAHAAN PERSEROAN (PERSERO) PT. PERUSAHAAN LISTRIK NEGARA") = "PT PLN (Persero)";

% Hitung jumlah
[badanUsahaUnique, ~, idxBU] = unique(badanUsaha);
jumlahBU = accumarray(idxBU, 1);

% Cek index PLN
idxPLN = find(badanUsahaUnique == "PT PLN (Persero)");
jumlahBU_Asli = jumlahBU;
jumlahBU(idxPLN) = jumlahBU(idxPLN) / 10;

% Plot
figure
b = bar(categorical(badanUsahaUnique), jumlahBU, 'FaceColor', '#0072BD');
ylabel('Jumlah SPKLU (PLN diskalakan x10)')
title('Jumlah SPKLU per Badan Usaha (dengan Skala Khusus PLN)')
xtickangle(45)
grid on
xtips = b.XEndPoints;
ytips = b.YEndPoints;
labels = string(jumlahBU_Asli);

labels(idxPLN) = labels(idxPLN) + " (/10)";
text(xtips, ytips + 1, labels, 'HorizontalAlignment','center', 'VerticalAlignment','bottom')

%% Pie Chart - Skema SPKLU
skema = string(lokasiClean.("Skema SPKLU"));
[skemaUnique, ~, idxSkema] = unique(skema);
jumlahSkema = accumarray(idxSkema, 1);
persenSkema = jumlahSkema / sum(jumlahSkema) * 100;
pieLabel = strcat(skemaUnique, ": ", string(round(persenSkema,1)), "%");

figure
pie(jumlahSkema, pieLabel)
title('Persentase Skema SPKLU')

%% Pie Chart - Persentase Jenis Konektor (Standardized & Gruped)
jenisKonektor = strtrim(string(konektor.("Jenis Konektor"))); % biar no spasi nyelip

% Standardisasi nama konektor
jenisKonektor(ismember(jenisKonektor, ["J1772 (Tipe 1)", "CCS1"])) = "AC Type 1";
jenisKonektor(ismember(jenisKonektor, ["AC (Tipe 2)", "Mennekes (Tipe2)", "Mennekes (Type 2)", "Mennekes (Tipe 2)"])) = "Mennekes (Type 2)";
% CCS2 tetap ya

% Hitung persentase
[jenisUnique, ~, idxKonektor] = unique(jenisKonektor);
jumlahKonektor = accumarray(idxKonektor, 1);
persenKonektor = jumlahKonektor / sum(jumlahKonektor) * 100;

% Buat label
pieLabelKonektor = strcat(jenisUnique, ": ", string(round(persenKonektor, 1)), "%");

% Pie chart time!
figure
pie(jumlahKonektor, pieLabelKonektor)
title('Persentase Jenis Konektor SPKLU (Sudah Distandardisasi)')
