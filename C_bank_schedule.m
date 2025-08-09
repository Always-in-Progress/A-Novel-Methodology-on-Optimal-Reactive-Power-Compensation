function [Q_C, delta_Q, Q_proportion_plot, schedule_info, C_bank_status_info] = C_bank_schedule(T_sample, Q_L, Cap, ...
                                                                                                C_bank_proportion, ...
                                                                                                Max_switch_times, ...
                                                                                                Mode)
% Designed by: William Liu
% Profile of designer: William Liu (also Wei Liu), born on 25 May, 1998, received a bachelor's degree in 
%                      2020 and a master's degree in 2023, in electrical engineering from the School of 
%                      Electrical Engineering and Automation, Anhui University, Hefei, Anhui, China. He 
%                      currently serves as an attendant of Substation Operation and Maintenance Shift II 
%                      for the Substation Operation and Maintenance Centre, State Grid Bozhou Power Supply 
%                      Company, Bozhou, Anhui, China.
%                      His research interests include mathematics, optimisation, algorithms, power system 
%                      analysis and power quality control.
%                      劉威，生於1998年5月25日，2020年於安徽大學电氣工程與自動化學院電氣工程及其自動化專業獲得學士
%                      學位，2023年於安徽大學電氣工程與自動化學院電氣工程專業獲得碩士學位。現於中國安徽省亳州市國
%                      網亳州供電公司變電運維中心任變電運維二班值班員。
%                      研究方向包含數學、優化、算法、電力系統分析和電能質量控制。
%                      刘威，1998年5月25日生，2020年获得安徽大学电气工程与自动化学院电气工程及其自动化专业学士学
%                      位，2023年获得安徽大学电气工程与自动化学院电气工程专业硕士学位。现任中国安徽省亳州市国网亳州
%                      供电公司变电运维中心变电运维二班值班员。
%                      研究方向包括数学、优化、算法、电力系统分析和电能质量控制。
%                      Уильям Лю (также Уэй Лю), родившийся 25 мая 1998 года, получил степень бакалавра 
%                      в 2020 году и степень магистра в 2023 году по электротехнике в Школе электротехники 
%                      и автоматизации Аньхойского университета в Хэфэе, провинция Аньхой, Китай. В 
%                      настоящее время он работает дежурным смены эксплуатации и технического 
%                      обслуживания подстанций II в центре эксплуатации и обслуживания подстанции 
%                      государственной сети Бочжоу электроснабжающей компании, Бочжоу, провинция 
%                      Аньхой, Китай.
%                      Его научные интересы включают математику, оптимизацию, алгоритмы, анализ 
%                      энергосистем и контроль качества электроэнергии. 
%                      劉ウィリアムは、1998年5月25日に生まれて、2020年に安徽大学電気工事と自動化学院で電気工事専門
%                      の学士学位を取得して、2023年に安徽大学電気工事と自動化学院で電気工事専門の修士学位を取得した。
%                      現在は中国安徽省亳州市に国家電網亳州供電公司変電所オペレーションとメンテナンスセンターで変電所
%                      オペレーションとメンテナンスシフト2の当直員を務めている。
%                      研究分野には数学、最適化、アルゴリズム、電力システム分析、電力品質制御が含まれる。
% 
% Main article: [1] W. Liu, Z. Ding, H. Zhang and M. Zhu, 
%                   "Multiobjective Optimal Power Flow for Distribution Networks 
%                   Utilizing a Novel Heuristic Algorithm—Grey Wolf Equilibrium 
%                   Optimizer," IEEE Systems Journal, vol. 18, no. 1, 
%                   pp. 174-185, March 2024, doi: 10.1109/JSYST.2024.3352235
%               [2] W. Liu, R. Zhang, X. Wang, C. Gao, D. Li, F. Ye and et al, 
%                   "A Novel Methodology on Dynamic Optimal Power Flow Considering 
%                   Switching Counts of Capacitors,"(in Chinese) C.N.
%                   Patent 120222404A, June 27, 2025.
    
    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end

    Q_L_Cal = (Q_L > 0).*Q_L;
    [k_C, Q_C, Q_proportion_plot] = initial_C_bank_schedule(Q_L_Cal, Cap, C_bank_proportion, Mode);
    [schedule_info, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L_Cal, ...
                                                              C_bank_proportion, k_C, Q_C, Mode);
    [k_C, Q_C] = curtailment_of_C_bank_overswitches(T_sample, Q_L_Cal, C_bank_proportion, k_C, Q_C, ...
                                                    Max_switch_times, schedule_info, C_bank_status_info, ...
                                                    Mode);
    [schedule_info, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L_Cal, ...
                                                                          C_bank_proportion, k_C, Q_C, Mode);
    % [k_C, Q_C] = extension_of_switch_timespan(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
    %                                           Min_switch_timespan, schedule_info, C_bank_status_info, ...
    %                                           Mode);
    % [schedule_info, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, ...
    %                                                                       C_bank_proportion, k_C, Q_C, Mode);
    delta_Q = Q_L - Q_C;

end