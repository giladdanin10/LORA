close all;
clear

[filepath,name,ext] = fileparts(mfilename('fullpath'));cd (filepath);
plot_graphs = 1;


%% get data
base_dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\data';
% mode = 'create_symbols_for_SDR';
% mode = 'check_SDR';

mode = 'SDR_ADAFRUIT_comparison';

ana_folder = [base_dir '\' '130223\Hello_World_500_08_5_1_1_PASS'];
% ana_folder = [base_dir '\' '200223\ZEROS_0250_08_5_1_1'];
% ana_folder = [base_dir '\' '150223\01020304050607080910111213141516_250_08_5_1_2_PASS'];
% ana_folder = [base_dir '\' '160223\32CHARS_250_11_5_1_1'];

file_type = '.txt'
Fs = 5e6;
BW = 500e3;
SF = 8;
[SF BW Fs status] = LORA.parse_folder_name(ana_folder);if (status) return;end
Fs2 = BW;
yLim_val = [-1 1]*(BW/2+100e3)/1e6;
ADA_ind = [];
SDR_ind = [];

% file_type = '.mat'
% ana_folder = [base_dir '\' '080823\125_11'];
% Fs = 5e6;
% BW = 125e3;
% SF = 10;
% Fs2 = BW;
% ADA_ind = [970756 1795670];
% SDR_ind = [1926010 3850350];
%
file_type = '.mat'
ana_folder = [base_dir '\' '100823\125_10'];
Fs = 1.25e6;
BW = 125e3;
SF = 10;
Fs2 = BW;
ADA_ind = [705616 1170270];
SDR_ind = [728306 1928110];


yLim_val = [-1 1]*(BW/2+100e3)/1e6;

[sig_ADAFRUIT sig_SDR symbols_ADAFRUIT_ref symbols_SDR_ref status] = LORA.import_data_folder(ana_folder,'mode',mode,'file_type',file_type,'ADA_ind',ADA_ind,'SDR_ind',SDR_ind);if (status) return;end






% read synthetic files and add offset
% add_carrier_offest;

% [sig_ADAFRUIT sig_SDR symbols_ADAFRUIT_ref symbols_SDR_ref status] = LORA.import_data_folder([base_dir '\' '130223\010203040506_500_08_5_1_1_PASS'],[]);if (status) return;end
if (~isempty(sig_ADAFRUIT))
    %     sig_ADAFRUIT = LORA.prepare_signal(sig_ADAFRUIT,SF,BW,Fs);

    %% analyze signals
    [sig_ADAFRUIT symbols_ADAFRUIT R_ADAFRUIT ana_struct_ADAFRUIT status] = LORA.demodulate_message(sig_ADAFRUIT,SF,BW,Fs,Fs2,'ADAFRUIT');if (status) return;end
    sig_ADAFRUIT_clean = LORA.get_clean_signal(sig_ADAFRUIT,ana_struct_ADAFRUIT,3);

    x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct_ADAFRUIT,'full');

    x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct_ADAFRUIT,'full');
    if (plot_graphs)
        LORA.plot_spectogram({sig_ADAFRUIT},'x_aux_line',x_aux_line_ind,'Fs',Fs,'legend',{'ADAFRUIT'});
    end
end
%%
% start_symbol = 10;
% LORA.plot_corr_fft({R_ADAFRUIT(:,start_symbol:start_symbol+3)},[])
%%
if (~isempty(sig_SDR))

    % symbols_err_table = LORA.compare_symbols(symbols_SDR_ref,symbols_ADAFRUIT_ref);
    % basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs);
    [sig_SDR symbols_SDR R_SDR ana_struct_SDR] = LORA.demodulate_message(sig_SDR,SF,BW,Fs,Fs2,'SDR');
    sig_SDR_clean = LORA.get_clean_signal(sig_SDR,ana_struct_SDR,3);
end
%% summarize
if (~isempty(sig_ADAFRUIT))
    x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct_ADAFRUIT,'clean');
    if (plot_graphs)
        LORA.plot_spectogram({sig_ADAFRUIT_clean},'x_aux_line',x_aux_line_ind,'Fs',Fs,'legend',{'ADAFRUIT'});

        LORA.plot_corr_fft({R_ADAFRUIT(:,1:4)},'fig_name','corr_fft_SDR','legend',{'ADAFRUIT'});
        %         x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct_ADAFRUIT,'clean');

        PLOT.plot_signal(sig_ADAFRUIT,'x_aux_line',LORA.get_x_aux_line_ind(ana_struct_ADAFRUIT,'all'))
    end
    LORA.export_symbols_to_SDR(symbols_ADAFRUIT,ana_folder,'format','Keysight');
end
if (~isempty(sig_SDR))
    x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct_SDR,'full');

    if (plot_graphs)
        LORA.plot_spectogram({sig_SDR},'x_aux_line',x_aux_line_ind,'Fs',Fs,'legend',{'SDR'});

        LORA.plot_corr_fft({R_SDR(:,1:4)},'fig_name','corr_fft_SDR','legend',{'SDR'});


    end

    % bols_err_table1 = LORA.compare_symbols(symbols_ADAFRUIT,symbols_SDR);
    %     % symbols_err_table = LORA.compare_symbols(symbols_ADAFRUIT_ref,symbols_SDR_ref(7:end));
    %     symbols_err_table2 = LORA.compare_symbols(symbols_ADAFRUIT_ref(7:end),symbols_ADAFRUIT);




    %%

    ana_struct_SDR_new = ana_struct_SDR;
    ana_struct_SDR_new.start_symbol_ind = ana_struct_SDR_new.start_symbol_ind_new;
    x_aux_line = LORA.get_x_aux_line_ind(ana_struct_SDR,'all');
    x_aux_line_new = LORA.get_x_aux_line_ind(ana_struct_SDR_new,'all');

    PLOT.plot_signal(angle(sig_SDR),'x_aux_line',{LORA.get_x_aux_line_ind(ana_struct_SDR,'all'),LORA.get_x_aux_line_ind(ana_struct_SDR_new,'all')})

end

