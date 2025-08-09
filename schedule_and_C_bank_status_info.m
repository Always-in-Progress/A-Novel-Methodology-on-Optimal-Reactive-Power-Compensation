function [schedule_info, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, ...
                                                                               C_bank_proportion, ...
                                                                               k_C, Q_C, Mode)

    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end

    schedule_info = struct;
    C_bank_status_info = struct;

    schedule_info.real_time_status = struct;
    schedule_info.total_E_quantity_Q = struct;
    C_bank_status_info.Capacitor = struct;
    C_bank_status_info.Bank = struct;
    
    real_time_C_bank_status = zeros(size(Q_L, 1), size(C_bank_proportion, 2));
    C_bank_permutations = zeros(2^size(C_bank_proportion, 2), size(C_bank_proportion, 2));
    number = 0;
    for count = 0:size(C_bank_proportion, 2)
        C_bank_permutations(number + 1:number + nchoosek(size(C_bank_proportion, 2), count), :) = ...
            unique(perms([ones(1, count), zeros(1, size(C_bank_proportion, 2) - count)]), ...
            'rows');
        number = number + nchoosek(size(C_bank_proportion, 2), count);
    end
    C_bank_taps = sum(C_bank_proportion.*C_bank_permutations, 2);
    for count = 1:size(Q_L, 1)
        flag = find(C_bank_taps == k_C(count, :));
        real_time_C_bank_status(count, :) = C_bank_permutations(flag(1), :);
    end
    
    is_C_bank_switched = [zeros(1, size(C_bank_proportion, 2)); -1*(real_time_C_bank_status(1:end-1, :) ...
        > real_time_C_bank_status(2:end, :)) + (real_time_C_bank_status(1:end-1, :) < ...
        real_time_C_bank_status(2:end, :))];
    for count = 1:size(C_bank_proportion, 2)
        schedule_info.real_time_status(count).real_time_C_bank_status = real_time_C_bank_status(:, count);
        schedule_info.real_time_status(count).is_C_bank_switched = is_C_bank_switched(:, count);
    end

    for count = 1:size(C_bank_proportion, 2)
        C_bank_status_info.Capacitor(count).Number = count;
        C_bank_status_info.Capacitor(count).Proportion = C_bank_proportion(count);
        C_bank_status_info.Capacitor(count).Real_time_status = real_time_C_bank_status(:, count);
        C_bank_status_info.Capacitor(count).Sample_when_switched = find(is_C_bank_switched(:, count));
        C_bank_status_info.Capacitor(count).Time_when_switched = ...
            T_sample*(C_bank_status_info.Capacitor(count).Sample_when_switched - 1);
        C_bank_status_info.Capacitor(count).Sample_when_switched_on = ...
            find(is_C_bank_switched(:, count) == 1);
        C_bank_status_info.Capacitor(count).Sample_when_switched_off = ...
            find(is_C_bank_switched(:, count) == -1);
        C_bank_status_info.Capacitor(count).Time_when_switched_on = ...
            T_sample*(C_bank_status_info.Capacitor(count).Sample_when_switched_on - 1);
        C_bank_status_info.Capacitor(count).Time_when_switched_off = ...
            T_sample*(C_bank_status_info.Capacitor(count).Sample_when_switched_off - 1);
        C_bank_status_info.Capacitor(count).C_bank_switch_on_times = ...
            sum(is_C_bank_switched(:, count) == 1, 1);
        C_bank_status_info.Capacitor(count).C_bank_switch_off_times = ...
            sum(is_C_bank_switched(:, count) == -1, 1);
        C_bank_status_info.Capacitor(count).C_bank_switch_times = ...
            C_bank_status_info.Capacitor(count).C_bank_switch_on_times + ...
            C_bank_status_info.Capacitor(count).C_bank_switch_off_times;
        C_bank_status_info.Capacitor(count).C_bank_operating_samplespan = ...
            sum(real_time_C_bank_status(:, count));
        C_bank_status_info.Capacitor(count).C_bank_operating_timespan = ...
            T_sample*C_bank_status_info.Capacitor(count).C_bank_operating_samplespan;        
    end

    sample_of_status = [1, find(any(is_C_bank_switched, 2))'; ...
                       find(any(is_C_bank_switched, 2))', size(Q_L, 1)]';
    status_count = size(sample_of_status, 1);
    for count = 1:status_count
        C_bank_status_info.Bank(count).Status_number = count;
        C_bank_status_info.Bank(count).Sample_of_status = sample_of_status(count, :);
        C_bank_status_info.Bank(count).Samplespan_of_status = diff((sample_of_status(count, :))')';
        C_bank_status_info.Bank(count).Time_of_status = T_sample*(sample_of_status(count, :) - 1);
        C_bank_status_info.Bank(count).Timespan_of_status = T_sample*diff((sample_of_status(count, :))')';
        C_bank_status_info.Bank(count).Merged_C_bank_status = real_time_C_bank_status(sample_of_status...
                                                              (count, 1), :);
        C_bank_status_info.Bank(count).k_C_at_status = sum(C_bank_status_info.Bank(count).Merged_C_bank_status...
                                                       .*C_bank_proportion, 2);
        C_bank_status_info.Bank(count).Q_C_at_status = Q_C(sample_of_status(count, 1), :);
        C_bank_status_info.Bank(count).E_quantity_Q = (sum(abs(Q_L(sample_of_status(count, 1):sample_of_status(count, 2) - 1, ...
                                                      :) - C_bank_status_info.Bank(count).Q_C_at_status), 1))*T_sample;
    end

    if status_count > 1
        for count = 1:status_count
            switch count
                case 1
                    C_bank_status_info.Bank(count).deltaE_quantity_Q_last = [];
                    C_bank_status_info.Bank(count).deltaE_quantity_Q_next = ...
                        (C_bank_status_info.Bank(count).Q_C_at_status - ...
                        C_bank_status_info.Bank(count + 1).Q_C_at_status) ...
                        *C_bank_status_info.Bank(count).Timespan_of_status;
                    C_bank_status_info.Bank(count).is_C_bank_switched = zeros(1, size(C_bank_proportion, 2));
                    C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed = false(1, 2);
                    switch Mode
                        case 1
                            if (C_bank_status_info.Bank(count).k_C_at_status > C_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status < Q_L(C_bank_status_info.Bank(count).Sample_of_status(2)))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(2) = true;
                            end
                        case 0
    
                        case -1
                            if (C_bank_status_info.Bank(count).k_C_at_status < C_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status > Q_L(C_bank_status_info.Bank(count).Sample_of_status(2)))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(2) = true;
                            end
                        otherwise
                            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');
                    end
                case status_count
                    C_bank_status_info.Bank(count).deltaE_quantity_Q_last = ...
                        (C_bank_status_info.Bank(count).Q_C_at_status - ...
                        C_bank_status_info.Bank(count - 1).Q_C_at_status) ...
                        *C_bank_status_info.Bank(count).Timespan_of_status;
                    C_bank_status_info.Bank(count).deltaE_quantity_Q_next = [];
                    C_bank_status_info.Bank(count).is_C_bank_switched = [is_C_bank_switched(sample_of_status...
                                                                        (count, 1), :)];
                    C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed = false(1, 2);
                    switch Mode
                        case 1
                            if (C_bank_status_info.Bank(count - 1).k_C_at_status < C_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status < Q_L(C_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(1) = true;
                            end
                        case 0
    
                        case -1
                            if (C_bank_status_info.Bank(count - 1).k_C_at_status > C_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status > Q_L(C_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(1) = true;
                            end
                        otherwise
                            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');
                    end
                otherwise
                    C_bank_status_info.Bank(count).deltaE_quantity_Q_last = ...
                        (C_bank_status_info.Bank(count).Q_C_at_status - ...
                        C_bank_status_info.Bank(count - 1).Q_C_at_status) ...
                        *C_bank_status_info.Bank(count).Timespan_of_status;
                    C_bank_status_info.Bank(count).deltaE_quantity_Q_next = ...
                        (C_bank_status_info.Bank(count).Q_C_at_status - ...
                        C_bank_status_info.Bank(count + 1).Q_C_at_status) ...
                        *C_bank_status_info.Bank(count).Timespan_of_status;
                    C_bank_status_info.Bank(count).is_C_bank_switched = [is_C_bank_switched(sample_of_status...
                                                                        (count, 1), :)];
                    C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed = false(1, 2);
                    switch Mode
                        case 1
                            if (C_bank_status_info.Bank(count - 1).k_C_at_status < C_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status < Q_L(C_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(1) = true;
                            end
                            if (C_bank_status_info.Bank(count).k_C_at_status > C_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status < Q_L(C_bank_status_info.Bank(count).Sample_of_status(2)))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(2) = true;
                            end
                        case 0
    
                        case -1
                            if (C_bank_status_info.Bank(count - 1).k_C_at_status > C_bank_status_info.Bank(count).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status > Q_L(C_bank_status_info.Bank(count).Sample_of_status(1) - 1))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(1) = true;
                            end
                            if (C_bank_status_info.Bank(count).k_C_at_status < C_bank_status_info.Bank(count + 1).k_C_at_status) && ...
                                    (C_bank_status_info.Bank(count).Q_C_at_status > Q_L(C_bank_status_info.Bank(count).Sample_of_status(2)))
                                C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed(2) = true;
                            end
                        otherwise
                            error('The mode of the OPF schedule must be specified as 1, 0, or -1!');
                    end
            end
        end

    else
        C_bank_status_info.Bank(count).deltaE_quantity_Q_last = [];
        C_bank_status_info.Bank(count).deltaE_quantity_Q_next = [];
        C_bank_status_info.Bank(count).is_C_bank_switched = zeros(1, size(C_bank_proportion, 2));
        C_bank_status_info.Bank(count).is_C_bank_status_overcurtailed = false(1, 2);
    end

    schedule_info.total_E_quantity_Q.before_switching = sum(abs(Q_L), 1) * T_sample;
    schedule_info.total_E_quantity_Q.after_switching = sum([C_bank_status_info.Bank.E_quantity_Q], 2);

end