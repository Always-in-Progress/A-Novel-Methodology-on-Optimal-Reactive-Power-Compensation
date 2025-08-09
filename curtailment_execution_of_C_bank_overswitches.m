function [k_C, Q_C] = curtailment_execution_of_C_bank_overswitches(T_sample, Q_L, C_bank_proportion, ...
                                                                   k_C, Q_C, Max_switch_times, ...
                                                                   C_bank_status_info, Mode)

    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end
    
    switch Mode
        case 1
            C_bank_count = size(C_bank_status_info.Capacitor, 2);
            for count1 = 1:C_bank_count
                C_bank_switch_times = C_bank_status_info.Capacitor(count1).C_bank_switch_times;
                overswitched_C_bank_status = [];
                if C_bank_switch_times > Max_switch_times
                    is_C_bank_switched = (reshape([C_bank_status_info.Bank.is_C_bank_switched]', ...
                                         size(C_bank_status_info.Capacitor, 2), size(C_bank_status_info.Bank, 2)))';
                    overswitched_C_bank_status = find(is_C_bank_switched(:, count1) ~= 0);
                    overswitched_C_bank_status = [1; overswitched_C_bank_status];
                end
                if ~isempty(overswitched_C_bank_status)
                    overswitched_C_bank_status_count = size(overswitched_C_bank_status, 1);
                    for count2 = 1:overswitched_C_bank_status_count
                        status_num = overswitched_C_bank_status(count2, :);
                        switch status_num
                            case 1
                                if C_bank_status_info.Bank(status_num).k_C_at_status < ...
                                        C_bank_status_info.Bank(status_num + 1).k_C_at_status
                                    overswitched_C_bank_status(overswitched_C_bank_status == status_num) = 0;
                                end
                            case size(C_bank_status_info.Bank, 2)
                                if C_bank_status_info.Bank(status_num - 1).k_C_at_status > ...
                                        C_bank_status_info.Bank(status_num).k_C_at_status
                                    overswitched_C_bank_status(overswitched_C_bank_status == status_num) = 0;
                                end
                            otherwise
                                if (C_bank_status_info.Bank(status_num - 1).k_C_at_status > ...
                                        C_bank_status_info.Bank(status_num).k_C_at_status) && ...
                                        (C_bank_status_info.Bank(status_num).k_C_at_status < ...
                                        C_bank_status_info.Bank(status_num + 1).k_C_at_status)
                                    overswitched_C_bank_status(overswitched_C_bank_status == status_num) = 0;
                                end
                        end
                    end
                    overswitched_C_bank_status(overswitched_C_bank_status == 0) = [];
                    deltaE_quantity_Q_selected_neighbour = zeros(size(C_bank_status_info.Bank, 2), 1);
                    for status_num = 1:size(C_bank_status_info.Bank, 2)
                        deltaE_quantity_Q_last_at_current_status = C_bank_status_info.Bank(status_num).deltaE_quantity_Q_last;
                        deltaE_quantity_Q_next_at_current_status = C_bank_status_info.Bank(status_num).deltaE_quantity_Q_next;
                        if deltaE_quantity_Q_last_at_current_status < 0
                            deltaE_quantity_Q_last_at_current_status = inf;
                        end
                        if deltaE_quantity_Q_next_at_current_status < 0
                            deltaE_quantity_Q_next_at_current_status = inf;
                        end
                        deltaE_quantity_Q_selected_neighbour(status_num) = min([deltaE_quantity_Q_last_at_current_status, ...
                            deltaE_quantity_Q_next_at_current_status]);
                    end
                    [~, index] = sort(deltaE_quantity_Q_selected_neighbour(overswitched_C_bank_status), 'ascend');
                    curtailed_status_count = min([size(overswitched_C_bank_status, 1), overswitched_C_bank_status_count - Max_switch_times]);
                    overswitched_C_bank_status = overswitched_C_bank_status(index);
                    overswitched_C_bank_status(curtailed_status_count + 1:end) = [];
                    switch overswitched_C_bank_status(1)
                        case 1
                            if (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        case size(C_bank_status_info.Bank, 2)
                            if (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                if C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) == size(Q_L, 1)
                                    terminated_sample = size(Q_L, 1);
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        otherwise
                            if (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = max([C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status, ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status]);
                                curtailed_Q_C = max([C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status, ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status]);
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                    end
                end
                [~, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, C_bank_proportion, k_C, Q_C, Mode);
                overcurtailed_C_bank_status_count = size(C_bank_status_info.Bank, 2);
                for count3 = 1:overcurtailed_C_bank_status_count
                    discriminant = (Q_L(1:end-1) - C_bank_status_info.Bank(count3).Q_C_at_status).*(Q_L(2:end) - C_bank_status_info.Bank(count3).Q_C_at_status);
                    intersection = find(discriminant <= 0);
                    if C_bank_status_info.Bank(count3).is_C_bank_status_overcurtailed(1)
                        candidated_preceding_intersection = intersection(intersection < C_bank_status_info.Bank(count3).Sample_of_status(1) - 1);
                        preceding_intersection = candidated_preceding_intersection(end) + 1;
                        k_C(preceding_intersection:C_bank_status_info.Bank(count3).Sample_of_status(1), :) = C_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(preceding_intersection:C_bank_status_info.Bank(count3).Sample_of_status(1), :) = C_bank_status_info.Bank(count3).Q_C_at_status;
                        C_bank_status_info.Bank(count3 - 1).Sample_of_status(2) = preceding_intersection;
                        C_bank_status_info.Bank(count3).Sample_of_status(1) = preceding_intersection;
                    end
                    if C_bank_status_info.Bank(count3).is_C_bank_status_overcurtailed(2)
                        candidated_following_intersection = intersection(intersection >= C_bank_status_info.Bank(count3).Sample_of_status(2));
                        following_intersection = candidated_following_intersection(1);
                        k_C(C_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = C_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(C_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = C_bank_status_info.Bank(count3).Q_C_at_status;
                        C_bank_status_info.Bank(count3).Sample_of_status(2) = following_intersection + 1;
                        C_bank_status_info.Bank(count3 + 1).Sample_of_status(1) = following_intersection + 1;
                    end
                end
                [~, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, C_bank_proportion, k_C, Q_C, Mode);
            end

        case 0
            C_bank_count = size(C_bank_status_info.Capacitor, 2);
            [tipping_sample, delta_E_equatity_Q] = tipping_sample_selection(T_sample, Q_L, C_bank_status_info);
            for count1 = 1:C_bank_count
                C_bank_switch_times = C_bank_status_info.Capacitor(count1).C_bank_switch_times;
                overswitched_C_bank_status = [];
                if C_bank_switch_times > Max_switch_times
                    is_C_bank_switched = (reshape([C_bank_status_info.Bank.is_C_bank_switched]', ...
                                         size(C_bank_status_info.Capacitor, 2), size(C_bank_status_info.Bank, 2)))';
                    overswitched_C_bank_status = find(is_C_bank_switched(:, count1) ~= 0);
                    overswitched_C_bank_status = [1; overswitched_C_bank_status];
                end
                if ~isempty(overswitched_C_bank_status)
                    overswitched_C_bank_status_count = size(overswitched_C_bank_status, 1);
                    [~, index] = sort(delta_E_equatity_Q(overswitched_C_bank_status), 'ascend');
                    curtailed_status_count = min([size(overswitched_C_bank_status, 1), overswitched_C_bank_status_count - Max_switch_times]);
                    overswitched_C_bank_status = overswitched_C_bank_status(index);
                    overswitched_C_bank_status(curtailed_status_count + 1:end) = [];
                    switch overswitched_C_bank_status(1)
                        case 1
                            started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                            terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                            if terminated_sample < started_sample
                                terminated_sample = started_sample;
                            end
                            curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status;
                            curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status;
                            k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                            Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                        case size(C_bank_status_info.Bank, 2)
                            started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                            terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                            if terminated_sample < started_sample
                                terminated_sample = started_sample;
                            end
                            curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                            curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                            k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                            Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                        otherwise
                            started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                            terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                            if terminated_sample < started_sample
                                terminated_sample = started_sample;
                            end
                            curtailed_k_C_last_status = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                            curtailed_Q_C_last_status = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                            k_C(started_sample:tipping_sample(overswitched_C_bank_status(1)) - 1, :) = curtailed_k_C_last_status;
                            Q_C(started_sample:tipping_sample(overswitched_C_bank_status(1)) - 1, :) = curtailed_Q_C_last_status;
                            curtailed_k_C_next_status = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                            curtailed_Q_C_next_status = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                            k_C(tipping_sample(overswitched_C_bank_status(1)):terminated_sample, :) = curtailed_k_C_next_status;
                            Q_C(tipping_sample(overswitched_C_bank_status(1)):terminated_sample, :) = curtailed_Q_C_next_status;
                    end
                end
                [~, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, C_bank_proportion, k_C, Q_C, Mode);
                overcurtailed_C_bank_status_count = size(C_bank_status_info.Bank, 2);
                for count3 = 1:overcurtailed_C_bank_status_count
                    discriminant = (Q_L(1:end-1) - C_bank_status_info.Bank(count3).Q_C_at_status).*(Q_L(2:end) - C_bank_status_info.Bank(count3).Q_C_at_status);
                    intersection = find(discriminant <= 0);
                    if C_bank_status_info.Bank(count3).is_C_bank_status_overcurtailed(1)
                        candidated_preceding_intersection = intersection(intersection < C_bank_status_info.Bank(count3).Sample_of_status(1) - 1);
                        preceding_intersection = candidated_preceding_intersection(end) + 1;
                        k_C(preceding_intersection:C_bank_status_info.Bank(count3).Sample_of_status(1), :) = C_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(preceding_intersection:C_bank_status_info.Bank(count3).Sample_of_status(1), :) = C_bank_status_info.Bank(count3).Q_C_at_status;
                        C_bank_status_info.Bank(count3 - 1).Sample_of_status(2) = preceding_intersection;
                        C_bank_status_info.Bank(count3).Sample_of_status(1) = preceding_intersection;
                    end
                    if C_bank_status_info.Bank(count3).is_C_bank_status_overcurtailed(2)
                        candidated_following_intersection = intersection(intersection >= C_bank_status_info.Bank(count3).Sample_of_status(2));
                        following_intersection = candidated_following_intersection(1);
                        k_C(C_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = C_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(C_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = C_bank_status_info.Bank(count3).Q_C_at_status;
                        C_bank_status_info.Bank(count3).Sample_of_status(2) = following_intersection + 1;
                        C_bank_status_info.Bank(count3 + 1).Sample_of_status(1) = following_intersection + 1;
                    end
                end
                [~, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, C_bank_proportion, k_C, Q_C, Mode);
            end
            
         case -1
            C_bank_count = size(C_bank_status_info.Capacitor, 2);
            for count1 = 1:C_bank_count
                C_bank_switch_times = C_bank_status_info.Capacitor(count1).C_bank_switch_times;
                overswitched_C_bank_status = [];
                if C_bank_switch_times > Max_switch_times
                    is_C_bank_switched = (reshape([C_bank_status_info.Bank.is_C_bank_switched]', ...
                                         size(C_bank_status_info.Capacitor, 2), size(C_bank_status_info.Bank, 2)))';
                    overswitched_C_bank_status = find(is_C_bank_switched(:, count1) ~= 0);
                    overswitched_C_bank_status = [1; overswitched_C_bank_status];
                end
                if ~isempty(overswitched_C_bank_status)
                    overswitched_C_bank_status_count = size(overswitched_C_bank_status, 1);
                    for count2 = 1:overswitched_C_bank_status_count
                        status_num = overswitched_C_bank_status(count2, :);
                        switch status_num
                            case 1
                                if C_bank_status_info.Bank(status_num).k_C_at_status > ...
                                        C_bank_status_info.Bank(status_num + 1).k_C_at_status
                                    overswitched_C_bank_status(overswitched_C_bank_status == status_num) = 0;
                                end
                            case size(C_bank_status_info.Bank, 2)
                                if C_bank_status_info.Bank(status_num - 1).k_C_at_status < ...
                                        C_bank_status_info.Bank(status_num).k_C_at_status
                                    overswitched_C_bank_status(overswitched_C_bank_status == status_num) = 0;
                                end
                            otherwise
                                if (C_bank_status_info.Bank(status_num - 1).k_C_at_status < ...
                                        C_bank_status_info.Bank(status_num).k_C_at_status) && ...
                                        (C_bank_status_info.Bank(status_num).k_C_at_status > ...
                                        C_bank_status_info.Bank(status_num + 1).k_C_at_status)
                                    overswitched_C_bank_status(overswitched_C_bank_status == status_num) = 0;
                                end
                        end
                    end
                    overswitched_C_bank_status(overswitched_C_bank_status == 0) = [];
                    deltaE_quantity_Q_selected_neighbour = zeros(size(C_bank_status_info.Bank, 2), 1);
                    for status_num = 1:size(C_bank_status_info.Bank, 2)
                        deltaE_quantity_Q_last_at_current_status = C_bank_status_info.Bank(status_num).deltaE_quantity_Q_last;
                        deltaE_quantity_Q_next_at_current_status = C_bank_status_info.Bank(status_num).deltaE_quantity_Q_next;
                        if deltaE_quantity_Q_last_at_current_status > 0
                            deltaE_quantity_Q_last_at_current_status = -inf;
                        end
                        if deltaE_quantity_Q_next_at_current_status > 0
                            deltaE_quantity_Q_next_at_current_status = -inf;
                        end
                        deltaE_quantity_Q_selected_neighbour(status_num) = max([deltaE_quantity_Q_last_at_current_status, ...
                            deltaE_quantity_Q_next_at_current_status]);
                    end
                    [~, index] = sort(deltaE_quantity_Q_selected_neighbour(overswitched_C_bank_status), 'descend');
                    overswitched_C_bank_status_count = min([size(overswitched_C_bank_status, 1), overswitched_C_bank_status_count - Max_switch_times]);
                    overswitched_C_bank_status = overswitched_C_bank_status(index);
                    overswitched_C_bank_status(overswitched_C_bank_status_count + 1:end) = [];
                    switch overswitched_C_bank_status(1)
                        case 1
                            if (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        case size(C_bank_status_info.Bank, 2)
                            if (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                if C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) == size(Q_L, 1)
                                    terminated_sample = size(Q_L, 1);
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        otherwise
                            if (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = min([C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status, ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status]);
                                curtailed_Q_C = min([C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status, ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status]);
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status < ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(overswitched_C_bank_status(1)).k_C_at_status > ...
                                    C_bank_status_info.Bank(overswitched_C_bank_status(1) + 1).k_C_at_status)
                                started_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(1);
                                terminated_sample = C_bank_status_info.Bank(overswitched_C_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = C_bank_status_info.Bank(overswitched_C_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                    end
                end
                [~, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, C_bank_proportion, k_C, Q_C, Mode);
                overcurtailed_C_bank_status_count = size(C_bank_status_info.Bank, 2);
                for count3 = 1:overcurtailed_C_bank_status_count
                    discriminant = (Q_L(1:end-1) - C_bank_status_info.Bank(count3).Q_C_at_status).*(Q_L(2:end) - C_bank_status_info.Bank(count3).Q_C_at_status);
                    intersection = find(discriminant <= 0);
                    if C_bank_status_info.Bank(count3).is_C_bank_status_overcurtailed(1)
                        candidated_preceding_intersection = intersection(intersection < C_bank_status_info.Bank(count3).Sample_of_status(1) - 1);
                        preceding_intersection = candidated_preceding_intersection(end) + 1;
                        k_C(preceding_intersection:C_bank_status_info.Bank(count3).Sample_of_status(1), :) = C_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(preceding_intersection:C_bank_status_info.Bank(count3).Sample_of_status(1), :) = C_bank_status_info.Bank(count3).Q_C_at_status;
                        C_bank_status_info.Bank(count3 - 1).Sample_of_status(2) = preceding_intersection;
                        C_bank_status_info.Bank(count3).Sample_of_status(1) = preceding_intersection;
                    end
                    if C_bank_status_info.Bank(count3).is_C_bank_status_overcurtailed(2)
                        candidated_following_intersection = intersection(intersection >= C_bank_status_info.Bank(count3).Sample_of_status(2));
                        following_intersection = candidated_following_intersection(1);
                        k_C(C_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = C_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(C_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = C_bank_status_info.Bank(count3).Q_C_at_status;
                        C_bank_status_info.Bank(count3).Sample_of_status(2) = following_intersection + 1;
                        C_bank_status_info.Bank(count3 + 1).Sample_of_status(1) = following_intersection + 1;
                    end
                end
                [~, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, C_bank_proportion, k_C, Q_C, Mode);
            end

        otherwise
            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');

    end
end