classdef PARSE
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function [ yesNo ] = isField(str,dataSet)
            if (isempty(dataSet))
                yesNo = 0;
                return;
            end
            if (iscell(str))
                str = cell2Str(str);
            end

            if (isstruct(dataSet) || istable(dataSet))
                if (~isempty(STR.findStringInCellArray(str,fields(dataSet))))
                    yesNo  = 1;
                else
                    yesNo  = 0;
                end
                %             elseif (isDataSet(dataSet))
                %
                %                 if (~isempty(STR.findStringInCellArray(str,fieldnames(dataSet))))
                %                     yesNo  = 1;
                %                 else
                %                     yesNo  = 0;
                %                 end

            else
                try
                    dataSet.(str);
                    yesNo  = 1;
                catch
                    yesNo  = 0;
                end
            end
        end

        function status = CheckStructFields(struct,fieldNames,struct_name,print_error_message)
            if (nargin==2)
                struct_name = 'the structure';
            else
                struct_name = sprintf('''%s''',struct_name);
            end
            if (nargin<4)
                print_error_message = 1;
            end

            status = 0;

            if (isempty(fieldNames))
                return;
            end

            fieldNames = STR.str2Cell(fieldNames);
            existDataSetFields = fields(struct);
            fieldsProb = fieldNames(find(~ismember(fieldNames,existDataSetFields)));
            % clear '' from fieldsProb;
            fieldsProb(find(ismember(fieldsProb,''))) = [];

            for i = 1:length(fieldsProb)
                status = 6;
                if (print_error_message)
                    myDisplay(sprintf('%s:%s is not a field of %s',mfilename,fieldsProb{i},struct_name));
                    myDisplay(sprintf('possible options are:'));
                    for j = 1:length(existDataSetFields)
                        myDisplay(sprintf('%s',existDataSetFields{j}));
                    end
                    displayFuncPath(dbstack);
                end
                return;
            end



        end


        %%
        function [status] = parse_parameter(paramVal,paramType,paramValList,varargin)
            if (length(varargin)>=1)
                str = varargin{1};
            else
                str =[];
            end

            if (~iscell(paramVal))
                if (isstr(paramVal))
                    paramVal = STR.str2Cell (paramVal);

                elseif (isnumeric(paramVal))
                    temp =[];
                    for (i = 1:length(paramVal))
                        temp = cat (2,temp,STR.cell2Str(num2str(paramVal(i))));
                    end
                    paramVal = temp;
                end


            end
            for (i = 1:length(paramVal))
                try
                    if (isempty(STR.findStrInCellArray(paramVal{i},paramValList)))
                        display (sprintf ('%s:''%s'' is not a legal %s. possible options are:',str,paramVal{i},paramType));
                        for j =1:length(paramValList)
                            display (sprintf ('%s',paramValList{j}));
                        end

                        status = 6;FILE.displayFuncPath(dbstack);


                        return;
                    end
                catch
                end


            end
            status = 0;
        end

        %%
        % function [lparams status] = ParseFunctionParams (function_name,defaultParams,paramsLists,inParams)
        function [lparams status] = ParseFunctionParams (function_name,paramsStruct,paramsLists,inParams,keep_structs)
            if (nargin==4)
                keep_structs = 1;
            end

            status = 0;
            lparams = [];


            % %% add [true false] paramsLists to all relevant parameters
            % for name = (fields(paramsStruct.defaultParams(:))).'
            %     name = cell2Str(name);
            %     if (islogical(paramsStruct.defaultParams.(name)))
            %         paramsStruct.paramsLists.(name) = [true false];
            %         paramsLists.(name) = [true false];
            %     end
            %
            % end

            configurationStructureNames = {'defaultParams','paramsLists','paramsType','paramsAccessLevel','paramsMetaData'};
            if (~PARSE.isField('defaultParams',paramsStruct))
                defaultParams = paramsStruct;
                paramsType = struct;
                paramsAccessLevel = struct;
                paramsMetaData = struct;
            else
                %     defaultParams = struct;
                %     paramsLists = struct;
                %     paramsType = struct;
                %     paramsAccessLevel = struct;

                for i = 1:length(configurationStructureNames)
                    if (PARSE.isField(configurationStructureNames{i},paramsStruct))
                        cmd = sprintf('%s = paramsStruct.%s;',configurationStructureNames{i},configurationStructureNames{i});
                    else
                        cmd = sprintf('%s = struct;',configurationStructureNames{i});
                    end
                    eval (cmd)
                end
            end
            if (isempty(fields(defaultParams))) && (isempty(fields(paramsLists)))
                global paramsTable;
                paramsTable = table;
                return;
            end

            if (isempty(inParams) || (isstruct(inParams) && PARSE.isField('function_name',inParams)))
                help_str_struct = inParams;
                callingStack = dbstack;

                % get the location of the 'ParseFunctionParams' function in teh stack
                for i = 1:length(callingStack)
                    if (strcmp(callingStack(i).name,'PARSE.ParseFunctionParams'))
                        ind_func = i;
                        continue;
                    end
                end

                ind_func = ind_func+1;
                function_name = STR.GetPartialDelimitedString(callingStack(ind_func).name,'nodeNum',1);
                file_name = which (callingStack(ind_func).file);

                PARSE.ShowParams (defaultParams,paramsLists,paramsType,paramsAccessLevel,paramsMetaData,function_name,file_name,help_str_struct);
                status = 1;
                return;
            else
                % structure of parameters
                if (isstruct(inParams{1}))
                    lparams = inParams{1};
                    % if the input is {[]} this means that the user desires to use the default values only
                elseif (isempty(inParams{1}))
                    lparams = defaultParams;
                else
                    % parameters list get default params
                    %         lparams = params.defaultParams.(mfilename);
                    %         fieldNames = fields(lparams);

                    % decode and check the parameters list
                    [decodeParamStruct status] = PARSE.DecodeParamListStr (inParams,function_name,defaultParams,keep_structs);if (status) return;end;
                    lparams = STRUCT.mergeStruct (defaultParams,decodeParamStruct);
                end



            end
            [lparams status ] = PARSE.ParseParamsList (lparams,paramsLists,defaultParams,function_name,keep_structs);if (status) return; end


        end








        function [ status ] = PARSE.parse_parameter(paramVal,paramType,paramValList,varargin)
            if (length(varargin)>=1)
                str = varargin{1};
            else
                str =[];
            end

            if (~iscell(paramVal))
                if (isstr(paramVal))
                    paramVal = STR.str2Cell (paramVal);

                elseif (isnumeric(paramVal))
                    temp =[];
                    for (i = 1:length(paramVal))
                        temp = cat (2,temp,STR.cell2Str(num2str(paramVal(i))));
                    end
                    paramVal = temp;
                end


            end
            for (i = 1:length(paramVal))
                try
                    if (isempty(findStrInCellArray(paramVal{i},paramValList)))
                        display (sprintf ('%s:%s is not a legal %s. possible options are:',str,paramVal{i},paramType));
                        for j =1:length(paramValList)
                            display (sprintf ('%s',paramValList{j}));
                        end

                        status = 6;FILE.displayFuncPath(dbstack);


                        return;
                    end
                catch
                end


            end
            status = 0;
        end


        function paramsTable = addRemarks(paramsTable,function_name,file_name)

            % open the fuction source file
            fid = fopen ([file_name]);
            j = 1;
            paramsTable.parameterDescription = repmat({''},height(paramsTable),1);
            paramsTable.parameterOptionsDescription = repmat({''},height(paramsTable),1);


            % go over the lines of the file
            while feof(fid) == 0
                % increment line counter
                j=j+1;
                tline = fgetl(fid);



                %% handle the remarks following the default vals
                % look for lines with the word 'defaultParams'
                if (strfind(tline,'defaultParams'))
                    tlineNoSpace = strrep(tline,' ','');
                    indStart = strfind(tlineNoSpace,'defaultParams')+length('defaultParams')+1;

                    indEnd = strfind(tlineNoSpace,'=')-1;
                    paramName = STR.str2Cell(tlineNoSpace(indStart:indEnd));
                    ind = find(ismember(paramsTable.name,paramName));
                    % see if there is an assosiated remark to this parameter
                    if (strfind(tline,'%'))
                        indStart = strfind(tline,'%')+1;
                        % refer to indStart(1) in case there are a few %'s
                        if (isspace(tline(indStart(1))))
                            indStart(1) = indStart(1)+1;
                        end
                        indEnd = length(tline);
                        remark = STR.str2Cell(tline(indStart(1):indEnd));
                        paramsTable.parameterDescription(ind) = remark;
                    end
                end


                if (strfind(tline,'paramsLists'))
                    tlineNoSpace = strrep(tline,' ','');
                    indStart = strfind(tline,'paramsLists')+length('paramsLists')+1;

                    indEnd = strfind(tlineNoSpace,'=')-1;
                    paramName = STR.str2Cell(tline(indStart:indEnd));
                    ind = find(ismember(paramsTable.name,paramName));
                    % see if there is an assosiated remark to this parameter
                    if (strfind(tline,'%'))
                        indStart = strfind(tline,'%')+1;
                        % refer to indStart(1) in case there are a few %'s
                        if (isspace(tline(indStart(1))))
                            indStart(1) = indStart(1)+1;
                        end
                        indEnd = length(tline);
                        remark = STR.str2Cell(tline(indStart(1):indEnd));
                        paramsTable.parameterOptionsDescription(ind) = remark;
                    end
                end

            end

            % % put the parameterDescrip column next to the name column
            % temp = paramsTable(:,2);
            % paramsTable(:,2) = paramsTable(:,4);
            % paramsTable(:,4) = temp;
            % paramsTable.Properties.VariableNames;
            % temp2 = paramsTable.Properties.VariableNames(2);
            % temp4 = paramsTable.Properties.VariableNames(4);
            % paramsTable.Properties.VariableNames(2) = {'kuku1'};
            % paramsTable.Properties.VariableNames(4) = {'kuku2'};
            % paramsTable.Properties.VariableNames(2) = temp4;
            % paramsTable.Properties.VariableNames(4) = temp2;
        end

        function paramsTable = ShowParams (defaultParams,paramsLists,paramsType,paramsAccessLevel,paramsMetaData,function_name,file_name,help_str_struct)
            if (nargin==6)
                help_str_struct = struct;
            end
            global paramsTable;
            global showParamsTable;
            paramNames = fieldnames(defaultParams);
            paramsTable = table;




            for i = 1:length(paramNames)
                line = table;
                line.name = paramNames(i);
                if (isnumeric(defaultParams.(paramNames{i})))
                    line.defaultValue = STR.str2Cell(num2str (defaultParams.(paramNames{i})));
                elseif (isstr(defaultParams.(paramNames{i})))
                    line.defaultValue{1} = defaultParams.(paramNames{i});
                elseif (iscellstr(defaultParams.(paramNames{i})))
                    str =[];
                    for j = 1:length(defaultParams.(paramNames{i}))
                        str = [str '''' defaultParams.(paramNames{i}){j} '''' ','];
                    end
                    str(end) = [];
                    line.defaultValue{1} = str;
                else
                    temp = defaultParams.(paramNames{i});
                    if (iscell(temp)) && iscell(temp{1})
                        line.defaultValue = {''};
                    else
                        line.defaultValue = defaultParams.(paramNames{i});

                    end
                end


                if (PARSE.isField(paramNames{i},paramsLists))
                    str = [];

                    for j  = 1:length(paramsLists.(paramNames{i}))
                        if (iscell(paramsLists.(paramNames{i})(j)))
                            str = [str '''' (paramsLists.(paramNames{i}){j}) '''' ','];
                        elseif (isnumeric(paramsLists.(paramNames{i})(j)))
                            str = [str num2str(paramsLists.(paramNames{i})(j))  ','];
                        end
                    end
                    str(end) = [];
                    line.options = STR.str2Cell(str);
                else
                    line.options = {[]};
                end

                % refer to params.type
                if (isempty(fields(paramsType)))
                    line.type = {''};
                else
                    if (PARSE.isField(paramNames{i},paramsType))
                        line.type = STR.str2Cell(paramsType.(paramNames{i}));
                    else
                        line.type = {''};
                    end
                end
                % refer to params.accessLevel

                % if the user did not set paramsAccessLevel, set highest accessability to
                % all parameters. Otherwise set accessability level 2 as a default
                if (isempty(fields(paramsAccessLevel)))
                    line.accessLevel = 1;
                else
                    if (PARSE.isField(paramNames{i},paramsAccessLevel))
                        line.accessLevel = paramsAccessLevel.(paramNames{i});
                    else
                        line.accessLevel = 2;
                    end
                end


                % refer to params.paramsMetaData


                if (isempty(fields(paramsMetaData)))
                    line.paramsMetaData{1} = struct;
                else
                    if (PARSE.isField(paramNames{i},paramsMetaData))
                        line.paramsMetaData = paramsMetaData.(paramNames{i});
                    else
                        line.paramsMetaData{1} = struct;
                    end
                end

                paramsTable = cat (1,paramsTable,line);
            end


            show_mode = 'simple';
            if (~strcmp(show_mode,'parsing_table'))
                paramsTable
            else

                % add the remarks
                paramsTable = addRemarks(paramsTable,function_name,file_name);




                % setappdata(0,'evalue',paramsTable);
                if (isempty(showParamsTable)) || (showParamsTable==1)
                    %% header
                    display(sprintf('\n'))
                    display(repmat('-',1,length(function_name)+16));
                    display(sprintf('%s%s',repmat(' ',1,8),function_name));
                    display(repmat('-',1,length(function_name)+16));


                    %% function description
                    function_description = get_function_description(file_name,function_name);


                    display(sprintf('\n'));

                    %% input params
                    if (PARSE.isField('input_description',help_str_struct))
                        display(sprintf(' inputs:'))
                        display(repmat('-',1,length('inputs:')+4));
                        str = STR.str2Cell(help_str_struct.input_description);
                        for i = 1:length(str)
                            if (~isempty(str{i}))
                                display(sprintf('\t%d. %s',i,str{i}));
                            end
                        end
                        display(sprintf('\n'));

                    end


                    %% output params
                    if (PARSE.isField('output_description',help_str_struct))
                        display(sprintf('  outputs:'))
                        display(repmat('-',1,length('outputs:')+4));

                        str = STR.str2Cell(help_str_struct.output_description);
                        for i = 1:length(str)
                            display(sprintf('\t%d. %s',i,str{i}));
                        end
                        display(sprintf('\n'));

                    end

                    %% name-value / struct params
                    display(sprintf('  parameters:'))
                    display(repmat('-',1,length('parameters:')+4));

                    %     display(sprintf('\n'));
                    %     disp(paramsTable);




                    display_parsing_table(paramsTable,{'name','parameterDescription','defaultValue','options','parameterOptionsDescription'},{'name','parameterDescription','defaultValue','options','parameterOptionsDescription'});
                end
            end
        end


        function [structOut status] = DecodeParamListStr (inParams,function_name,defaultParams,keep_struct)
            if (nargin==3)
                keep_struct
            end
            paramsOptions = fieldnames(defaultParams);
            structOut =[];
            status= 0;
            if (mod(length(inParams),2)~= 0)
                display(sprintf('%s: length of params list is not even for ''%s''',mfilename,function_name));
                status = 6;FILE.displayFuncPath(dbstack);
                return;
            end

            for i = 1:length(inParams)/2
                paramName = inParams{2*i-1};
                if (~isempty(paramsOptions)) && (~ismember(paramName,paramsOptions))
                    display(sprintf('%s: ''%s'' is not a legal param for ''%s''.Optional Parameters are:',mfilename,paramName,function_name));
                    for j = 1:length(paramsOptions)
                        display(sprintf('%s',paramsOptions{j}));
                    end

                    status = 6;displayFuncPath(dbstack);
                    return;
                end
                paramVal =  inParams{2*i};




                structOut.(paramName) = paramVal;




            end



        end
        %%
        function [ paramsParsed status ] = ParseParamsList (lparams,paramsLists,defaultParams,function_name,keep_struct)
            if (nargin==4)
                keep_struct
            end

            % if (length(varargin)>=1)
            %     str = varargin{1};
            % else
            %     str =[];
            % end

            paramNameList = fieldnames (defaultParams);

            for i = 1:length(paramNameList)
                % if the checked field does not exist in the checked list
                if (~isfield(lparams,paramNameList{i}))
                    % set the default value
                    paramsParsed.(paramNameList{i}) = defaultParams.(paramNameList{i});


                    % if the checked field exists in the checked list
                else
                    % if there is a list of possible values for this parameter check the actual value
                    listNames = fieldnames(paramsLists);
                    if ~(isempty(STR.findStrInCellArray (paramNameList{i},listNames)))
                        %if the check failed declare failure
                        if (PARSE.parse_parameter(lparams.(paramNameList{i}),paramNameList{i},paramsLists.(paramNameList{i}),function_name))
                            paramsParsed = [];
                            status = 6;
                            FILE.displayFuncPath(dbstack);

                            return;


                        else
                            % if the check passed set the parameter
                            % if it's not a cell array convert it
                            %                 if (isstr(params.(paramNameList{i})))
                            %                     paramsParsed.(paramNameList{i}) = STR.str2Cell(params.(paramNameList{i}));
                            %                 else

                            paramsParsed.(paramNameList{i}) = lparams.(paramNameList{i});
                            %                 end
                        end

                        %if there is no list for this param set the parameter
                    else
                        paramsParsed.(paramNameList{i}) = lparams.(paramNameList{i});
                    end

                end

            end

            if (keep_struct)
                field_names = fields(lparams);
                for i = 1:length(field_names)
                    if (isstruct(lparams.(field_names{i})))
                        paramsParsed.(field_names{i}) = lparams.(field_names{i});
                    end
                end
            end

            status = 0;


        end

        %%
        function FILE.displayFuncPath(funcPath)
            global strG;
            temp = strG;
            for i = 1:length(funcPath)
                display(sprintf('error in %s (line %d)',funcPath(i).name,funcPath(i).line));
            end
            strG = temp;
        end


        %%
        function [ status ] = ParseParamter(paramVal,paramType,paramValList,varargin)
            if (length(varargin)>=1)
                str = varargin{1};
            else
                str =[];
            end

            if (isstr(paramValList))
                paramValList = STR.str2Cell(paramValList)';
            end

            if (~iscell(paramVal))
                if (isstr(paramVal))
                    paramVal = STR.str2Cell (paramVal);

                elseif (isnumeric(paramVal))
                    temp =[];
                    for (i = 1:length(paramVal))
                        temp = cat (2,temp,cellstr(num2str(paramVal(i))));
                    end
                    paramVal = temp;
                end
            end

            if (~iscell(paramValList))
                if (isstr(paramVal))
                    paramValList = STR.str2Cell (paramValList);

                elseif (isnumeric(paramValList))
                    paramValList = num2StrCellArray(paramValList);
                end
            end


            for (i = 1:length(paramVal))
                try
                    if (isempty(findStrInCellArray(paramVal{i},paramValList)))
                        myDisplay (sprintf ('%s:''%s'' is not a legal %s. possible options are:',str,paramVal{i},paramType));
                        for j =1:length(paramValList)
                            myDisplay (sprintf ('''%s''',paramValList{j}));
                        end

                        status = 6;displayFuncPath(dbstack);


                        return;
                    end
                catch
                    %         myDisplay(sprintf()ch)

                end


            end
            status = 0;
        end

        %%
        function status = CheckEmptiness (in,paramsList)
            status = 0;

            if (~isstruct(in)) && (~isobject(in))
                if (nargin==1)
                    paramsList = 'var';
                end
                lparams.(paramsList) = in;
            else
                lparams = in;
            end

            paramsList = STR.str2Cell (paramsList);
            for i = 1 :length(paramsList)
                if (isempty(lparams.(paramsList{i})))
                    myDisplay(sprintf('%s:''%s'' is empty',mfilename,paramsList{i}));
                    displayFuncPath(dbstack)
                    status = 6;
                    return;
                end
            end
        end


        %%
        function [ paramsPermut ] = creatParamPermutationStruct(lparams)

            paramsPermut = table;
            if (isempty(lparams))
                return;
            else
                %get the length of each parameter list and init the paramsPermut struct
                fieldNames = fieldnames(lparams);
                if (isempty(fieldNames))
                    return;

                end
                for i = 1:length (fieldNames)
                    if (isempty(lparams.(fieldNames{i})))
                        mark(i) = 1;
                    else
                        mark(i) = 0;
                    end
                end



                cmd = 'paramsPermutBlock = table(';
                for i = 1:length (fieldNames)
                    %     paramsPermutBlock{1}.(fieldNames{i}) = lparams.(fieldNames{i}){1};
                    if (iscell(lparams.(fieldNames{i})))
                        line{1,i} = lparams.(fieldNames{i}){1};
                        paramlistLen (i) = length (lparams.(fieldNames{i}));

                    elseif (isstr(lparams.(fieldNames{i})))
                        line(1,i) = str2Cell(lparams.(fieldNames{i}));
                        paramlistLen (i) = 1;

                    elseif (isempty(lparams.(fieldNames{i})))
                        continue;
                    else
                        paramlistLen (i) = length (lparams.(fieldNames{i}));

                        line{1,i} = (lparams.(fieldNames{i})(1));
                    end
                    cmd = [cmd sprintf('{line{1,%d}},',i)];
                end
                cmd  = [cmd '''variableNames'',fieldNames);'];
                eval (cmd);

                % paramsPermutBlock = dataset({line{1,1}},{line{1,2}},{line{1,3}},'varnames',fieldNames);

                paramsPermut = [];
                numPermut = 1;
                % run over all the lparams
                for i = 1:length (fieldNames)
                    % run on all the choices of the current param
                    if (i ==1)
                        jStart = 1;
                    else
                        jStart = 2;
                    end
                    for j = jStart:paramlistLen(i)
                        %run on all the previous defined permutations
                        for k = 1:height(paramsPermutBlock)
                            if (iscell(lparams.(fieldNames{i})))
                                paramsPermutBlock.(fieldNames{i})(k) = {(lparams.(fieldNames{i}){j})};
                            elseif (isstr(lparams.(fieldNames{i})))
                                paramsPermutBlock.(fieldNames{i})(k) = {(lparams.(fieldNames{i}))};
                            else
                                paramsPermutBlock.(fieldNames{i})(k) = {(lparams.(fieldNames{i})(j))};
                            end
                        end
                        % add the current permutation to the block (if empty init the block
                        % with the permutation)
                        if (isempty(paramsPermut))
                            paramsPermut = paramsPermutBlock;
                        else
                            paramsPermut = [paramsPermut;paramsPermutBlock];
                        end
                    end
                    %the block for the next paramter should be all the permutations
                    %gathered so far
                    paramsPermutBlock = paramsPermut;
                end

                index = 1:height (paramsPermut);index = index';
                paramsPermut = cat (2,table(index),paramsPermut);

            end

            field_names = paramsPermut.Properties.VariableNames;
            for i = 1:length(field_names)
                if (iscell(paramsPermut.(field_names{i})(1))) && (~isstr(paramsPermut.(field_names{i}){1}))
                    try
                        column = cell2Mat(paramsPermut.(field_names{i}));
                        %             if (column)
                        try
                            paramsPermut.(field_names{i}) = column;
                        catch
                            k = 1;
                        end

                        %             end
                    catch
                        k = 1;
                    end
                end

            end
        end

    end
end