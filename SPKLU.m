clc;
clear;
clear all;

%% Define Variable
lokasi = readtable('SPKLU-LOKASI.csv', 'PreserveVariableNames', true);
mesin = readtable('SPKLU-MESIN.csv', 'PreserveVariableNames', true);
konektor = readtable('SPKLU-KONEKTOR.csv', 'PreserveVariableNames', true);

%% Sebaran SPKLU (Pakai Map)
disp(lokasi.Properties.VariableNames)

lat = str2double(string(lokasi.("Latitude")));
lon = str2double(string(lokasi.("Longitude")));

invalidRows = ...
    isnan(lat) | isnan(lon) | ...
    lat < -90 | lat > 90 | ...
    lon < -180 | lon > 180;

lokasiClean = lokasi(~invalidRows, :);
latClean = lat(~invalidRows);
lonClean = lon(~invalidRows);

geoscatter(latClean, lonClean, 'filled')
geobasemap streets
title('Sebaran SPKLU di Indonesia')

%% Bar Chart - Jumlah SPKLU per Badan Usaha (PLN diskalakan 10x)
badanUsaha = string(lokasiClean.("Badan Usaha"));

badanUsaha(badanUsaha == "PERUSAHAAN PERSEROAN (PERSERO) PT. PERUSAHAAN LISTRIK NEGARA") = "PT PLN (Persero)";

[badanUsahaUnique, ~, idxBU] = unique(badanUsaha);
jumlahBU = accumarray(idxBU, 1);

idxPLN = find(badanUsahaUnique == "PT PLN (Persero)");
jumlahBU_Asli = jumlahBU;
jumlahBU(idxPLN) = jumlahBU(idxPLN) / 10;

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
pieLabel = strcat(skemaUnique, ": ", string(jumlahSkema), " (", string(round(persenSkema,1)), "%)");

figure
pie(jumlahSkema, pieLabel)
title('Persentase Skema SPKLU')

%% Pie Chart - Persentase Jenis Konektor (Standardized & Gruped)
jenisKonektor = strtrim(string(konektor.("Jenis Konektor"))); 

jenisKonektor(ismember(jenisKonektor, ["J1772 (Tipe 1)", "CCS1"])) = "AC Type 1";
jenisKonektor(ismember(jenisKonektor, ["AC (Tipe 2)", "Mennekes (Tipe2)", "Mennekes (Type 2)", "Mennekes (Tipe 2)"])) = "Mennekes (Type 2)";

[jenisUnique, ~, idxKonektor] = unique(jenisKonektor);
jumlahKonektor = accumarray(idxKonektor, 1);
persenKonektor = jumlahKonektor / sum(jumlahKonektor) * 100;

pieLabelKonektor = strcat(jenisUnique, ": ", string(jumlahKonektor), " (", string(round(persenKonektor, 1)), "%)");

figure
pie(jumlahKonektor, pieLabelKonektor)
title('Persentase Jenis Konektor SPKLU')

%% Bar Chart Horizontal - Jumlah SPKLU per Provinsi (A-Z)
provinsi = string(lokasiClean.("Provinsi"));

[provUnique, ~, idxProv] = unique(provinsi);
jumlahSPKLU = accumarray(idxProv, 1);

[provSorted, sortIdx] = sort(provUnique); 
jumlahSorted = jumlahSPKLU(sortIdx);

figure
barh(categorical(provSorted), jumlahSorted, 'FaceColor', '#EDB120')
xlabel('Jumlah SPKLU')
title('Sebaran Jumlah SPKLU per Provinsi')
grid on

for i = 1:length(jumlahSorted)
    text(jumlahSorted(i) + 0.5, i, ...
        num2str(jumlahSorted(i)), ...
        'VerticalAlignment', 'middle', 'FontSize', 9)
end

%% 2. Matrix Matching: Jenis Konektor vs Jenis Pengisian

dataJoin = innerjoin(konektor, mesin, 'Keys', 'Nomor Identitias');
konektorJenis = strtrim(string(dataJoin.("Jenis Konektor")));
pengisianJenis = string(dataJoin.("Jenis Pengisian"));

konektorJenis(ismember(konektorJenis, ["J1772 (Tipe 1)", "CCS1"])) = "AC Type 1";
konektorJenis(ismember(konektorJenis, ["AC (Tipe 2)", "Mennekes (Tipe2)", "Mennekes (Type 2)", "Mennekes (Tipe 2)"])) = "Mennekes (Type 2)";

[C, ~, ic] = unique([konektorJenis, pengisianJenis], 'rows');
counts = accumarray(ic, 1);

konektorLabels = unique(konektorJenis);
pengisianLabels = unique(pengisianJenis);

T = table(C(:,1), C(:,2), counts, ...
    'VariableNames', {'Jenis_Konektor', 'Jenis_Pengisian', 'Jumlah'})

% Pivot to matrix
konektorCat = categorical(C(:,1), konektorLabels);
pengisianCat = categorical(C(:,2), pengisianLabels);
pivotMat = zeros(length(konektorLabels), length(pengisianLabels));

for i = 1:size(C, 1)
    r = find(string(konektorLabels) == string(konektorCat(i)));
    c = find(string(pengisianLabels) == string(pengisianCat(i)));
    pivotMat(r, c) = counts(i);
end

% Heatmap
figure
heatmap(pengisianLabels, konektorLabels, pivotMat, ...
    'Colormap', parula, 'ColorbarVisible', 'on')
h.CellLabelColor = 'k';  
h.FontSize = 16; 

xlabel('Jenis Pengisian')
ylabel('Jenis Konektor')
title('Matrix Matching: Konektor vs Jenis Pengisian')

