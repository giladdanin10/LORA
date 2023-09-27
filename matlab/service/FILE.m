classdef FILE
    %FILEM Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function displayFuncPath(funcPath)
            global strG;
            temp = strG;
            for i = 1:length(funcPath)
                display(sprintf('error in %s (line %d)',funcPath(i).name,funcPath(i).line));
            end
            strG = temp;
        end

        %%
        function [ dir_name_mod ] = prepare_dir_name( dir_name,OS_type)
            global gsim

            if (~PARSE.isField('OS_type',gsim))
                gsim.OS_type = MANAGE.get_OS_name;
            end

            if (nargin==1) || isempty(gsim.OS_type)
                if (isempty(gsim.OS_type))
                    gsim.OS_type = 'windows';
                end

                gsim.OS_type = gsim.OS_type;
            end

            switch gsim.OS_type
                case 'windows'
                    dir_name_mod = strrep(dir_name,'/','\');
                    dir_name_mod = strrep(dir_name_mod,'\\','\');

                case 'linux'
                    dir_name_mod = strrep(dir_name,'\','/');
                    dir_name_mod = strrep(dir_name_mod,'//','/');



            end


        end

        % getFolderFileNames gets the file names placed at an input directory location
        % input parameters:
        %   1. dirName - input directory name
        %   2. mode - mode of opeartion (optional) -
        %         1. 'lastNode' (default) - outputs only the actual file name (without the full path)
        %         2. 'fullPath' - outputs the full path name
        %   3. fileNameFilter - a string filter applied to the found fileNames (optional)
        % example:
        %   getFolderFileNames('T:\afikim\EAR Tag\videoed tests\680\230815\exp2','fullPath','csv & processed') will output all the filenames
        %   containing the strings 'csv' and 'processed' located in the 'T:\afikim\EAR Tag\videoed tests\680\230815\exp2' folder

        function [fileNames status] = getFolderFileNames(dirName,varargin)
            if (nargin==1)
                mode = 'lastNode';
                fileNameFilter = [];
            elseif (nargin==2)
                mode = varargin;
                fileNameFilter = [];
            elseif (nargin==3)
                mode = varargin{1};
                fileNameFilter = varargin{2};


            end

            status = PARSE.ParseParamter(mode,'mode',{'lastNode','fullPath'});if (status) return;end

            status = 0;
            fileNames =[];
            dirName = STR.cell2Str(dirName);
            if (~exist(dirName))
                display(sprintf('%s: %s does not exist',mfilename,dirName));
                status = 6;displayFuncPath(dbstack);
                return;
            end
            d = dir(dirName);
            isub = [d(:).isdir]; %# returns logical vector
            fileNames = {d(~isub).name}';
            fileNames(find(ismember({'.','..'},fileNames))) =[];

            if (strcmp(mode,'fullPath'))
                fileNames = STR.addStrToCellArray([dirName '\'],fileNames,'begin');
            end

            fileNames = STR.filterStrCellArray(fileNames,fileNameFilter);
            for i = 1:length(fileNames)
                fileNames{i} = FILE.prepare_dir_name(fileNames{i});
            end
        end

        %%
        function [ fileExt ] = getFileExt( fileName )
            indExt = findstr(fileName, '.');
            if (isempty(indExt))
                fileExt = [];
                return;
            end

            fileExt = fileName(indExt(end)+1:end);
        end

        %%
        function [ status ] = export_cell_array_to_text_file(file_name,C,formatSpec)
            if (nargin==2)
                formatSpec = '%s\n';
            end
            status = 0;
            fileID = fopen(file_name,'w');
            if (fileID==-1)
                myDisplay(sprintf('%s: could not open ''%s'' for writing',mfilename,file_name))
                status = 6;displayFuncPath(dbstack); return;
            end
            [nrows] = size(C);
            for row = 1:nrows
                fprintf(fileID,formatSpec,C{row,:});
            end
            fclose(fileID);

        end

        %%
        function [status] = checkExistance(fileName)
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


        % get the file path from the file name
        function [filePath] = GetFilePath (fileName)
            % get the actual file name (without the path)
            fileNameLastNode = FILE.getPathNode(fileName,1);

            % remove it from the full path name
            filePath = strrep(fileName,fileNameLastNode,'');

            % remove '/' or '\' signs in the end
            dashFound = 1;
            i = length(filePath);
            while dashFound && i>0
                if (strcmp(filePath(i),'\')) || (strcmp(filePath(i),'/'))
                    i = i-1;
                else
                    dashFound = 0;
                end
            end

            filePath(i+1:end) = [];

        end


        %%
        function [ node] = getPathNode(path,varargin)

            path = STR.str2Cell(path);
            for i = 1:length(path)
                % handle empty path
                if (isempty(path{i}))
                    node = [];
                    return;
                end

                if (path{i}(end)== '\') || (path{i}(end)== '/')
                    path{i}(end) = [];
                end
                if nargin==1
                    nodeNum = 1;
                    mode = 'specifiedNodeOnly';
                else
                    nodeNum = varargin{1};
                end

                if nargin==2
                    mode = 'specifiedNodeOnly';
                else
                    nodeNum = varargin{1};
                    mode = varargin{2};
                end



                findCoupleDash = 1;
                while (findCoupleDash==1)
                    path{i} = strrep(path{i},'\\','\');
                    path{i} = strrep(path{i},'//','/');
                    findCoupleDash = ~isempty(strfind(path{i},'//'));
                end

                ind1 = strfind(path{i},'\');
                ind2 = strfind(path{i},'/');



                ind = unique([ind1 ind2]);

                % could happen if the path contains only one node (local path)
                if (isempty(ind))
                    if (nodeNum==1)
                        node{i} = path{i};
                    else
                        node{i} = [];
                    end
                else

                    ind = sort(ind,'descend');

                    if (nodeNum>length(ind))
                        node{i} = '';
                    elseif(nodeNum==1)
                        node{i} = path{i}((ind(nodeNum)+1):length(path{i}));
                    else
                        switch (mode)
                            case 'specifiedNodeOnly'
                                node{i} = path{i}((ind(nodeNum)+1):(ind(nodeNum-1)-1));
                            case 'endToSpecified'
                                node{i} = path{i}((ind(nodeNum)+1):length(path{i}));
                            case 'startToSpecified'
                                nodePre = path{i}((ind(nodeNum)+1):length(path{i}));
                                node{i} = strrep(path{i},nodePre,'');
                        end
                    end
                end


                if (length(path)==1)
                    node = STR.cell2Str(node);
                end
            end
        end

        %%
        function [ fileNamePayLoad status] = GetFileNamePayLoad( fileName )
            status = 0;
            fileNamePayLoad = [];
            orgSize = size(fileName);
            fileNameCell = STR.str2Cell(fileName);

            for i = 1:length(fileNameCell)
                fileName = fileNameCell{i};
                fileName = STR.cell2Str(fileName);
                % clear path
                fileNameClean = FILE.getPathNode(fileName,1);

                % no '/' in teh fileName --> clean file already
                if (isempty(fileNameClean))
                    fileNameClean = fileName;
                end
                indExt = findstr(fileNameClean, '.');
                if (isempty(indExt))
                    fileNamePayLoad{i} = fileNameClean;
                else
                    fileNamePayLoad{i} = fileNameClean(1:indExt(end)-1);
                end
            end

            if (length(fileNamePayLoad)==1)
                fileNamePayLoad = STR.cell2Str(fileNamePayLoad);
            else
                fileNamePayLoad = reshape(fileNamePayLoad,orgSize(1),orgSize(2));
            end
        end

%%


    end
end
