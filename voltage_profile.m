clear;
close all;
clc;

%% Preliminary
basefolder = 'D:\Academia\Electric Engineering\Power System Quality\MATLAB Simulation\Case Study\Bozhou';
source_subfolder = '\1. Source Data';
optimisation_subfolder = '\2. Optimisation';
scenario_subsubfolder = {'\2.1 Fixed ratios (1, 2)'; '\2.2 Fixed ratios (1, 2, 4)'; ...
                         '\2.3 Fixed ratios (1, 2, 4, 8)'; '\2.4 Tunable ratios'};
N_sample = 1440;
t = (linspace(0, 24, N_sample + 1))';
t = t(1:N_sample);

%% Plot Voltage Profiles
% 110kV Xuege Substation
% 10kV Busbar Section I
mat_filename = 'voltage_analysis_of_10kV_Bus_1_at_Xuege.mat';
V_L_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(1);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    V_L_t_pro(:, count) = struct2array(load(mat_filelocale, 'V_L_t'));
end
boxplot(V_L_t_pro);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
xlabel('分组方法', 'FontName', '宋体', 'FontSize', 20, 'Color', 'k');
ylabel('{\it{V}_L} (kV)', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'YLim', [10.29, 10.45], 'YTick', 10.29:0.04:10.45);
saveas(gcf, '110kV薛阁变10kV 1母线电压运行范围.fig');
% 10kV Busbar Section II
mat_filename = 'voltage_analysis_of_10kV_Bus_2_at_Xuege.mat';
V_L_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(2);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    V_L_t_pro(:, count) = struct2array(load(mat_filelocale, 'V_L_t'));
end
boxplot(V_L_t_pro);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
xlabel('分组方法', 'FontName', '宋体', 'FontSize', 20, 'Color', 'k');
ylabel('{\it{V}_L} (kV)', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'YLim', [10.29, 10.45], 'YTick', 10.29:0.04:10.45);
saveas(gcf, '110kV薛阁变10kV 2母线电压运行范围.fig');
% 110kV Yuanyi Substation
% 10kV Busbar Section I
mat_filename = 'voltage_analysis_of_10kV_Bus_1_at_Yuanyi.mat';
V_L_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(3);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    V_L_t_pro(:, count) = struct2array(load(mat_filelocale, 'V_L_t'));
end
boxplot(V_L_t_pro);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
xlabel('分组方法', 'FontName', '宋体', 'FontSize', 20, 'Color', 'k');
ylabel('{\it{V}_L} (kV)', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'YLim', [10.29, 10.45], 'YTick', 10.29:0.04:10.45);
saveas(gcf, '110kV园艺变10kV 1母线电压运行范围.fig');
% 10kV Busbar Section II
mat_filename = 'voltage_analysis_of_10kV_Bus_2_at_Yuanyi.mat';
V_L_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(4);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    V_L_t_pro(:, count) = struct2array(load(mat_filelocale, 'V_L_t'));
end
boxplot(V_L_t_pro);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
xlabel('分组方法', 'FontName', '宋体', 'FontSize', 20, 'Color', 'k');
ylabel('{\it{V}_L} (kV)', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'YLim', [10.29, 10.45], 'YTick', 10.29:0.04:10.45);
saveas(gcf, '110kV园艺变10kV 2母线电压运行范围.fig');

%% Plot Tap Position Profiles
% 110kV Xuege Substation
% 10kV Busbar Section I
mat_filename = 'voltage_analysis_of_10kV_Bus_1_at_Xuege.mat';
tap_list_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(5);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    tap_list_t_pro(:, count) = struct2array(load(mat_filelocale, 'tap_list_t'));
end
stairs(t, tap_list_t_pro, 'LineWidth', 1.2);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
legend_label = {'\fontname{宋体}分组方法\fontname{Times New Roman}1', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}2', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}3', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}4'};
legend(legend_label, 'Location', 'Southeastoutside');
xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 20, 'Color', 'k');
ylabel('Tap No.', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
saveas(gcf, '110kV薛阁变1号主变有载调压抽头档位曲线.fig');
% 10kV Busbar Section II
mat_filename = 'voltage_analysis_of_10kV_Bus_2_at_Xuege.mat';
tap_list_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(6);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    tap_list_t_pro(:, count) = struct2array(load(mat_filelocale, 'tap_list_t'));
end
stairs(t, tap_list_t_pro, 'LineWidth', 1.2);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
legend_label = {'\fontname{宋体}分组方法\fontname{Times New Roman}1', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}2', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}3', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}4'};
legend(legend_label, 'Location', 'Southeastoutside');
xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 20, 'Color', 'k');
ylabel('Tap No.', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
saveas(gcf, '110kV薛阁变2号主变有载调压抽头档位曲线.fig');
% 110kV Yuanyi Substation
% 10kV Busbar Section I
mat_filename = 'voltage_analysis_of_10kV_Bus_1_at_Yuanyi.mat';
tap_list_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(7);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    tap_list_t_pro(:, count) = struct2array(load(mat_filelocale, 'tap_list_t'));
end
stairs(t, tap_list_t_pro, 'LineWidth', 1.2);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
legend_label = {'\fontname{宋体}分组方法\fontname{Times New Roman}1', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}2', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}3', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}4'};
legend(legend_label, 'Location', 'Southeastoutside');
xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 20, 'Color', 'k');
ylabel('Tap No.', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
saveas(gcf, '110kV园艺变1号主变有载调压抽头档位曲线.fig');
% 10kV Busbar Section II
mat_filename = 'voltage_analysis_of_10kV_Bus_2_at_Yuanyi.mat';
tap_list_t_pro = zeros(N_sample, numel(scenario_subsubfolder));
figure(8);
ax = subplot(1, 1, 1);
for count = 1:numel(scenario_subsubfolder)
    mat_filelocale = [basefolder, optimisation_subfolder, char(scenario_subsubfolder{count}), '\', mat_filename];
    tap_list_t_pro(:, count) = struct2array(load(mat_filelocale, 'tap_list_t'));
end
stairs(t, tap_list_t_pro, 'LineWidth', 1.2);
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
legend_label = {'\fontname{宋体}分组方法\fontname{Times New Roman}1', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}2', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}3', ...
                '\fontname{宋体}分组方法\fontname{Times New Roman}4'};
legend(legend_label, 'Location', 'Southeastoutside');
xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 20, 'Color', 'k');
ylabel('Tap No.', 'FontSize', 20, 'Color', 'k');
% grid('on');
set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
saveas(gcf, '110kV园艺变2号主变有载调压抽头档位曲线.fig');

close all;