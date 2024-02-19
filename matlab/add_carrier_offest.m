%%
load sig_5M;sig_SDR = sig_5M;
N_cycle = 30;
f = Fs/length(sig_SDR)*N_cycle;
carrier_offset_sig = exp(j*2*pi*f/Fs*(1:length(sig_SDR)));
sig_SDR = sig_SDR.*carrier_offset_sig.';