function [k_C, Q_C] = extension_of_switch_timespan(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
                                                   Min_switch_timespan, C_bank_status_info, Mode)
    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 0;
    end

    [k_C, Q_C] = curtailment_of_overswitches(T_sample, Q_L, C_bank_proportion, k_C, Q_C, ...
                                             Min_switch_timespan, C_bank_status_info, Mode);
    switch round(Mode/abs(Mode + eps))
        case 1

        case 0
            
        case -1

    end

end