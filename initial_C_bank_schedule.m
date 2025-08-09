function [k_C, Q_C, Q_proportion_plot] = initial_C_bank_schedule(Q_L, Cap, C_bank_proportion, Mode)
    
    if ~exist('Mode', 'var') || isempty(Mode)
        Mode = 1;
    end
    
    k_L = Q_L/Cap*sum(C_bank_proportion);
    C_bank_taps = zeros(1, 2^size(C_bank_proportion, 2));
    number = 0;
    for count = 1:size(C_bank_proportion, 2)
        C_bank_taps(number + 2: number + nchoosek(size(C_bank_proportion, 2), count) + 1) = ...
                    sum(nchoosek(C_bank_proportion, count), 2)';
        number = number + nchoosek(size(C_bank_proportion, 2), count) + 1;
    end
    C_bank_taps = unique(sort(C_bank_taps, 'ascend'));
    k_C = zeros(size(Q_L, 1), size(Q_L, 2));
    for count = 1:size(C_bank_taps, 2)
        switch round(Mode/abs(Mode + eps))
            case 1
                if C_bank_taps(count) < sum(C_bank_proportion)
                    k_C = k_C + C_bank_taps(count) * ((k_L >= C_bank_taps(count)) & ...
                        (k_L < C_bank_taps(count + 1)));
                else
                    k_C = k_C + C_bank_taps(count) * (k_L >= C_bank_taps(count));
                end
            case 0
                if count == 1
                    k_C = k_C + C_bank_taps(count) * ((k_L >= C_bank_taps(count)/2) & ...
                        (k_L < (C_bank_taps(count) + C_bank_taps(count + 1))/2));
                elseif C_bank_taps(count) < sum(C_bank_proportion)
                    k_C = k_C + C_bank_taps(count) * ((k_L >= (C_bank_taps(count - 1) + ...
                        C_bank_taps(count))/2) & (k_L < (C_bank_taps(count) + ...
                        C_bank_taps(count + 1))/2));
                else
                    k_C = k_C + C_bank_taps(count) * (k_L >= (C_bank_taps(count - 1) + ...
                        C_bank_taps(count))/2);
                end
            case -1
                if C_bank_taps(count) < sum(C_bank_proportion)
                    k_C = k_C + C_bank_taps(count + 1) * ((k_L >= C_bank_taps(count)) & ...
                        (k_L < C_bank_taps(count + 1)));
                else
                    k_C = k_C + C_bank_taps(count) * (k_L >= C_bank_taps(count));
                end
            otherwise
                error('The mode of the OPF schedule must be specified as a numerical scalar!');
        end
    end
    k_C = (k_L ~= 0) .* k_C;
    Q_C = k_C*Cap/sum(C_bank_proportion);
    Q_proportion_plot = ones(size(Q_L, 1), size(Q_L, 2))*C_bank_taps*Cap/sum(C_bank_proportion);
    
end