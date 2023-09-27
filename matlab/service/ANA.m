classdef ANA
    %ANA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods (Static)
        function [start_ind corr_val] = find_pattern_in_signal(pattern,sig)
            sig = sig/max(abs(sig));
            pattern = [pattern/(max(abs(pattern)))];
            [corr_val loc] = xcorr(sig,pattern);
            corr_val = corr_val/length(pattern)
            [~,ind]=max(abs(corr_val));
            start_ind = loc(ind)+1;
        end
    end
end

