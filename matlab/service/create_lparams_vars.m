global GparamsStruct
if (~isempty(lparams))
fieldNames = fields(lparams);

for i = 1:length(fieldNames)
    str1 = sprintf('%s = lparams.%s;',fieldNames{i},fieldNames{i});
    eval (str1);
end
end

GparamsStruct = paramsStruct;