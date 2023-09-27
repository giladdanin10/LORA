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

else
    try
       dataSet.(str); 
       yesNo  = 1;
    catch
        yesNo  = 0;
    end
end
end
