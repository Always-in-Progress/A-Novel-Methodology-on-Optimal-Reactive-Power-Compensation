function [schedule_info, L_bank_status_info] = schedule_and_L_bank_status_info(T_sample, Q_L, ...
                                                                               L_bank_proportion, ...
                                                                               k_C, Q_C, Mode)

    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end

    schedule_info = struct;
    L_bank_status_info = struct;

    schedule_info.real_time_status = struct;
    schedule_info.total_E_quantity_Q = struct;
    L_bank_status_info.Reactor = struct;
    L_bank_status_info.Bank = struct;
    
    real_time_L_bank_status = zeros(size(Q_L, 1), size(L_bank_proportion, 2));
    L_bank_permutations = zeros(2^size(L_bank_proportion, 2), size(L_bank_proportion, 2));
    number = 0;
    for count = 0:size(L_bank_proportion, 2)
        L_bank_permutations(number + 1:number + nchoosek(size(L_bank_proportion, 2), count), :) = ...
            unique(perms([ones(1, count), zeros(1, size(L_bank_proportion, 2) - count)]), ...
            'rows');
        number = number + nchoosek(size(L_bank_proportion, 2), count);
    end
    L_bank_taps = sum(L_bank_proportion.*L_bank_permutations, 2);
    for count = 1:size(Q_L, 1)
        flag = find(L_bank_taps == k_C(count, :));
        real_time_L_bank_status(count, :) = L_bank_permutations(flag(1), :);
    end
    
    is_L_bank_switched = [zeros(1, size(L_bank_proportion, 2)); -1*(real_time_L_bank_status(1:end-1, :) ...
        > real_time_L_bank_status(2:end, :)) + (real_time_L_bank_status(1:end-1, :) < ...
        real_time_L_bank_status(2:end, :))];
    for count = 1:size(L_bank_proportion, 2)
        schedule_info.real_time_status(count).real_time_L_bank_status = real_time_L_bank_status(:, count);
        schedule_info.real_time_status(count).is_L_bank_switched = is_L_bank_switched(:, count);
    end

    for count = 1:size(L_bank_proportion, 2)
        L_bank_status_info.Reactor(count).Number = count;
        L_bank_status_info.Reactor(count).Proportion = L_bank_proportion(count);
        L_bank_status_info.Reactor(count).Real_time_status = real_time_L_bank_status(:, count);
        L_bank_status_info.Reactor(count).Sample_when_switched = find(is_L_bank_switched(:, count));
        L_bank_status_info.Reactor(count).Time_when_switched = ...
            T_sample*(L_bank_status_info.Reactor(count).Sample_when_switched - 1);
        L_bank_status_info.Reactor(count).Sample_when_switched_on = ...
            find(is_L_bank_switched(:, count) == 1);
        L_bank_status_info.Reactor(count).Sample_when_switched_off = ...
            find(is_L_bank_switched(:, count) == -1);
        L_bank_status_info.Reactor(count).Time_when_switched_on = ...
            T_sample*(L_bank_status_info.Reactor(count).Sample_when_switched_on - 1);
        L_bank_status_info.Reactor(count).Time_when_switched_off = ...
            T_sample*(L_bank_status_info.Reactor(count).Sample_when_switched_off - 1);
        L_bank_status_info.Reactor(count).L_bank_switch_on_times = ...
            sum(is_L_bank_switched(:, count) == 1, 1);
        L_bank_status_info.Reactor(count).L_bank_switch_off_times = ...
            sum(is_L_bank_switched(:, count) == -1, 1);
        L_bank_status_info.Reactor(count).L_bank_switch_times = ...
            L_bank_status_info.Reactor(count).L_bank_switch_on_times + ...
            L_bank_status_info.Reactor(count).L_bank_switch_off_times;
        L_bank_status_info.Reactor(count).L_bank_operating_samplespan = ...
            sum(real_time_L_bank_status(:, count));
        L_bank_status_info.Reactor(count).L_bank_operating_timespan = ...
            T_sample*L_bank_status_info.Reactor(count).L_bank_operating_samplespan;  
    end

    sample_of_status = [1, find(any(is_L_bank_switched, 2))'; ...
                       find(any(is_L_bank_switched, 2))', size(Q_L, 1)]';
    status_count = size(sample_of_status, 1);
    for count = 1:status_count
        L_bank_status_info.Bank(count).Status_number = count;
        L_bank_status_info.Bank(count).Sample_of_status = sample_of_status(count, :);
        L_bank_status_info.Bank(count).Samplespan_of_status = diff((sample_of_status(count, :))')';
        L_bank_status_info.Bank(count).Time_of_status = T_sample*(sample_of_status(count, :) - 1);
        L_bank_status_info.Bank(count).Timespan_of_status = T_sample*diff((sample_of_status(count, :))')';
        L_bank_status_info.Bank(count).Merged_L_bank_status = real_time_L_bank_status(sample_of_status...
                                                              (count, 1), :);
        L_bank_status_info.Bank(count).k_C_at_status = sum(L_bank_status_info.Bank(count).Merged_L_bank_status...
                                                       .*L_bank_proportion, 2);
        L_bank_status_info.Bank(count).Q_C_at_status = Q_C(sample_of_status(count, 1), :);
        L_bank_status_info.Bank(count).E_quantity_Q = (sum(abs(Q_L(sample_of_status(count, 1):sample_of_status(count, 2) - 1, ...
                                                      :) - L_bank_status_info.Bank(count).Q_C_at_status), 1))*T_sample;
    end

    if status_count > 1
        for count = 1:status_count
            switch count
                case 1
                    L_bank_status_info.Bank(count).deltaE_quantity_Q_last = [];
                    L_bank_status_info.Bank(count).deltaE_quantity_Q_next = ...
                        (L_bank_status_info.Bank(count).Q_C_at_status - ...
                        L_bank_status_info.Bank(count + 1).Q_C_at_status) ...
                        *L_bank_status_info.Bank(count).Timespan_of_status;
                    L_bank_status_info.Bank(count).is_L_bank_switched = zeros(1, size(L_bank_proportion, 2));
                    L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed = false(1, 2);
                    switch Mode
                        case 1
                            if (L_bank_status_info.Bank(count).k_C_at_status < L_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status < Q_L(L_bank_status_info.Bank(count).Sample_of_status(2)))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(2) = true;
                            end
                        case 0
    
                        case -1
                            if (L_bank_status_info.Bank(count).k_C_at_status > L_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status > Q_L(L_bank_status_info.Bank(count).Sample_of_status(2)))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(2) = true;
                            end
                        otherwise
                            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');
                    end
                case status_count
                    L_bank_status_info.Bank(count).deltaE_quantity_Q_last = ...
                        (L_bank_status_info.Bank(count).Q_C_at_status - ...
                        L_bank_status_info.Bank(count - 1).Q_C_at_status) ...
                        *L_bank_status_info.Bank(count).Timespan_of_status;
                    L_bank_status_info.Bank(count).deltaE_quantity_Q_next = [];
                    L_bank_status_info.Bank(count).is_L_bank_switched = [is_L_bank_switched(sample_of_status...
                                                                        (count, 1), :)];
                    L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed = false(1, 2);
                    switch Mode
                        case 1
                            if (L_bank_status_info.Bank(count - 1).k_C_at_status > L_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status < Q_L(L_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(1) = true;
                            end
                        case 0
    
                        case -1
                            if (L_bank_status_info.Bank(count - 1).k_C_at_status < L_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status > Q_L(L_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(1) = true;
                            end
                        otherwise
                            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');
                    end
                otherwise
                    L_bank_status_info.Bank(count).deltaE_quantity_Q_last = ...
                        (L_bank_status_info.Bank(count).Q_C_at_status - ...
                        L_bank_status_info.Bank(count - 1).Q_C_at_status) ...
                        *L_bank_status_info.Bank(count).Timespan_of_status;
                    L_bank_status_info.Bank(count).deltaE_quantity_Q_next = ...
                        (L_bank_status_info.Bank(count).Q_C_at_status - ...
                        L_bank_status_info.Bank(count + 1).Q_C_at_status) ...
                        *L_bank_status_info.Bank(count).Timespan_of_status;
                    L_bank_status_info.Bank(count).is_L_bank_switched = [is_L_bank_switched(sample_of_status...
                                                                        (count, 1), :)];
                    L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed = false(1, 2);
                    switch Mode
                        case 1
                            if (L_bank_status_info.Bank(count - 1).k_C_at_status > L_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status < Q_L(L_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(1) = true;
                            end
                            if (L_bank_status_info.Bank(count).k_C_at_status < L_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status < Q_L(L_bank_status_info.Bank(count).Sample_of_status(2)))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(2) = true;
                            end
                        case 0
    
                        case -1
                            if (L_bank_status_info.Bank(count - 1).k_C_at_status < L_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status > Q_L(L_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(1) = true;
                            end
                            if (L_bank_status_info.Bank(count).k_C_at_status > L_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (L_bank_status_info.Bank(count).Q_C_at_status > Q_L(L_bank_status_info.Bank(count).Sample_of_status(2)))
                                L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed(2) = true;
                            end
                        otherwise
                            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');
                    end
            end
        end

    else
        L_bank_status_info.Bank(count).deltaE_quantity_Q_last = [];
        L_bank_status_info.Bank(count).deltaE_quantity_Q_next = [];
        L_bank_status_info.Bank(count).is_L_bank_switched = zeros(1, size(L_bank_proportion, 2));
        L_bank_status_info.Bank(count).is_L_bank_status_overcurtailed = false(1, 2);
    end

    schedule_info.total_E_quantity_Q.before_switching = sum(abs(Q_L), 1) * T_sample;
    schedule_info.total_E_quantity_Q.after_switching = sum([L_bank_status_info.Bank.E_quantity_Q], 2);

end