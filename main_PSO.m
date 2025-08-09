%% Begin
tic;

clear;
close all;
clc;
warning off;

%% Preliminary
% Specify a file to import
basefolder = 'D:\Academia\Electric Engineering\Power System Quality\MATLAB Simulation\Case Study\Bozhou';
substation = '110kV薛阁变';
data = '250705-110kV谯薛II线754.xls';
full_filename = [basefolder, '\', substation, '\', data];
fprintf('Equipment through which the reactive power needs to be optimised: %s\t%s\n\n', ...
        substation, data(1:end-4));
% Import reactive power data for optimisation
Q_L = table2array(readtable(full_filename, 'Range', 'B:B'));
warning on;
if (contains(substation, '220kV') && contains(data, '220kV') && contains(data, '线')) || ...
   (contains(substation, '110kV') && contains(data, '110kV') && contains(data, '线')) || ...
   (contains(substation, '35kV') && contains(data, '35kV') && contains(data, '线')) || ...
   (contains(substation, '220kV') && ~contains(data, '220kV') && contains(data, '主变')) || ...
   (contains(substation, '110kV') && ~contains(data, '110kV') && contains(data, '主变')) || ...
   (contains(substation, '35kV') && ~contains(data, '35kV') && contains(data, '主变'))
    Q_L = -Q_L;
end
% Provide information in the simulation environment
T_sample = 1/60;
t = T_sample * (0:1:(length(Q_L) - 1))';
C_bank_proportion = sort([1, 2, 4, 8], 'ascend');
L_bank_proportion = sort([1, 2, 4, 8], 'ascend');
Max_switch_times  = [8, 8];
Min_switch_timespan = 15/60;
flag_sign = [(Q_L >= 0), (Q_L <= 0)];
Q_L_rate_lb = [0, -2];
Q_L_rate_ub = [2, 0];
Cap_lb = sign(Q_L_rate_lb) .* floor(abs(Q_L_rate_lb .* max(abs(flag_sign .* Q_L))) * 1e2) / 1e2;
Cap_ub = sign(Q_L_rate_ub) .* floor(abs(Q_L_rate_ub .* max(abs(flag_sign .* Q_L))) * 1e2) / 1e2;
Mode = [1, 1];

%% Optimisation
% Determine inherent parameters in the employed GWO
SearchAgents_no = 40;
Max_iter = 50;
dim = length(Cap_lb);
% Realise optimal reactive power compensation by employing GWO
[E_Q, Cap, Convergence_curve, Q_C, Q_proportion_plot, ...
      schedule_info_Cap, C_bank_status_info, ...
      schedule_info_Rea, L_bank_status_info] = PSO_for_ORPC(SearchAgents_no, Max_iter, Cap_lb, Cap_ub, dim, ...
                                                            T_sample, Q_L, C_bank_proportion, Max_switch_times, Mode);
delta_Q = Q_L - Q_C;

%% Results
% Print average power energy
fprintf('\n');
fprintf('The average reactive power energy in the obtained optimal schedule is %.4f Mvarh.\n', E_Q);
% Illustrate the obtained optimal schedule in a figure
figure(1);
ax = subplot(1, 1, 1);
stairs(t, Q_L, 'Color', '#0072BD', 'LineStyle', '-', 'LineWidth', 1.2);
hold on;
stairs(t, Q_proportion_plot, 'Color', '#D95319', 'LineStyle', '--', 'LineWidth', 0.5);
hold on;
stairs(t, Q_C, 'Color', '#D95319', 'LineStyle', '-', 'LineWidth', 1.2);
hold on;
stairs(t, delta_Q, 'Color', '#77AC30', 'LineStyle', '-', 'LineWidth', 1.2);
legend_label = cell(1, size(Q_L, 2) + size(Q_proportion_plot, 2) + size(Q_C, 2) + size(delta_Q, 2));
for count = 1:size(legend_label, 2)
    if count <= size(Q_L, 2)
        legend_label{count} = '{\it{Q_L}}';
    elseif count <= size(Q_L, 2) + size(Q_proportion_plot, 2)
        legend_label{count} = '';
    elseif count <= size(Q_L, 2) + size(Q_proportion_plot, 2) + size(Q_C, 2)
        legend_label{count} = '{\it{Q_C}}';
    else
        legend_label{count} = '{\Delta}{\it{Q}}';
    end
end
legend(legend_label, 'Location', 'Southeastoutside');
ax.FontName = 'Times New Roman';
ax.FontSize = 12;
xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 14, 'Color', 'k'); 
ylabel('{\it{Q}} (Mvar)', 'FontSize', 14, 'Color', 'k');
grid('on');
set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
% Illustrate real time statuses of each allocated capacitor
% Print operating information of each allocated capacitor
if ~isempty(schedule_info_Cap)
    C_bank_Cap = Cap(1) / sum(C_bank_proportion) * C_bank_proportion;
    numFigures = length(findall(0, 'Type', 'figure'));
    for count = 1:length(C_bank_proportion)
        figure(numFigures + count);
        ax = subplot(1, 2, 1);
        width = 1;
        bar(t, schedule_info_Cap.real_time_status(count).real_time_C_bank_status, width);
        ax.FontName = 'Times New Roman';
        ax.FontSize = 12;
        xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 14, 'Color', 'k'); 
        ylabel('Operation status (1, 0)', 'FontSize', 14, 'Color', 'k');
        grid('on');
        set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
        set(ax, 'YLim', [0, 1], 'YTick', 0:1:1);
        ax = subplot(1, 2, 2);
        width = 1;
        bar(t, schedule_info_Cap.real_time_status(count).is_C_bank_switched, width);
        ax.FontName = 'Times New Roman';
        ax.FontSize = 12;
        xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 14, 'Color', 'k'); 
        ylabel('Switch status (1, 0, -1)', 'FontSize', 14, 'Color', 'k');
        grid('on');
        set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
        set(ax, 'YLim', [-1, 1], 'YTick', -1:1:1);
    end
    fprintf('The allocated capacitor bank contains %d capacitor', length(C_bank_proportion));
    if length(C_bank_Cap) ~= 1
        fprintf('s');
    end
    fprintf(', with a total capacity %.2f Mvar.\n', Cap(1));
    for count = 1:length(C_bank_Cap)
        fprintf('Capacitor %d, the capacity of which is %.2f Mvar, operates for %d h', ...
                count, abs(C_bank_Cap(count)), fix(C_bank_status_info.Capacitor(count).C_bank_operating_timespan));
        if round(mod(C_bank_status_info.Capacitor(count).C_bank_operating_timespan, 1) * 60)
            fprintf(' %d min', round(mod(C_bank_status_info.Capacitor(count).C_bank_operating_timespan, 1) * 60));
        end
        if C_bank_status_info.Capacitor(count).C_bank_switch_on_times > 2
            fprintf(', switched on %d times', C_bank_status_info.Capacitor(count).C_bank_switch_on_times);
        elseif C_bank_status_info.Capacitor(count).C_bank_switch_on_times == 2
            fprintf(', switched on twice');
        elseif C_bank_status_info.Capacitor(count).C_bank_switch_on_times == 1
            fprintf(', switched on once');
        else
            fprintf(', never switched on');
        end
        fprintf(' and');
        if C_bank_status_info.Capacitor(count).C_bank_switch_off_times > 2
            fprintf(' switched off %d times', C_bank_status_info.Capacitor(count).C_bank_switch_off_times);
        elseif C_bank_status_info.Capacitor(count).C_bank_switch_off_times == 2
            fprintf(' switched off twice');
        elseif C_bank_status_info.Capacitor(count).C_bank_switch_off_times == 1
            fprintf(' switched off once');
        else
            fprintf(' never switched off');
        end
        fprintf('.\n');
    end
    fprintf('\n');
end
% Illustrate real time status of each allocated reactor
% Print operating information of each allocated reactor
if ~isempty(schedule_info_Rea)
    L_bank_Cap = Cap(2) / sum(L_bank_proportion) * L_bank_proportion;
    numFigures = length(findall(0, 'Type', 'figure'));
    for count = 1:length(L_bank_proportion)
        figure(numFigures + count);
        ax = subplot(1, 2, 1);
        width = 1;
        bar(t, schedule_info_Rea.real_time_status(count).real_time_L_bank_status, width);
        ax.FontName = 'Times New Roman';
        ax.FontSize = 12;
        xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 14, 'Color', 'k'); 
        ylabel('Operation status (1, 0)', 'FontSize', 14, 'Color', 'k');
        grid('on');
        set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
        set(ax, 'YLim', [0, 1], 'YTick', 0:1:1);
        ax = subplot(1, 2, 2);
        width = 1;
        bar(t, schedule_info_Rea.real_time_status(count).is_L_bank_switched, width);
        ax.FontName = 'Times New Roman';
        ax.FontSize = 12;
        xlabel('{\it{t}} (h)', 'FontName', 'Times New Roman', 'FontSize', 14, 'Color', 'k'); 
        ylabel('Switch status (1, 0, -1)', 'FontSize', 14, 'Color', 'k');
        grid('on');
        set(ax, 'XLim', [0, 24], 'XTick', 0:4:24);
        set(ax, 'YLim', [-1, 1], 'YTick', -1:1:1);
    end
    fprintf('The allocated reactor bank contains %d reactor', length(L_bank_proportion));
    if length(L_bank_Cap) ~= 1
        fprintf('s');
    end
    fprintf(', with a total capacity %.2f Mvar.\n', -Cap(2));
    for count = 1:length(L_bank_Cap)
        fprintf('Reactor %d, the capacity of which is %.2f Mvar, operates for %d h', ...
                count, abs(L_bank_Cap(count)), fix(L_bank_status_info.Reactor(count).L_bank_operating_timespan));
        if round(mod(L_bank_status_info.Reactor(count).L_bank_operating_timespan, 1) * 60)
            fprintf(' %d min', round(mod(L_bank_status_info.Reactor(count).L_bank_operating_timespan, 1) * 60));
        end
        if L_bank_status_info.Reactor(count).L_bank_switch_on_times > 2
            fprintf(', switched on %d times', L_bank_status_info.Reactor(count).L_bank_switch_on_times);
        elseif L_bank_status_info.Reactor(count).L_bank_switch_on_times == 2
            fprintf(', switched on twice');
        elseif L_bank_status_info.Reactor(count).L_bank_switch_on_times == 1
            fprintf(', switched on once');
        else
            fprintf(', never switched on');
        end
        fprintf(' and');
        if L_bank_status_info.Reactor(count).L_bank_switch_off_times > 2
            fprintf(' switched off %d times', L_bank_status_info.Reactor(count).L_bank_switch_off_times);
        elseif L_bank_status_info.Reactor(count).L_bank_switch_off_times == 2
            fprintf(' switched off twice');
        elseif L_bank_status_info.Reactor(count).L_bank_switch_off_times == 1
            fprintf(' switched off once');
        else
            fprintf(' never switched off');
        end
        fprintf('.\n');
    end
    fprintf('\n');
end

%% End
toc;