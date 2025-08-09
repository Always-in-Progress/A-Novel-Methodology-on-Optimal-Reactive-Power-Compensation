function [k_C, Q_C] = final_C_bank_schedule(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
                                            Max_switch_times, C_bank_status_info, Mode)
    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end

    [k_C, Q_C] = curtailment_of_overswitches(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
                                             Max_switch_times, C_bank_status_info, Mode);
    [k_C, Q_C] = extension_of_switch_timespan(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
                                              Max_switch_times, C_bank_status_info, Mode);

end