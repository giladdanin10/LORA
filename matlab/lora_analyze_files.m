close all;
clear

[filepath,name,ext] = fileparts(mfilename('fullpath'));cd (filepath);
plot_graphs = 1;

if (~exist('data_path.mat'))
    data_path = '../data';
else
    load('data_path.mat');
end
[fileI data_path] = uigetfile(fullfile(data_path,{'*.txt;*.mat'}));

save data_path data_path
if (strcmp(FILE.getFileExt(fileI),'mat'))
   Fs = 1e6;
   BW = 250;
   SF = 11;
    load ([data_path '\' fileI]);
else

    fileQ = strrep(fileI,'_I','_Q');

    nodes = strsplit(fileQ,'_');
    BW = str2num(nodes{1})*1e3;
    SF = str2num(nodes{2});

    if (strfind(fileI,'SIM'))
        Fs = 128e6;
    else
        Fs = 5e6;
    end

    yLim_val = [-1 1]*(BW/2+100e3)/1e6;


    [data_I status] = LORA.import_data_file([data_path '\' fileI]);if (status) return;end
    [data_Q status] = LORA.import_data_file([data_path '\' fileQ]);if (status) return;end

    len = min(length(data_I),length(data_Q));
    data_I = data_I(1:len);
    data_Q = data_Q(1:len);


    if (strfind(fileI,'SIM'))
        data_I = data_I/2^15;
        ind = find(data_I>1);
        data_I(ind) = -data_I(ind)+1;

        data_Q = data_Q/2^15;
        ind = find(data_Q>1);
        data_Q(ind) = -data_Q(ind)+1;

        % remove possiblle nans in the end of the files
        ind_nan = [find(isnan(data_I));find(isnan(data_Q))];
        data_I(ind_nan) = [];
        data_Q(ind_nan) = [];
    end

    sig = data_I+1j*data_Q;
end

% symbols_err_table = LORA.compare_symbols(symbols_ref,symbols_ADAFRUIT_ref);
if (Fs>5e6)
    sig = resample(sig,5e6,Fs);
    Fs = 5e6;

end


basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs);
[sig symbols R ana_struct] = LORA.demodulate_message(sig,SF,BW,Fs,BW,'SDR');
sig_clean = LORA.get_clean_signal(sig,ana_struct,3);

%% summarize

x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct,'full');

if (plot_graphs)
    LORA.plot_spectogram({sig},'x_aux_line',x_aux_line_ind,'Fs',Fs,'legend',{'SDR'});

    LORA.plot_corr_fft({R(:,1:4)},'fig_name','corr_fft','legend',{'SDR'});


end

% bols_err_table1 = LORA.compare_symbols(symbols_ADAFRUIT,symbols);
%     % symbols_err_table = LORA.compare_symbols(symbols_ADAFRUIT_ref,symbols_ref(7:end));
%     symbols_err_table2 = LORA.compare_symbols(symbols_ADAFRUIT_ref(7:end),symbols_ADAFRUIT);




%%

ana_struct_new = ana_struct;
ana_struct_new.start_symbol_ind = ana_struct_new.start_symbol_ind_new;
x_aux_line = LORA.get_x_aux_line_ind(ana_struct,'all');
x_aux_line_new = LORA.get_x_aux_line_ind(ana_struct_new,'all');

PLOT.plot_signal(angle(sig),'x_aux_line',{LORA.get_x_aux_line_ind(ana_struct,'all'),LORA.get_x_aux_line_ind(ana_struct_new,'all')})
symbols


