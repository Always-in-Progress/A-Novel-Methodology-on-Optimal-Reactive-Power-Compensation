clear;
close all;
clc;
warning off;

load('10kV_Bus_2_at_Xuege.mat');

full_filename = [basefolder, '\', substation, '\', data(1:end-4), 'PQ.xls'];
fprintf('Equipment through which the reactive power needs to be optimised: %s\t%s\n\n', ...
        substation, data(1:end-4));
% Import reactive power data for optimisation
P_L = table2array(readtable(full_filename, 'Range', 'B:B'));
warning on;
if (contains(substation, '220kV') && contains(data, '220kV') && contains(data, '线')) || ...
   (contains(substation, '110kV') && contains(data, '110kV') && contains(data, '线')) || ...
   (contains(substation, '35kV') && contains(data, '35kV') && contains(data, '线')) || ...
   (contains(substation, '220kV') && ~contains(data, '220kV') && contains(data, '主变')) || ...
   (contains(substation, '110kV') && ~contains(data, '110kV') && contains(data, '主变')) || ...
   (contains(substation, '35kV') && ~contains(data, '35kV') && contains(data, '主变'))
    P_L = -P_L;
end

PF_L = P_L ./ sqrt(P_L .^ 2 + Q_L .^ 2);
PF_C = P_L ./ sqrt(P_L .^ 2 + delta_Q .^ 2);

fprintf('\t\t\t\t\t\tWithout compensation\tWith compensation\n');
fprintf('Maximum power factor: \t\t%.4f\t\t\t\t\t%.4f\n', max(PF_L), max(PF_C));
fprintf('Avarge power factor: \t\t%.4f\t\t\t\t\t%.4f\n', mean(PF_L), mean(PF_C));
fprintf('Minimum power factor: \t\t%.4f\t\t\t\t\t%.4f\n', min(PF_L), min(PF_C));