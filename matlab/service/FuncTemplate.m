% get common parameters evolution through the design hirarchi.
% usage 1 (name value): FuncTemplate(name,value)
% usage 2 (params_struct): FuncTemplate(params_struct)
% usage 3 (default parameters}: FuncTemplate([])
% In order to get the available parameters: FuncTemplate
function [status] = FuncTemplate(varargin)
%% set params default vals and legal options

%status = 6;displayFuncPath(dbstack); return;
st = dbstack;funcname = st.name;

% if (nargin<=0)
%     varargin =  struct;
%     varargin.input_description{1} = '';    
%     varargin.input_description{2} = '';        
%     varargin.output_description{1} = '';               
% end


defaultParams = struct;
paramsLists = struct;

defaultParams.a = 'on'; % is a switch
paramsLists.a = {'on','off'};   % 'switch enabled','switch disabled'



paramsStruct.defaultParams = defaultParams;
paramsStruct.paramsLists = paramsLists;

%% parse parameters
[lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
create_lparams_vars;

%% function body


end