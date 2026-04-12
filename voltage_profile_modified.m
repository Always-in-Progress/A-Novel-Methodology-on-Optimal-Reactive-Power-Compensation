clear;
close all;
clc;

openfig('110kV薛阁变10kV 1母线电压运行范围.fig');
ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 18;
xlabel('分组方法/编号', 'FontName', '宋体', 'FontSize', 18, 'Color', 'k');
ylabel('{\it{V}}_L/kV', 'FontSize', 18, 'Color', 'k');
saveas(gcf, '110kV薛阁变10kV 1母线电压运行范围.fig');

openfig('110kV薛阁变10kV 2母线电压运行范围.fig');
ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 18;
xlabel('分组方法/编号', 'FontName', '宋体', 'FontSize', 18, 'Color', 'k');
ylabel('{\it{V}}_L/kV', 'FontSize', 18, 'Color', 'k');
saveas(gcf, '110kV薛阁变10kV 2母线电压运行范围.fig');

openfig('110kV园艺变10kV 1母线电压运行范围.fig');
ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 18;
xlabel('分组方法/编号', 'FontName', '宋体', 'FontSize', 18, 'Color', 'k');
ylabel('{\it{V}}_L/kV', 'FontSize', 18, 'Color', 'k');
saveas(gcf, '110kV园艺变10kV 1母线电压运行范围.fig');

openfig('110kV园艺变10kV 2母线电压运行范围.fig');
ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 18;
xlabel('分组方法/编号', 'FontName', '宋体', 'FontSize', 18, 'Color', 'k');
ylabel('{\it{V}}_L/kV', 'FontSize', 18, 'Color', 'k');
saveas(gcf, '110kV园艺变10kV 2母线电压运行范围.fig');

% close all;