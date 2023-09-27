classdef STRUCT
    %STRUCT Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function [s3 status] = mergeStruct(s1,s2,varargin)

            if (istable(s1))
                s1 = table2struct(s1);
            end

            if (istable(s2))
                s2 = table2struct(s2);
            end


            s3 = [];



            if (nargin==2)
                mode = 'all_fields';
            else
                mode = varargin{1};
            end


            status = PARSE.ParseParamter (mode,'mode',{'all_fields','common_fields','custom_fields','custom_fields_not'});if (status) return;end


            %             s3 = s1;

            if (isempty(s1))
                s3 = s2;
                return;
            end

            if (isempty(s2))
                s3 = s1;
                return;
            end

            s3 = s1;


            switch mode
                case 'all_fields'
                    fieldNames = fieldnames (s2);
                case 'common_fields'
                    fieldNames = intersect (fieldnames (s2),fieldnames (s1));
                case 'custom_fields'
                    fieldNames = varargin{2};
                case 'custom_fields_not'
                    fieldNames1 = fieldnames (s1);

                    if (~isempty(varargin{2}))
                        fieldNames1(find(ismember(fieldNames1,varargin{2}))) = [];
                    end
                    s3 = STRUCT.GetPartialStruct(s1,fieldNames1);
                    fieldNames = fieldnames(s2);
            end


            for (i = 1:length(fieldNames))
                if (isstruct(s2.(fieldNames{i})))
                    if (~isField(fieldNames{i},s1))
                        s3.(fieldNames{i}) = s2.(fieldNames{i});
                    else
                        s3.(fieldNames{i}) = mergeStruct(s1.(fieldNames{i}),s2.(fieldNames{i}));
                    end
                else
                    s3.(fieldNames{i}) = s2.(fieldNames{i});
                end
            end

        end

        %%
        function struct_field_names = get_struct_field_names(s)
            struct_field_names = [];
            for field = (fields(s)).'
                if (isstruct(s.(STR.cell2Str(field))))
                    struct_field_names = cat(2,struct_field_names,field);
                end
            end
        end


        %%
        function [ partialStruct status] = GetPartialStruct (dataSet,fields,varargin)
            %status = 6;displayFuncPath(dbstack); return;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;


            defaultParams.mode = 'return_on_none_existing';
            defaultParams.struct_name = 'struct';
            paramsLists.mode = {'return_on_none_existing','get_existing'};


            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            if (nargin==2)
                lparams = defaultParams;
            else
                %% parase parameters
                % [lparams status] = ParseFunctionParams (mfilename,defaultParams,paramsLists,varargin);if (status) return;end
                [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            end
            % create_lparams_vars;


            status = 0;
            fields = STR.str2Cell(fields);
            partialStruct = struct;
            for (i=1:length(fields))
                if (isField (fields{i},dataSet))
                    partialStruct.(fields{i}) = dataSet.(fields{i});
                else
                    switch lparams.mode
                        case 'return_on_none_existing'
                            myDisplay (sprintf('%s: %s is not a field in %s',mfilename,fields{i},lparams.struct_name));
                            status = 6;displayFuncPath(dbstack);
                        case 'get_existing'
                            continue;
                    end
                end


            end
        end

%%
function status = check_struct(s,field_names,varargin)
%status = 6;displayFuncPath(dbstack); return;
st = dbstack;funcname = st.name;



%% set params default vals and legal options
paramsLists = struct;
defaultParams = struct;


defaultParams.mode = {'exist'};
paramsLists.mode = {'exist','empty','integer','div'};

defaultParams.val = [];
defaultParams.val_name = [];
defaultParams.dim = [];

paramsStruct.paramsLists = paramsLists;
paramsStruct.defaultParams = defaultParams;

%% parase parameters
[lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
create_lparams_vars;

%% function body


mode = STR.str2Cell(lparams.mode);
mode = (mode(:))';
if (~ismember('exist',mode))
    mode = cat(2,mode,'exist');
end

field_names = STR.str2Cell(field_names);

for i = 1:length(mode)
    switch mode{i}
        case 'exist'
            status = PARSE.CheckStructFields(s,field_names);if (status) return;end
            
        case 'empty'
            status = CheckEmptiness(s,field_names);if (status) return;end
            
        case 'integer'
            for name = field_names(:).'
                name = STR.cell2Str(name);
                
                if (isempty(lparams.dim))
                    dim = 1:length(s.(name));
                end
                
                for i = dim
                    if (max(dim)>1)
                        name_str = [name '(' num2str(i) ')'];
                    else
                        name_str = name;
                    end
                    status = check_integer(s.(name)(i),name_str);if (status) return;end
                end
            end
            
        case 'div'
            status = CheckEmptiness(lparams,{'val'});if (status) return;end
            for name = field_names(:).'
                name = STR.cell2Str(name);
                
                
                if (isempty(lparams.dim))
                    dim = 1:length(s.(name));
                end
                
                
                for i = dim
                    if (max(dim)>1)
                        name_str = [name '(' num2str(i) ')'];
                    else
                        name_str = name;
                    end
                    
                    if (i>length(s.(name)))
                        myDisplay(sprintf('%s: ''%s'' does not have a dimention %d',mfilename,name,i))
                        status = 6;displayFuncPath(dbstack); return;
                    end
                    
                    status = check_div(s.(name)(i),val,name_str,val_name);if (status) return;end
                end
                
            end
            
            
            
    end
    
end





end        
    end
end