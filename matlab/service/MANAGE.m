classdef MANAGE
    %MANAGE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function dir_name = get_OS_name
            dir_name = pwd;
            if (strfind(pwd,'\'))
                dir_name = 'windows';
            else
                dir_name = 'linux';
            end

        end


        %%
        function [subDirNames status] = getSubFolderNames(dirName,varargin)
            global OS;
            if (nargin==1)
                mode = 'lastNode';
            else
                mode = varargin{1};
            end

            if (nargin>2)
                strFilter = varargin{2};
            else
                strFilter = [];
            end
            status = 0;
            subDirNames =[];


            dirName = FILE.prepare_dir_name(dirName,OS);

            dirName = STR.cell2Str(dirName);
            if (~exist(dirName))
                display(sprintf('%s: %s does not exist',mfilename,dirName));
                status = 6;FILE.displayFuncPath(dbstack);
                return;
            end


            if (dirName(end) ~= '\')
                dirName = [dirName '\'];
            end

            dirName = FILE.prepare_dir_name(dirName,OS);

            d = dir(dirName);
            isub = [d(:).isdir]; %# returns logical vector
            subDirNames = {d(isub).name}';
            subDirNames(find(ismember({'.','..'},subDirNames))) =[];

            if (strcmp(mode,'fullPath') && (~isempty(subDirNames)))
                subDirNames = STR.addStrToCellArray([dirName],subDirNames,'begin');
            end

            subDirNames = STR.filterStrCellArray(subDirNames,strFilter);
            subDirNames = STR.str2Cell(subDirNames);
        end

        %%
        function [lines_cell_array status] = import_text_file_to_cell_array(filename, startRow, endRow)
            status = 0;
            lines_cell_array = [];
            long_file_thresh = 1000;

            status = MANAGE.CheckExistance(filename);if (status) return;end

            %% Initialize variables.
            delimiter = '';
            if nargin<=2
                startRow = 1;
                endRow = inf;
            end

            %% Format string for each line of text:
            %   column1: text (%q)
            % For more information, see the TEXTSCAN documentation.
            formatSpec = '%q%[^\n\r]';

            %% Open the text file.
            if (isempty(filename))
                myDisplay(sprintf('%s: filename is empty'));
                status = 6;displayFuncPath(dbstack); return;
            end
            fileID = fopen(filename,'r');
            if (fileID==-1)
                myDisplay(sprintf('%s:could not open ''%s'' for reading',mfilename,filename));
                status = 6;displayFuncPath(dbstack); return;
            end

            % check the size of the file
            textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
            dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'ReturnOnError', false);
            if (length(dataArray{1})>long_file_thresh)
                %% Read columns of data according to format string.
                % This call is based on the structure of the file used to generate this
                % code. If an error occurs for a different file, try regenerating the code
                % from the Import Tool.

                %     for block=2:length(startRow)
                %         frewind(fileID);
                %         textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
                %         dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'ReturnOnError', false);
                %         dataArray{1} = [dataArray{1};dataArrayBlock{1}];
                %     end

                %% Create output variable
                lines_cell_array = [dataArray{1:end,1}];

            else
                % reopen the file (because of the file length check)
                fclose(fileID);
                fileID = fopen(filename,'r');

                line_ex = '';
                lines_cell_array = [];
                while ischar(line_ex)
                    line_ex = fgetl(fileID);  % read line excluding newline character
                    lines_cell_array = [lines_cell_array;STR.str2Cell(line_ex)];
                end

                lines_cell_array(end) = [];
                %



                %% Post processing for unimportable data.
                % No unimportable data rules were applied during the import, so no post
                % processing code is included. To generate code which works for
                % unimportable data, select unimportable cells in a file and regenerate the
                % script.
            end

            %% Close the text file.
            fclose(fileID);

        end

        %%
        function [status] = CheckExistance(fileName)
            status = 0;
            fileName = STR.cell2Str(fileName);
            if (isempty(fileName))
                myDisplay(sprintf('%s: empty fileName',mfilename));
                status = 6;displayFuncPath(dbstack);return;
            end

            if (~exist(fileName))
                % check the matlab path
                stat = which (fileName);
                if (isempty(stat))
                    myDisplay(sprintf('%s: %s does not exist',mfilename,fileName));
                    status = 6;displayFuncPath(dbstack);return;
                end
            end
        end

        %%
        function b = copyobj(a)
            b = eval(class(a));  %create default object of the same class as a. one valid use of eval
            for p =  properties(a).'  %copy all public properties
                p = cell2mat(p);
                try   %may fail if property is read-only
                    b.(p) = a.(p);
                catch
                    warning('failed to copy property: %s', p);
                end
            end
        end

        %%
        function publish(varargin)
            %status = 6;displayFuncPath(dbstack); return;
            st = dbstack;funcname = st.name;


            defaultParams = struct;
            paramsLists = struct;

            defaultParams.out_dir = []; % is a switch
            defaultParams.source_dir = [];


            paramsStruct.defaultParams = defaultParams;
            paramsStruct.paramsLists = paramsLists;

            %% parse parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

         
            copyfile(source_dir,out_dir)
        end

    end
end

