function displayFuncPath(funcPath)
global strG;
temp = strG;
for i = 1:length(funcPath)
    myDisplay(sprintf('error in %s (line %d)',funcPath(i).name,funcPath(i).line));   
end
strG = temp;
end