[filepath,name,ext] = fileparts(mfilename('fullpath'));cd (filepath);

%from matlab git

close all
clear
%%
Fs = 5e6 ;
SF = 8;
BW = 250e3;
ylim_val = [-1 1]*5*BW/2/1e6;

sig = LORA.modulate_message([0 64 128 64 0],SF,BW,Fs,1.1234e3);
% ana_struct.freq_offset = 3e3;
% sig = LORA.correct_freq_offset(sig,ana_struct,Fs);
% sig = LORA.modulate_message(zeros(1,20),SF,BW,Fs);

%%
% Fs2 = BW;
Fs2 = BW;
% sig = resample(sig,Fs2,Fs);

[sig symbols R ana_struct status] = LORA.demodulate_message(sig,SF,BW,Fs,Fs2,'ADAFRUIT');if (status) return;end
sig_clean = LORA.get_clean_signal(sig,ana_struct,0);
preamble = LORA.get_preamble(sig,ana_struct,0);
preamble = preamble(1:round(length(preamble)/ana_struct.N_sps)*ana_struct.N_sps);
symbols_mat = (reshape(preamble,ana_struct.N_sps,length(preamble)/ana_struct.N_sps)).';


x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct,'clean');
LORA.plot_spectogram(sig_clean,'Fs',Fs,'yLim_val',ylim_val,'x_aux_line',x_aux_line_ind);


x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct,'full');
LORA.plot_spectogram(sig,'Fs',Fs,'yLim_val',ylim_val,'x_aux_line',x_aux_line_ind);
BW = LORA.calc_BW(sig,ana_struct,'Fs',Fs);

% N_chirps = 8;
% [ana_struct status] = LORA.analyze_signal(sig,SF,BW,Fs,'down_chirp');
% LORA.plot_spectogram(sig,'x_aux_line',ana_struct.start_symbol_ind,'Fs',Fs);
%
% symbols_vec = LORA.split_signal_to_symbol_segments(sig,ana_struct);
% [message R] = LORA.demodulate_symbol(symbols_vec,SF,BW,Fs);
% [symbols R] = LORA.demodulate_message(sig,SF,BW,Fs);

LORA.plot_corr_fft(R(:,1:4),'fig_name','corr_fft_ADAFRUIT');

PLOT.plot_signal({angle(sig),angle(ana_struct.basic_chirp)},'x_aux_line',LORA.get_x_aux_line_ind(ana_struct,'all'));



x_aux_line_ind = LORA.get_x_aux_line_ind(ana_struct,'full');

LORA.plot_spectogram({sig},'x_aux_line',x_aux_line_ind,'Fs',Fs,'legend',{'sig'});
symbols