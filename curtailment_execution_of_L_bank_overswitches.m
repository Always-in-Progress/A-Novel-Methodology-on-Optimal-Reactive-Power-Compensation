function [k_C, Q_C] = curtailment_execution_of_L_bank_overswitches(T_sample, Q_L, L_bank_proportion, ...
                                                                   k_C, Q_C, Max_switch_times, ...
                                                                   L_bank_status_info, Mode)

    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end
    
    switch Mode
        case 1
            L_bank_count = size(L_bank_status_info.Reactor, 2);
            for count1 = 1:L_bank_count
                L_bank_switch_times = L_bank_status_info.Reactor(count1).L_bank_switch_times;
                overswitched_L_bank_status = [];
                if L_bank_switch_times > Max_switch_times
                    is_L_bank_switched = (reshape([L_bank_status_info.Bank.is_L_bank_switched]', ...
                                         size(L_bank_status_info.Reactor, 2), size(L_bank_status_info.Bank, 2)))';
                    overswitched_L_bank_status = find(is_L_bank_switched(:, count1) ~= 0);
                    overswitched_L_bank_status = [1; overswitched_L_bank_status];
                end
                if ~isempty(overswitched_L_bank_status)
                    overswitched_L_bank_status_count = size(overswitched_L_bank_status, 1);
                    for count2 = 1:overswitched_L_bank_status_count
                        status_num = overswitched_L_bank_status(count2, :);
                        switch status_num
                            case 1
                                if L_bank_status_info.Bank(status_num).k_C_at_status > ...
                                        L_bank_status_info.Bank(status_num + 1).k_C_at_status
                                    overswitched_L_bank_status(overswitched_L_bank_status == status_num) = 0;
                                end
                            case size(L_bank_status_info.Bank, 2)
                                if L_bank_status_info.Bank(status_num - 1).k_C_at_status < ...
                                        L_bank_status_info.Bank(status_num).k_C_at_status
                                    overswitched_L_bank_status(overswitched_L_bank_status == status_num) = 0;
                                end
                            otherwise
                                if (L_bank_status_info.Bank(status_num - 1).k_C_at_status < ...
                                        L_bank_status_info.Bank(status_num).k_C_at_status) && ...
                                        (L_bank_status_info.Bank(status_num).k_C_at_status > ...
                                        L_bank_status_info.Bank(status_num + 1).k_C_at_status)
                                    overswitched_L_bank_status(overswitched_L_bank_status == status_num) = 0;
                                end
                        end
                    end
                    overswitched_L_bank_status(overswitched_L_bank_status == 0) = [];
                    deltaE_quantity_Q_selected_neighbour = zeros(size(L_bank_status_info.Bank, 2), 1);
                    for status_num = 1:size(L_bank_status_info.Bank, 2)
                        deltaE_quantity_Q_last_at_current_status = L_bank_status_info.Bank(status_num).deltaE_quantity_Q_last;
                        deltaE_quantity_Q_next_at_current_status = L_bank_status_info.Bank(status_num).deltaE_quantity_Q_next;
                        if deltaE_quantity_Q_last_at_current_status < 0
                            deltaE_quantity_Q_last_at_current_status = inf;
                        end
                        if deltaE_quantity_Q_next_at_current_status < 0
                            deltaE_quantity_Q_next_at_current_status = inf;
                        end
                        deltaE_quantity_Q_selected_neighbour(status_num) = min([deltaE_quantity_Q_last_at_current_status, ...
                            deltaE_quantity_Q_next_at_current_status]);
                    end
                    [~, index] = sort(deltaE_quantity_Q_selected_neighbour(overswitched_L_bank_status), 'ascend');
                    curtailed_status_count = min([size(overswitched_L_bank_status, 1), overswitched_L_bank_status_count - Max_switch_times]);
                    overswitched_L_bank_status = overswitched_L_bank_status(index);
                    overswitched_L_bank_status(curtailed_status_count + 1:end) = [];
                    switch overswitched_L_bank_status(1)
                        case 1
                            if (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        case size(L_bank_status_info.Bank, 2)
                            if (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                if L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) == size(Q_L, 1)
                                    terminated_sample = size(Q_L, 1);
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        otherwise
                            if (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = min([L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status, ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status]);
                                curtailed_Q_C = max([L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status, ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status]);
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                    end
                end
                [~, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, L_bank_proportion, k_C, Q_C, Mode);
                overcurtailed_L_bank_status_count = size(L_bank_status_info.Bank, 2);
                for count3 = 1:overcurtailed_L_bank_status_count
                    discriminant = (Q_L(1:end-1) - L_bank_status_info.Bank(count3).Q_C_at_status).*(Q_L(2:end) - L_bank_status_info.Bank(count3).Q_C_at_status);
                    intersection = find(discriminant <= 0);
                    if L_bank_status_info.Bank(count3).is_L_bank_status_overcurtailed(1)
                        candidated_preceding_intersection = intersection(intersection < L_bank_status_info.Bank(count3).Sample_of_status(1) - 1);
                        preceding_intersection = candidated_preceding_intersection(end) + 1;
                        k_C(preceding_intersection:L_bank_status_info.Bank(count3).Sample_of_status(1) - 1, :) = L_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(preceding_intersection:L_bank_status_info.Bank(count3).Sample_of_status(1) - 1, :) = L_bank_status_info.Bank(count3).Q_C_at_status;
                        L_bank_status_info.Bank(count3 - 1).Sample_of_status(2) = preceding_intersection;
                        L_bank_status_info.Bank(count3).Sample_of_status(1) = preceding_intersection;
                    end
                    if L_bank_status_info.Bank(count3).is_L_bank_status_overcurtailed(2)
                        candidated_following_intersection = intersection(intersection >= L_bank_status_info.Bank(count3).Sample_of_status(2));
                        following_intersection = candidated_following_intersection(1);
                        k_C(L_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = L_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(L_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = L_bank_status_info.Bank(count3).Q_C_at_status;
                        L_bank_status_info.Bank(count3).Sample_of_status(2) = following_intersection + 1;
                        L_bank_status_info.Bank(count3 + 1).Sample_of_status(1) = following_intersection + 1;
                    end
                end
                [~, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, L_bank_proportion, k_C, Q_C, Mode);
            end

        case 0
            L_bank_count = size(L_bank_status_info.Reactor, 2);
            [tipping_sample, delta_E_equatity_Q] = tipping_sample_selection(T_sample, Q_L, L_bank_status_info);
            for count1 = 1:L_bank_count
                L_bank_switch_times = L_bank_status_info.Reactor(count1).L_bank_switch_times;
                overswitched_L_bank_status = [];
                if L_bank_switch_times > Max_switch_times
                    is_L_bank_switched = (reshape([L_bank_status_info.Bank.is_L_bank_switched]', ...
                                         size(L_bank_status_info.Reactor, 2), size(L_bank_status_info.Bank, 2)))';
                    overswitched_L_bank_status = find(is_L_bank_switched(:, count1) ~= 0);
                    overswitched_L_bank_status = [1; overswitched_L_bank_status];
                end
                if ~isempty(overswitched_L_bank_status)
                    overswitched_L_bank_status_count = size(overswitched_L_bank_status, 1);
                    [~, index] = sort(delta_E_equatity_Q(overswitched_L_bank_status), 'ascend');
                    curtailed_status_count = min([size(overswitched_L_bank_status, 1), overswitched_L_bank_status_count - Max_switch_times]);
                    overswitched_L_bank_status = overswitched_L_bank_status(index);
                    overswitched_L_bank_status(curtailed_status_count + 1:end) = [];
                    switch overswitched_L_bank_status(1)
                        case 1
                            started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                            terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                            if terminated_sample < started_sample
                                terminated_sample = started_sample;
                            end
                            curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status;
                            curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status;
                            k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                            Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                        case size(L_bank_status_info.Bank, 2)
                            started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                            terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                            if terminated_sample < started_sample
                                terminated_sample = started_sample;
                            end
                            curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                            curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                            k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                            Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                        otherwise
                            started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                            terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                            if terminated_sample < started_sample
                                terminated_sample = started_sample;
                            end
                            curtailed_k_C_last_status = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                            curtailed_Q_C_last_status = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                            k_C(started_sample:tipping_sample(overswitched_L_bank_status(1)) - 1, :) = curtailed_k_C_last_status;
                            Q_C(started_sample:tipping_sample(overswitched_L_bank_status(1)) - 1, :) = curtailed_Q_C_last_status;
                            curtailed_k_C_next_status = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                            curtailed_Q_C_next_status = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                            k_C(tipping_sample(overswitched_L_bank_status(1)):terminated_sample, :) = curtailed_k_C_next_status;
                            Q_C(tipping_sample(overswitched_L_bank_status(1)):terminated_sample, :) = curtailed_Q_C_next_status;
                    end
                end
                [~, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, L_bank_proportion, k_C, Q_C, Mode);
                overcurtailed_L_bank_status_count = size(L_bank_status_info.Bank, 2);
                for count3 = 1:overcurtailed_L_bank_status_count
                    discriminant = (Q_L(1:end-1) - L_bank_status_info.Bank(count3).Q_C_at_status).*(Q_L(2:end) - L_bank_status_info.Bank(count3).Q_C_at_status);
                    intersection = find(discriminant <= 0);
                    if L_bank_status_info.Bank(count3).is_L_bank_status_overcurtailed(1)
                        candidated_preceding_intersection = intersection(intersection < L_bank_status_info.Bank(count3).Sample_of_status(1) - 1);
                        preceding_intersection = candidated_preceding_intersection(end) + 1;
                        k_C(preceding_intersection:L_bank_status_info.Bank(count3).Sample_of_status(1), :) = L_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(preceding_intersection:L_bank_status_info.Bank(count3).Sample_of_status(1), :) = L_bank_status_info.Bank(count3).Q_C_at_status;
                        L_bank_status_info.Bank(count3 - 1).Sample_of_status(2) = preceding_intersection;
                        L_bank_status_info.Bank(count3).Sample_of_status(1) = preceding_intersection;
                    end
                    if L_bank_status_info.Bank(count3).is_L_bank_status_overcurtailed(2)
                        candidated_following_intersection = intersection(intersection >= L_bank_status_info.Bank(count3).Sample_of_status(2));
                        following_intersection = candidated_following_intersection(1);
                        k_C(L_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = L_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(L_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = L_bank_status_info.Bank(count3).Q_C_at_status;
                        L_bank_status_info.Bank(count3).Sample_of_status(2) = following_intersection + 1;
                        L_bank_status_info.Bank(count3 + 1).Sample_of_status(1) = following_intersection + 1;
                    end
                end
                [~, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, L_bank_proportion, k_C, Q_C, Mode);
            end

            
        case -1
            L_bank_count = size(L_bank_status_info.Reactor, 2);
            for count1 = 1:L_bank_count
                L_bank_switch_times = L_bank_status_info.Reactor(count1).L_bank_switch_times;
                overswitched_L_bank_status = [];
                if L_bank_switch_times > Max_switch_times
                    is_L_bank_switched = (reshape([L_bank_status_info.Bank.is_L_bank_switched]', ...
                                         size(L_bank_status_info.Reactor, 2), size(L_bank_status_info.Bank, 2)))';
                    overswitched_L_bank_status = find(is_L_bank_switched(:, count1) ~= 0);
                    overswitched_L_bank_status = [1; overswitched_L_bank_status];
                end
                if ~isempty(overswitched_L_bank_status)
                    overswitched_L_bank_status_count = size(overswitched_L_bank_status, 1);
                    for count2 = 1:overswitched_L_bank_status_count
                        status_num = overswitched_L_bank_status(count2, :);
                        switch status_num
                            case 1
                                if L_bank_status_info.Bank(status_num).k_C_at_status < ...
                                        L_bank_status_info.Bank(status_num + 1).k_C_at_status
                                    overswitched_L_bank_status(overswitched_L_bank_status == status_num) = 0;
                                end
                            case size(L_bank_status_info.Bank, 2)
                                if L_bank_status_info.Bank(status_num - 1).k_C_at_status > ...
                                        L_bank_status_info.Bank(status_num).k_C_at_status
                                    overswitched_L_bank_status(overswitched_L_bank_status == status_num) = 0;
                                end
                            otherwise
                                if (L_bank_status_info.Bank(status_num - 1).k_C_at_status > ...
                                        L_bank_status_info.Bank(status_num).k_C_at_status) && ...
                                        (L_bank_status_info.Bank(status_num).k_C_at_status < ...
                                        L_bank_status_info.Bank(status_num + 1).k_C_at_status)
                                    overswitched_L_bank_status(overswitched_L_bank_status == status_num) = 0;
                                end
                        end
                    end
                    overswitched_L_bank_status(overswitched_L_bank_status == 0) = [];
                    deltaE_quantity_Q_selected_neighbour = zeros(size(L_bank_status_info.Bank, 2), 1);
                    for status_num = 1:size(L_bank_status_info.Bank, 2)
                        deltaE_quantity_Q_last_at_current_status = L_bank_status_info.Bank(status_num).deltaE_quantity_Q_last;
                        deltaE_quantity_Q_next_at_current_status = L_bank_status_info.Bank(status_num).deltaE_quantity_Q_next;
                        if deltaE_quantity_Q_last_at_current_status > 0
                            deltaE_quantity_Q_last_at_current_status = -inf;
                        end
                        if deltaE_quantity_Q_next_at_current_status > 0
                            deltaE_quantity_Q_next_at_current_status = -inf;
                        end
                        deltaE_quantity_Q_selected_neighbour(status_num) = max([deltaE_quantity_Q_last_at_current_status, ...
                            deltaE_quantity_Q_next_at_current_status]);
                    end
                    [~, index] = sort(deltaE_quantity_Q_selected_neighbour(overswitched_L_bank_status), 'descend');
                    curtailed_status_count = min([size(overswitched_L_bank_status, 1), overswitched_L_bank_status_count - Max_switch_times]);
                    overswitched_L_bank_status = overswitched_L_bank_status(index);
                    overswitched_L_bank_status(curtailed_status_count + 1:end) = [];
                    switch overswitched_L_bank_status(1)
                        case 1
                            if (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        case size(L_bank_status_info.Bank, 2)
                            if (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                if L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) == size(Q_L, 1)
                                    terminated_sample = size(Q_L, 1);
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                        otherwise
                            if (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = max([L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status, ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status]);
                                curtailed_Q_C = min([L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status, ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status]);
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status < ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            elseif (L_bank_status_info.Bank(overswitched_L_bank_status(1) - 1).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(overswitched_L_bank_status(1)).k_C_at_status > ...
                                    L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status)
                                started_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(1);
                                terminated_sample = L_bank_status_info.Bank(overswitched_L_bank_status(1)).Sample_of_status(2) - 1;
                                if terminated_sample < started_sample
                                    terminated_sample = started_sample;
                                end
                                curtailed_k_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).k_C_at_status;
                                curtailed_Q_C = L_bank_status_info.Bank(overswitched_L_bank_status(1) + 1).Q_C_at_status;
                                k_C(started_sample:terminated_sample, :) = curtailed_k_C;
                                Q_C(started_sample:terminated_sample, :) = curtailed_Q_C;
                            end
                    end
                end
                [~, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, L_bank_proportion, k_C, Q_C, Mode);
                overcurtailed_L_bank_status_count = size(L_bank_status_info.Bank, 2);
                for count3 = 1:overcurtailed_L_bank_status_count
                    discriminant = (Q_L(1:end-1) - L_bank_status_info.Bank(count3).Q_C_at_status).*(Q_L(2:end) - L_bank_status_info.Bank(count3).Q_C_at_status);
                    intersection = find(discriminant <= 0);
                    if L_bank_status_info.Bank(count3).is_L_bank_status_overcurtailed(1)
                        candidated_preceding_intersection = intersection(intersection < L_bank_status_info.Bank(count3).Sample_of_status(1) - 1);
                        preceding_intersection = candidated_preceding_intersection(end) + 1;
                        k_C(preceding_intersection:L_bank_status_info.Bank(count3).Sample_of_status(1) - 1, :) = L_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(preceding_intersection:L_bank_status_info.Bank(count3).Sample_of_status(1) - 1, :) = L_bank_status_info.Bank(count3).Q_C_at_status;
                        L_bank_status_info.Bank(count3 - 1).Sample_of_status(2) = preceding_intersection;
                        L_bank_status_info.Bank(count3).Sample_of_status(1) = preceding_intersection;
                    end
                    if L_bank_status_info.Bank(count3).is_L_bank_status_overcurtailed(2)
                        candidated_following_intersection = intersection(intersection >= L_bank_status_info.Bank(count3).Sample_of_status(2));
                        following_intersection = candidated_following_intersection(1);
                        k_C(L_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = L_bank_status_info.Bank(count3).k_C_at_status;
                        Q_C(L_bank_status_info.Bank(count3).Sample_of_status(2):following_intersection, :) = L_bank_status_info.Bank(count3).Q_C_at_status;
                        L_bank_status_info.Bank(count3).Sample_of_status(2) = following_intersection + 1;
                        L_bank_status_info.Bank(count3 + 1).Sample_of_status(1) = following_intersection + 1;
                    end
                end
                [~, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, L_bank_proportion, k_C, Q_C, Mode);
            end

        otherwise
            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');

    end
end