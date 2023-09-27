function myDisplay( str,varagin )
global gsim;
global logFile;
% global guiOn;

global strG;
% return;
% if ~isempty(guiOn) && (guiOn==1)     
%         global str 
%     
% end


if (isField('print_messages',gsim))
    if (gsim.print_messages==0)
        return;
    end
end

disp (str);
return;

strG = str;

if (nargin==1)
    file = logFile;
%     check if the file identifier exists or not
    filename = fopen(file);
    if (strcmp(filename,'dummyFile'))
        file = fopen ('log.txt','w');
    end
    
else
    file = varagin;
end



strNew = strrep (str,'\', '\\');
% strNew = str;
fprintf (file,strNew);
fprintf (file,'\n');
disp (str);

end

