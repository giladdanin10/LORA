classdef STR
    %STR Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)

        function [partialStr status] = GetPartialDelimitedString(str,varargin)

            partialStr =[];
            %status = 6;displayFuncPath(dbstack); return;

            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;
            defaultParams.nodeNum = [];    % pathNode/'s
            defaultParams.delimiter = '.';  % delimiter
            defaultParams.outputDelimiter = [];  % in some cases we whish to decode numerous delimiters but output a single one (e.g //,\\,\./ --> \)
            defaultParams.mode = 'countFromEnd';    % mode of opeartion
            defaultParams.logic = 'positive';   % whether to take the specified nodes ('positive') or all but them ('negative')

            paramsLists.mode = {...
                'countFromEnd',...
                'countFromStart'...
                };

            paramsLists.logic = {...
                'positive',...  % take the specified nodes
                'negative'... % take all but the specified nodes
                };


            %% parase parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,defaultParams,paramsLists,varargin);if (status) return;end
            if (isempty(lparams))
                return;
            end

            str_vec = STR.str2Cell(str);

            partialStr_vec =[];
            for str = (str_vec(:))'
                str = STR.cell2Str(str);
                nodeNum = lparams.nodeNum;


                delimiter = STR.str2Cell(lparams.delimiter);

                if (isempty(lparams.outputDelimiter))
                    outputDelimiter = delimiter;
                else
                    outputDelimiter = lparams.outputDelimiter;
                end

                if (length(outputDelimiter) > 1)
                    myDisplay(sprintf('%s: length of outputDelimiter should be 1',mfilename));
                    status = 6;displayFuncPath(dbstack); return;

                end
                % get nodes
                nodes = strsplit(str,delimiter);

                % remove empty nodes (could happen if the end of the string equlas one of the delimiters)
                nodes(find(ismember(nodes,{''}))) = [];


                % decode the mode
                switch (lparams.mode)
                    case 'countFromEnd'
                        nodeNum = length(nodes)-lparams.nodeNum+1;
                    case 'countFromStart'
                        nodeNum = lparams.nodeNum;
                end

                switch lparams.logic
                    case 'positive'
                        nodeNum = nodeNum;
                    case 'negative'
                        nodeNum = find(~ismember([1:length(nodes)],nodeNum));
                end

                % construct the partialStr
                nodeNum = sort(nodeNum);

                if (max(nodeNum)>length(nodes))
                    myDisplay(sprintf('%s: max nodeNum (%d) exceeds length of nodes (%d)',mfilename,max(nodeNum),length(nodes)));
                    status = 6;displayFuncPath(dbstack); return;
                end

                partialStr = '';
                for i = 1:length(nodeNum)
                    if (i==1)
                        partialStr = nodes{nodeNum(i)};
                    else
                        partialStr = [partialStr STR.cell2Str(outputDelimiter) nodes{nodeNum(i)}];
                    end
                end

                partialStr_vec = cat(1,partialStr_vec,STR.str2Cell(partialStr));
            end

            if (length(partialStr_vec)==1)
                partialStr = partialStr_vec{1};
            else
                partialStr = partialStr_vec;
            end
        end
        %%

        function [ ind] = findStringInCellArray( string,cellArray,varargin)
            ind = find(ismember(cellArray,string));
            %             if (nargin==3)
            %                 excactMatch = varargin {1};
            %             else
            %                 excactMatch = 1;
            %             end
            %
            %             if (isempty(cellArray))
            %                 ind = [];
            %                 return;
            %             end
            %
            %             if (isempty(string))
            %                 ind =[];
            %                 for i = 1:length(cellArray)
            %                     if (isempty(cellArray{i}))
            %                         ind = [ind;i];
            %                     end
            %                 end
            %                 return;
            %             else
            %
            %                 try
            %                     vec = strfind(cellArray,STR.str2Cell(string));
            %                 catch
            %                     display(sprintf('%s: could dot perform strfind command',mfilename));
            %                     status = 6;FILE.displayFuncPath(dbstack); return;
            %                 end
            %                 myIsEmptyH = @(index)myIsEmpty(vec,index);
            %                 vec1 = arrayfun(myIsEmptyH,1:length(vec), 'UniformOutput', false);
            %                 ind = find (~cell2mat(vec1));
            %
            %                 if (excactMatch)
            %                     % the above process fiters in also cellArray nodes that conatins the string and not necessarily
            %                     % match it exactly. The following lines exclude these cases
            %                     stat  = ones (length(ind),1);
            %                     for i = 1:length(ind)
            %                         if ~strcmp(cellArray{ind(i)},string)
            %                             stat(i) = 0;
            %                         end
            %                     end
            %
            %                     ind (find (stat==0))=[];
            %                 end
            %
            %             end
        end

        %%
        function ind = myIsEmpty(vec,index)
            ind  =  isempty (vec{index});

        end

        %%
        function cell = str2Cell(str)
            if (isstr(str))
                cell{1} = str;
            else
                cell = str;
            end

        end


        %%
        function str = cell2Str(cell)
            if (isempty(cell))
                str = [];
            elseif (isstr(cell))
                str = cell;
            elseif (isnumeric(cell))
                str = num2str(cell);
            else

                str = cell{1};

                if (isnumeric(str)) || (islogical(str))
                    str = num2str(str);
                end


            end
        end


        %%
        function [chars locs] = get_numerical_chars_from_string(str)
            chars = [];
            locs = [];
            for i = 1:length(str)
                if (~isempty(str2num(str(i))))
                    chars = cat(2,chars,str(i));
                    locs = cat(2,locs,i);
                end
            end
        end


        %%
        %addStrToCellArray adds a string to each node of a cell array of strings
        %inputs -
        %   str - string to be added
        %   cellArray - cell array of strings
        %   place - place of the string incertion site (could be 'begin','end' or
        %   number greater than 2 and smaller than the minimum string length of the cell array
        function cellArrayMod = addStrToCellArray (str,cellArray,place)
            if (isempty(cellArray))
                cellArrayMod = [];
                return;
            end

            cellArray = STR.str2Cell(cellArray);


            if (isnumeric(place))
                if (place <2)
                    display (sprintf ('%s:ilegal place',mfilename));
                    cellArrayMod = cellArray;
                    return;
                end
            elseif (isempty(STR.findStringInCellArray(place,{'begin','end'})))
                display (sprintf ('%s:ilegal place',mfilename));
                cellArrayMod = cellArray;
                return;


            end
            for i = 1:length(cellArray)
                if (strcmp(place,'end'))
                    cellArrayMod{i} = [cellArray{i} str];
                elseif (strcmp(place,'begin'))
                    cellArrayMod{i} = [str cellArray{i}];
                else
                    cellArrayMod{i} = [cellArray{i}(1:place) str cellArray{i}(place:end)];
                end
            end

            % return to the original size of the cell array
            if (size(cellArray,1)>size(cellArray,2))
                cellArrayMod = cellArrayMod';
            end

        end

        %%
        function [strCellArrayFilt indRes status] = filterStrCellArray (strCellArray,strFilter)
            global params;
            status = 0;
            strCellArrayFilt = [];
            indRes =[];

            strCellArray = STR.str2Cell(strCellArray);

            logicalSigns = {'&','|','~'};



            % if the filter is empty and  str ('''') we return nothing
            % if the filter is empty and not an str we return all
            if (isempty(strFilter))
                if (isstr(strFilter))
                    return;
                else
                    %         strCellArrayFilt = strCellArray;
                    %         indRes = 1:length(strCellArray);
                end
            end

            if (iscell(strFilter))
                indRes = find (ismember(strCellArray,strFilter));
                strCellArrayFilt = strCellArray(indRes);
                return;
            else

                strFilter = STR.cell2Str(strFilter);







                strCellArrayOrg = strCellArray;
                % clear striongs from problematic nodes
                % strFilter = prepareStr(strFilter,{'-',' '});
                % for i = 1:length(strCellArray)
                %     strCellArray{i} = prepareStr(strCellArray{i},{'-',' '});
                % end




                % we remove some signs for getting the logic nodes. Afterwards we will
                % return to the original filter

                if (isempty(strFilter))
                    strCellArrayFilt = STR.str2Cell(strCellArray);
                    indRes = 1:length(strCellArray);
                    return;
                end
                strFilterTemp = strFilter;

                strFilterTemp = strrep(strFilterTemp,'(','');
                strFilterTemp = strrep(strFilterTemp,')','');
                strFilterTemp = strrep(strFilterTemp,' ','');
                [logicalNodes,logicSign] = separateStr (strFilterTemp,logicalSigns,2,[]);

                for i = 1:length(logicalNodes)
                    if (strfind('evalDataSet',logicalNodes{i}))
                        newStr = [logicalNodes{i} '_'];
                        strCellArray = replaceStrInCellArray(strCellArray,logicalNodes{i},newStr);
                        strFilter = strrep(strFilter,logicalNodes{i},newStr);
                        logicalNodes{i} = newStr;
                    end
                end


                % logicalNodes = replaceStrInCellArray(logicalNodes,' ','');
                % get a logic results for teh present of each logicNode in each of the
                % strings in the strCellArray
                % evalDataSet = dataset([],[],'VarNames',logicalNodes);
                % evalDataSet = set(evalDataSet,'VarNames',logicalNodes);
                evalDataSet = table;
                strFilterMod = strFilter;

                [logicalNodes ind] = sortStrCellArray (logicalNodes,'long2Short');

                repChars = {'(',')',' ','<','=','>','~','-','.','$','*','/','\','+','[',']','{','}','#','"',';','@',':',''''};
                logicalNodesDS = logicalNodes;

                % logicalNodesDS = addStrToCellArray('_11',logicalNodesDS,'end');
                % for i = 1:length (logicalNodesDS)
                %     ind = strfind('eval',logicalNodesDS{i})
                %     if (~isempty(ind))
                %         logicalNodesDS{i} = logicalNodesDS{i}(end:-1:1);
                %     end
                % end
                for i = 1:length(repChars)
                    %     strFilterTemp = strrep(strFilterTemp,repChars{i},'_');
                    logicalNodesDS = replaceStrInCellArray(logicalNodesDS,repChars{i},'_');

                end

                % logicalNodesDS = replaceStrInCellArray(logicalNodes,'-','_');
                % str2num(logicalNodes{i})

                for i = 1:length(logicalNodes)
                    indFound = findStringInCellArray (logicalNodes{i},strCellArray,0);
                    evalDataSet.(['eval_' logicalNodesDS{i}]) = zeros(length(strCellArray),1);
                    evalDataSet.(['eval_' logicalNodesDS{i}])(indFound) = 1;

                    strFilterMod = strrep(strFilterMod,logicalNodes{i},['evalDataSet.' ['eval_' logicalNodesDS{i}] '']);
                    strFilterMod = strrep(strFilterMod,'eevalDataSet','evalDataSet');

                    strFilterMod = strrep(strFilterMod,'evalDataSet.eval_evalDataSet','evalDataSet');



                end

                % strFilterMod = strrep(strFilterMod,'eval_eval','eval');

                cmd = [strFilterMod ';'];


                try
                    res = eval (cmd);
                catch
                    myDisplay(sprintf('%s:''%s'' cannot be evaluated',mfilename,cmd));
                    status = 6; displayFuncPath(dbstack); return;
                end
                indRes = find(res);
                strCellArrayFilt = strCellArrayOrg(indRes);
                % apply filter on the logical results
                % logicRes =
            end
            strCellArrayFilt = STR.str2Cell(strCellArrayFilt);
        end


        %%
        %
        %   number greater than 2 and smaller than the minimum string length of the cell array
        function cellArray = replaceStrInCellArray (cellArray,str,strRrp)
            for i = 1:length(cellArray)
                cellArray{i} = strrep (cellArray{i},str,strRrp);
            end
        end

        %%
        function ind = findStrInCellArray(str,cellArray)
            for (i=1:length(cellArray))
                if (strcmp (cellArray{i},str))
                    ind = i;
                    return;
                end
            end
            ind = [];
            %UNTITLED3 Summary of this function goes here
            %   Detailed explanation goes here


        end


        %%
        function [strCellArray] = StrArray2StrCellArray(strArray)
            if (iscell(strArray))
                strCellArray = strArray;
                return;
            end
            strCellArray =[ ];
            for i = 1:size(strArray,1)
                strCellArray{i} = strArray(i,:);
            end
            strCellArray = strCellArray';
        end


        %%
        function [cellArray] = num2StrCellArray(vec,varargin)
            f1 = @(x) num2str(x);

            if (~iscell(vec))
                cellArray = cellfun(@(x){f1(x)}, num2cell(vec));
            else
                cellArray = cellfun(@(x){f1(x)}, vec);
            end
            if (nargin ==2)
                numChars = varargin{1};
                indChange = find(vec<10^(numChars-1));
                if (~isempty(indChange))
                    addStr = repmat('0',1,1);
                    cellArray(indChange) = STR.addStrToCellArray(addStr,cellArray(indChange),'begin');
                end
            end


        end


    end
end

