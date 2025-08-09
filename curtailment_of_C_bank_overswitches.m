function [k_C, Q_C] = curtailment_of_C_bank_overswitches(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
                                                         Max_switch_times, schedule_info, C_bank_status_info, ...
                                                         Mode)
    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end
    
    C_bank_switch_times = [C_bank_status_info.Capacitor.C_bank_switch_times];
    real_time_C_bank_status_before_curtailment = [schedule_info.real_time_status.real_time_C_bank_status];

    while any(C_bank_switch_times > Max_switch_times)
        [k_C, Q_C] = curtailment_execution_of_C_bank_overswitches(T_sample, Q_L, C_bank_proportion, ...
                                                                  k_C, Q_C, Max_switch_times, ...
                                                                  C_bank_status_info, Mode);
        [schedule_info, C_bank_status_info] = schedule_and_C_bank_status_info(T_sample, Q_L, ...
                                                                              C_bank_proportion, ...
                                                                              k_C, Q_C);
        C_bank_switch_times = [C_bank_status_info.Capacitor.C_bank_switch_times];
        real_time_C_bank_status_after_curtailment = [schedule_info.real_time_status.real_time_C_bank_status];
        if all(all(real_time_C_bank_status_before_curtailment == real_time_C_bank_status_after_curtailment))
            break;
        end
        real_time_C_bank_status_before_curtailment = real_time_C_bank_status_after_curtailment;
    end


end