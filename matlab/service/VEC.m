classdef VEC
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function [ vecTrans status] = transVec(vec,targetType)
            vecTrans  = [];
            status = 0;
            if (strcmp(targetType,'raw'))
                if (size(vec,1)>size(vec,2))
                    vecTrans = vec.';
                else
                    vecTrans = vec;
                end

            elseif (strcmp(targetType,'column'))
                if (size(vec,1)<size(vec,2))
                    vecTrans = vec.';
                else
                    vecTrans = vec;
                end

            else
                display (sprintf('%s:%s is not a legal targetType',mfilename,targetType));
                status = 6;
                return;

            end

        end


    end
end