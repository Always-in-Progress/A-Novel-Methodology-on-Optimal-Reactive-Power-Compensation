%% Particle Swarm Optimisation for Optimal Reactive Power Compensation
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

function [gBest_score, gBest_pos, Convergence_curve, Q_C, Q_proportion_plot, ...
          schedule_info_Cap, C_bank_status_info, ...
          schedule_info_Rea, L_bank_status_info] = PSO_for_ORPC(Particle_no, Max_iter, lb, ub, dim, ...
                                                                T_sample, Q_L, C_bank_proportion, Max_switch_times, Mode)
    
    
    schedule_info_Cap = [];
    C_bank_status_info = [];
    schedule_info_Rea = [];
    L_bank_status_info = [];

    % GWEO parameters
    Vmax = 0.5 * abs(ub - lb);
    wMax = 0.9;
    wMin = 0.2;
    c1 = 2;
    c2 = 2;

    % Initialisations
    vol = zeros(Particle_no, dim);
    pBest_Score = inf * ones(1, Particle_no);
    pBest_pos = zeros(Particle_no, dim);
    gBest_pos = zeros(1, dim);
    gBest_score = inf;
    Convergence_curve = zeros(1, Max_iter);

    % Random initialisation for agents.
    Positions = initialisation(Particle_no, dim, ub, lb); 
       
    iter = 1;% Loop counter

    % Main loop
    while iter <= Max_iter
        for i = 1:size(Positions, 1)  

            % Return back the search agents that go beyond the boundaries of the search space
            Flag4ub = Positions(i, :) > ub;
            Flag4lb = Positions(i, :) < lb;
            Positions(i, :) = (Positions(i, :) .* (~(Flag4ub + Flag4lb))) + ub .* Flag4ub + lb .* Flag4lb;
            Cap = Positions(i, :);

            % Calculate objective function for each search agent
            if Cap(1) > 0
                [Q_C_Cap, ~, Q_proportion_plot_Cap, schedule_info_Cap, C_bank_status_info] = C_bank_schedule(T_sample, Q_L, Cap(1), ...
                    C_bank_proportion, Max_switch_times(1), Mode(1));
                Q_proportion_plot = Q_proportion_plot_Cap;
                Q_C = Q_C_Cap;
            end
            if Cap(2) < 0
                [Q_C_Rea, ~, Q_proportion_plot_Rea, schedule_info_Rea, L_bank_status_info] = L_bank_schedule(T_sample, Q_L, Cap(2), ...
                    L_bank_proportion, Max_switch_times(2), Mode(2));
                Q_proportion_plot = [Q_proportion_plot, Q_proportion_plot_Rea];
                Q_C = Q_C + Q_C_Rea;
            end
            delta_Q = Q_L - Q_C;
            fitness = sum(delta_Q) * T_sample;

            % Update Alpha, Beta, and Delta
            if pBest_Score(i) > fitness
                pBest_Score(i) = fitness;
                pBest_pos(i, :) = Positions(i,:);
            end
            if gBest_score > fitness
                gBest_score = fitness;
                gBest_pos = Positions(i,:);
            end
        end

        % Update the W of PSO
        w = wMax - iter * ((wMax - wMin) / Max_iter);
        % Update the Velocity and Position of particles
        for i = 1:size(Positions, 1)
            for j = 1:size(Positions, 2)
                vol(i, j) = w * vol(i, j) + c1 * rand() * (pBest_pos(i, j) - Positions(i, j)) + ...
                            c2 * rand() * (gBest_pos(j) - Positions(i, j));

                if vol(i, j) > Vmax(j)
                    vol(i, j) = Vmax(j);
                end
                if vol(i, j) < -Vmax(j)
                    vol(i, j) = -Vmax(j);
                end
            end
        end
        Positions = Positions + vol;
        Convergence_curve(iter) = gBest_score;
        
        % Display Results
        fprintf('Iteration %d:\n', iter);
        fprintf('The average reactive power energy in the best schedule is %.4f Mvarh.\n', gBest_score);
        fprintf(['The total capacities of the allocated capacitor and reactor banks are %.2f Mvar and ', ...
                 '%.2f Mvar, respectively.\n'], abs(gBest_pos(1)), abs(gBest_pos(2)));

        iter = iter + 1;
    end
end