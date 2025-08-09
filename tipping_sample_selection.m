function [tipping_sample, delta_E_equatity_Q] = tipping_sample_selection(T_sample, Q_L, C_bank_status_info)
    
    C_bank_status_count = size(C_bank_status_info.Bank, 2);
    tipping_sample = zeros(C_bank_status_count, 1);
    tipping_sample(1) = 1;
    tipping_sample(end) = size(Q_L, 1);
    delta_E_equatity_Q = zeros(C_bank_status_count, 1);

    for status_count = 2:C_bank_status_count - 1
        start_sample = C_bank_status_info.Bank(status_count).Sample_of_status(1);
        terminal_sample = C_bank_status_info.Bank(status_count).Sample_of_status(2);
        Q_C_in_the_neighbour = [C_bank_status_info.Bank(status_count - 1).Q_C_at_status, ...
                                C_bank_status_info.Bank(status_count + 1).Q_C_at_status];
        extreme_samples = find((Q_L(1:end-1) - mean(Q_C_in_the_neighbour)).*(Q_L(2:end) - mean(Q_C_in_the_neighbour)) <= 0) + 1;
        extreme_samples = extreme_samples((extreme_samples > C_bank_status_info.Bank(status_count).Sample_of_status(1)) & ...
                                          (extreme_samples < C_bank_status_info.Bank(status_count).Sample_of_status(2) - 1));
        candidate_samples = [start_sample; extreme_samples; terminal_sample - 1];
        E_quantity_Q = zeros(size(candidate_samples, 1), 1);

        for sample_count = 1:size(candidate_samples, 1)
            Q_C_curtailed(start_sample:candidate_samples(sample_count) - 1, :) = Q_C_in_the_neighbour(1);
            Q_C_curtailed(candidate_samples(sample_count):terminal_sample - 1, :) = Q_C_in_the_neighbour(2);
            E_quantity_Q(sample_count, 1) = sum(abs(Q_L(start_sample:terminal_sample - 1, :) - ...
                                            Q_C_curtailed(start_sample:terminal_sample - 1, :)))*T_sample;
        end
        
        delta_E_equatity_Q(status_count) = min(E_quantity_Q);
        tmp = candidate_samples(E_quantity_Q == delta_E_equatity_Q(status_count), 1);
        tipping_sample(status_count) = tmp(randi(length(tmp)));
    end
    
    start_sample = C_bank_status_info.Bank(1).Sample_of_status(1);
    terminal_sample = C_bank_status_info.Bank(1).Sample_of_status(2);
    Q_C_curtailed(start_sample:terminal_sample - 1, :) = C_bank_status_info.Bank(2).Q_C_at_status;
    delta_E_equatity_Q(1) = sum(abs(Q_L(start_sample:terminal_sample - 1, :) - ...
                            Q_C_curtailed(start_sample:terminal_sample - 1, :)))*T_sample;

    start_sample = C_bank_status_info.Bank(C_bank_status_count).Sample_of_status(1);
    terminal_sample = C_bank_status_info.Bank(C_bank_status_count).Sample_of_status(2);
    Q_C_curtailed(start_sample:terminal_sample - 1, :) = C_bank_status_info.Bank(C_bank_status_count - 1)...
                                                         .Q_C_at_status;
    delta_E_equatity_Q(C_bank_status_count) = sum(abs(Q_L(start_sample:terminal_sample - 1, :) - ...
                                              Q_C_curtailed(start_sample:terminal_sample - 1, :)))*T_sample;
end