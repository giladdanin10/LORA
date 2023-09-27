classdef LORA
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        %%
        %         function [symb_sig] = symb_sig_gen(val,SF,BW,Fs)
        %             M = 2^SF;
        %             Tsymb = M/BW*2;
        %             t = 0:1/Fs:(Tsymb-1/Fs);
        %
        %             n_symbol_samples = length(t);
        %             dk = floor(n_symbol_samples/M); % the length of basic delay of symbol
        %             K = val*dk;
        %
        %             %             basic_chirp = chirp(t,-BW/2,t(end),BW/2,'linear',0,'complex');
        %             basic_chirp = chirp(t,0,t(end),BW);
        %
        %
        %             symb_sig = circshift(basic_chirp,K);
        %             symb_sig = (loramod(val,SF,BW,Fs)).';
        %             %             symb_sig = [zeros(1,K) basic_chirp(1:length(basic_chirp)-K)];
        %         end

        function [y] = modulate_symbol(x,SF,BW,fs,varargin)
            % loramod LoRa modulates a symbol vector specified by x
            %
            %   in:  x          1xN symbol vector wher N=1-Inf
            %                   with values {0,1,2,...,2^(SF)-1}
            %        BW         sig BW of LoRa transmisson
            %        SF         spreading factor
            %        Fs         sampling frequency
            %        varargin{1} polarity of chirp
            %
            %  out:  y          LoRa IQ waveform
            if (nargin < 4)
                error(message('comm:pskmod:numarg1'));
            end

            if (nargin > 5)
                error(message('comm:pskmod:numarg2'));
            end

            % Check that x is a positive integer
            if (~isreal(x) || any(any(ceil(x) ~= x)) || ~isnumeric(x))
                error(message('comm:pskmod:xreal1'));
            end

            M = 2^SF ;

            % Check that M is a positive integer
            if (~isreal(M) || ~isscalar(M) || M<=0 || (ceil(M)~=M) || ~isnumeric(M))
                error(message('comm:pskmod:Mreal'));
            end

            % Check that x is within range
            if ((min(min(x)) < 0) || (max(max(x)) > (M-1)))
                error(message('comm:pskmod:xreal2'));
            end

            % Polarity of Chirp
            if nargin == 4
                Inv = 1 ;
            elseif nargin == 5
                Inv = varargin{1} ;
            end
            % Symbol Constants
            Ts      = 2^SF/BW ;
            Ns      = fs.*M/BW ;

            gamma   = x/Ts ;
            beta    = BW/Ts ;

            time    = (0:Ns-1)'.*1/fs ;
            freq    = mod(gamma + Inv.*beta.*time,BW) - BW/2 ;

            Theta   = cumtrapz(time,freq) ;
            y       = reshape(exp(j.*2.*pi.*Theta),numel(Theta),1) ;
        end

        %%
        function [sig] = symb_vec_sig_gen(val,SF,BW,Fs)
            sig = [];
            for i = 1:length(val)
                sig = cat(2,sig,LORA.symb_sig_gen(val(1),SF,BW,Fs));
            end
        end

        %%
        function status = plot_spectogram(sig,varargin)
            %status = 6;displayFuncPath(dbstack); return;
            st = dbstack;funcname = st.name;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;

            defaultParams = PLOT.get_standard_plot_params;
            defaultParams.Fs = 1;
            defaultParams.Ndft = 4096;
            defaultParams.L = 11;
            defaultParams.g = hanning(256);
            defaultParams.x_aux_line = [];
            defaultParams.type = '1D';
            paramsLists.type = {'1D','2D'};

            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            %% parase parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

            clear legend


            if (isempty(axesH))
                fig = figure;
                fig.Name = fig_name;
                axesH = axes;
                ZoomHandle = zoom(fig);
                set(ZoomHandle,'Motion','horizontal')

            end

            if (~iscell(sig))
                sig  = {sig};
            end

            if (size(sig,1)>size(sig,2))
                mode = 'multiple_axes';
                for i = 1:length(sig)
                    axesH(i) = subplot(length(sig),1,i);
                end
                colors = repmat([0 0 1],length(sig),1);
            else
                mode = 'single_axes';
                colors = PLOT.createColors(length(sig));
                %                 lparams.legend = (lparams.legend).';

            end



            for i = 1:length(sig)
                [x f_t t status] = LORA.calc_freq_over_t(sig{i},lparams);if (status) return;end

                switch lparams.type
                    case '1D'
                        [a,locs] = max(abs(x),[],1);
                        filter_junk_flag = false;


                        x_tmp = round(x_aux_line./length(sig{i})*size(x,2));
                        x_tmp(find(x_tmp==0)) = [];
                        x_tmp(find(x_tmp>length(f_t))) = [];
                        symbol_change = nan(size(f_t));
                        symbol_change(x_tmp) = f_t(x_tmp);

                        if(filter_junk_flag)
                            th = 20;
                            junk_idx = a<th;
                            locs(junk_idx) = [];
                            f_t(junk_idx(1:length(f_t))) = [];
                            symbol_change(junk_idx(1:length(symbol_change))) = [];
                        end

                        switch mode
                            case 'multiple_axes'
                                axes (axesH(i));
                            case 'single_axes'

                        end

                        plot(f_t,'LineWidth',2,'color',colors(i,:));hold all;




                    case '2D'
                        x = flipud(x);

                        %                     pspectrum(sig(i,:),Fs,'spectrogram', ...
                        %                         'OverlapPercent',99,'Leakage',0.85);
                        if (~isempty(yLim_val))
                            ylim(yLim_val);
                        end

                        for x_aux_val_pre = x_aux_line
                            x_aux_val = round(x_aux_val_pre/length(sig)*size(x,2));
                            x(:,x_aux_val) = 255;
                        end

                        image(abs(x));

                        if (N_col==1)
                            if (~isempty(title_str))
                                title (PLOT.prepareStrForPlot(title_str));
                            end
                        else
                            title (PLOT.prepareStrForPlot(['symbol ' num2str(i)]));
                        end
                end
            end


            %% finalize axesH


            for i = 1:length(axesH)
                axes(axesH(i));
                if (~isempty(x_aux_line))
                    [x_data_mod y_data_mod] = PLOT.create_vertical_auxilery_grid_line(x_tmp,axesH(i).YLim);
                    line(x_data_mod,y_data_mod,'LineStyle','--','color',[0 0 0]);
                    plot(symbol_change,'*','color',[0 0 0])
                    grid minor;
                    switch mode
                        case 'multiple_axes'
                            legend_str = [lparams.legend(i) {''} {''}];
                        case 'single_axes'
                            legend_str = [lparams.legend {''} {''}];
                    end
                    if (~isempty(lparams.legend))
                        legend(legend_str)

                    end
                end



            end



        end


        %%
        function [x f_t t status] = calc_freq_over_t (sig,varargin)
            defaultParams.Fs = 1;
            defaultParams.Ndft = 4096;
            defaultParams.L = 11;
            defaultParams.g = hanning(256);
            defaultParams.filter_junk_flag = false;
            paramsLists = struct;

            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            %% parase parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;
            [x f t] = spectrogram(sig,g,L,Ndft,Fs,'yaxis','centered');


            [a,locs] = max(abs(x),[],1);
            

            f_t = f(locs)'; % instead of flipud (as in x)
            if (filter_junk_flag)    
                
                th = 20;
                junk_idx = a<th;
                %             locs(junk_idx) = [];
                f_t(junk_idx) = [];
            end



        end

        %%
        function status = plot_symbols_spectogram(sig,varargin)
            %status = 6;displayFuncPath(dbstack); return;
            st = dbstack;funcname = st.name;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;

            defaultParams = PLOT.get_standard_plot_params;
            defaultParams.Fs = 1;
            defaultParams.Ndft = 4096;
            defaultParams.L = 11;
            defaultParams.g = hanning(256);
            defaultParams.x_aux_line = [];
            defaultParams.type = '1D';
            paramsLists.type = {'1D','2D'};

            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            %% parase parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

            if (isempty(axesH))
                fig = figure;
                fig.Name = fig_name;
                axesH = axes;
                ZoomHandle = zoom(fig);
                set(ZoomHandle,'Motion','horizontal')

            end
            axes (axesH);
            status = 0;

            % make sig a rows matrix
            if size(sig,1)>size(sig,2)
                sig = sig.';
            end

            N_rows_max = 4;
            N_symbols = size(sig,1);
            N_col = min(N_symbols,2);
            N_rows = ceil(N_symbols/2);
            %             N_col = ceil(N_symbols/N_rows_max);
            %             N_rows = min(N_symbols,N_rows_max);
            if (~isempty(lparams.axesH))
                %                 pspectrum(sig,Fs,'spectrogram', ...
                %                     'OverlapPercent',99,'Leakage',0.85);

                spectrogram(sig,g,L,Ndft,Fs,'yaxis','centered');
                if (~isempty(yLim_val))
                    ylim(yLim_val);
                end
                title (PLOT.prepareStrForPlot(title_str));

            else

                if (iscell(sig))
                    for i = 1:length(sig)
                        axesH(i) = subplot(length(sig),1,i);
                        spectrogram(sig{i},g,L,Ndft,Fs,'yaxis','centered');

                        if (~isempty(yLim_val))
                            ylim(yLim_val);
                        end

                        if (~isempty(title_str))
                            title (PLOT.prepareStrForPlot(title_str{i}));
                        end

                    end
                    linkaxes(axesH)
                else

                    for i = 1:N_symbols
                        axesH = subplot(N_rows,N_col,i);
                        [x f t] = spectrogram(sig(i,:),g,L,Ndft,Fs,'yaxis','centered');

                        switch lparams.type
                            case '1D'
                                [a,locs] = max(abs(x),[],1);
                                filter_junk_flag = true;


                                f_t = f(locs)'; % instead of flipud (as in x)
                                x_tmp = round(x_aux_line./length(sig)*size(x,2));
                                x_tmp(find(x_tmp==0)) = [];
                                symbol_change = nan(size(f_t));
                                symbol_change(x_tmp) = f_t(x_tmp);

                                if(filter_junk_flag)
                                    th = 20;
                                    junk_idx = a<th;
                                    locs(junk_idx) = [];
                                    f_t(junk_idx) = [];
                                    symbol_change(junk_idx) = [];
                                end

                                %
                                %                                 figure;
                                %                                 symbol_change(find(isnan(symbol_change))) = [];
                                plot(f_t,'LineWidth',2);hold all;
                                for val = x_tmp
                                    line('xData',[val val],'yData',[axesH.YLim],'LineStyle','--');
                                end


                                plot(symbol_change,'*')
                                grid minor;

                            case '2D'
                                x = flipud(x);

                                %                     pspectrum(sig(i,:),Fs,'spectrogram', ...
                                %                         'OverlapPercent',99,'Leakage',0.85);
                                if (~isempty(yLim_val))
                                    ylim(yLim_val);
                                end

                                for x_aux_val_pre = x_aux_line
                                    x_aux_val = round(x_aux_val_pre/length(sig)*size(x,2));
                                    x(:,x_aux_val) = 255;
                                end

                                image(abs(x));

                                if (N_col==1)
                                    if (~isempty(title_str))
                                        title (PLOT.prepareStrForPlot(title_str));
                                    end
                                else
                                    title (PLOT.prepareStrForPlot(['symbol ' num2str(i)]));
                                end
                        end
                    end
                end
            end


        end

        %         function [tau R_lpf] = demodulate(sig,SF,BW,Fs)
        %             basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs);
        %
        %             r = basic_chirp.*sig;r = (r(:)).';
        %             %             window = hamming(length(r));window = (window(:))';
        %             %             rw = window.*r;
        %             %             R = fft(r);
        %
        %             %temp
        %             % r = ifft(ones(size(r)));
        %
        %             r_lpf = lowpass(r,BW,Fs);
        %
        %             R_lpf = fft(r_lpf);
        %
        %
        %             [~,ind] = max(abs(R_lpf));
        %             tau = (ind-1)/length(R_lpf)*Fs

        %         end

        %%
        function plot_corr_fft(R_in,varargin)
            %status = 6;displayFuncPath(dbstack); return;
            st = dbstack;funcname = st.name;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;

            defaultParams = PLOT.get_standard_plot_params;

            paramsStruct.defaultParams = defaultParams;
            paramsStruct.paramsLists = paramsLists;

            %% parse parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

            if (~iscell(R_in))
                R_in = {R_in};
            end
            fig = figure;
            fig.Name = fig_name;

            R = R_in{1};
            N_rows_max = 4;
            N_symbols = size(R,2);
            N_col = min(N_symbols,2);
            N_rows = ceil(N_symbols/2);

            for i = 1:N_symbols
                axesH(i) = subplot(N_rows,N_col,i);
            end


            colors = PLOT.createColors(length(R_in));

            for j = 1:length(R_in)
                R = R_in{j};
                if (size(R,1)<size(R,2))
                    R = R.';
                end
                x = -length(R)/2:(length(R)/2-1);
                %             figure;plot(x,20*log10(fftshift(abs(R))));

                %                 N_rows_max = 4;
                %                 N_symbols = size(R,2);
                %                 N_col = min(N_symbols,2);
                %                 N_rows = ceil(N_symbols/2);
                %                 fig = figure;
                %                 fig.Name = fig_name;
                for i = 1:N_symbols
                    %                     subplot(N_rows,N_col,i);
                    axes (axesH(i));
                    plot(x,20*log10(fftshift(abs(R(:,i)))),'Color',colors(j,:));hold on;
                    title (PLOT.prepareStrForPlot(['symbol ' num2str(i)]));
                end


            end

            for i = 1:N_symbols
                %                     subplot(N_rows,N_col,i);
                axes (axesH(i));
                clear legend
                legend(lparams.legend);
            end
        end



        %%
        function preamble = generate_preamble(N_zeros,SF,BW,Fs)
            preamble = LORA.modulate_symbol([zeros(1,N_zeros)],SF,BW,Fs,1);
            preamble1 = LORA.modulate_symbol([zeros(1,2)],SF,BW,Fs,-1);
            preamble = cat(1,preamble,preamble1);

        end




        %%
        function [symbols_mat symbols_sig] = split_signal_to_symbol_segments(sig,Fs2,Fs,ana_struct)
            %             if (nargin==4)
            %                 start_ind = 1;
            %             end
            %             sig = sig(:).';
            %             sig = sig(start_ind:end);
            % %             symbol_length = 2^SF*Fs/BW;
            %   symbol_length = sps;
            sig_ds = resample(double(sig),Fs2,Fs);
            ana_struct.start_symbol_ind = ana_struct.start_symbol_ind;
            ana_struct.ind_message_start = ana_struct.ind_message_start;
            ana_struct.N_sps = ana_struct.N_sps;

            N_symbols = length(ana_struct.start_symbol_ind);

            % for the segmentation use the resampled version of things
            ind_message_start = round(ana_struct.ind_message_start*Fs2/Fs)+1;
            N_sps = round(ana_struct.N_sps*Fs2/Fs);

            symbols_sig = sig_ds(ind_message_start:ind_message_start+N_symbols*N_sps-1);
            symbols_mat = (reshape(symbols_sig,N_sps,N_symbols)).';
        end


        %%
        function signal_mod = modulate_message(message,SF,BW,Fs,varargin)
            % LoRa_Tx emulates a Lora transmission
            %
            %   in:  message      payload message
            %        BW    sig BW of LoRa transmisson
            %        SF           spreading factor
            %        Pt           transmit power in deicbels
            %        Fs           sampling frequency
            %        dF           frequency offset
            %        varargin{1}  code rate
            %        varargin{2}  symbols in preamble
            %        varargin{3}  sync key
            %
            %  out:  sig       LoRa IQ waveform
            %        packet       encoded message
            %
            % Dr Bassel Al Homssi
            % RMIT University
            % Credit to rpp0 on https://github.com/rpp0/gr-lora
            if nargin == 4
                dF = 0;
            else
                dF = varargin{1};
            end
            n_preamble = 8 ;
            SyncKey = 1;
            Pt = 0;
            %             if nargin == 6
            %                 CR = 1 ;
            %                 n_preamble = 8 ;
            %                 SyncKey = 5 ;
            %                 SyncKey = 0;
            %             elseif nargin == 7
            %                 CR = varargin{1} ;
            %                 n_preamble = 8 ;
            %                 SyncKey = 5 ;
            %             elseif nargin == 8
            %                 CR = varargin{1} ;
            %                 n_preamble = varargin{2} ;
            %                 SyncKey = 5 ;
            %             elseif nargin == 9
            %                 CR = varargin{1} ;
            %                 n_preamble = varargin{2} ;
            %                 SyncKey = varargin{3} ;
            %             end

            packet = message;

            signal_prmb = LORA.modulate_symbol((SyncKey - 1).*ones(1,n_preamble),SF,BW,Fs,1) ; % preamble upchirps

            signal_sync_u = LORA.modulate_symbol([0 0],SF,BW,Fs,1) ; % sync upchirp

            signal_sync_d1 = LORA.modulate_symbol(0,SF,BW,Fs,-1) ; % header downchirp
            signal_sync_d = [signal_sync_d1; signal_sync_d1; signal_sync_d1(1:length(signal_sync_d1)/4)] ; % concatenate header

            signal_mesg = LORA.modulate_symbol(mod(packet + SyncKey-1,2^SF),SF,BW,Fs,1) ; % add sync key to payload messaage
            sig = [signal_prmb; signal_sync_u; signal_sync_d; signal_mesg] ; % concatenate LoRa packet
            pt = 0;
            signal_mod = 10.^(Pt./20).*sig.*exp(j.*2.*pi.*dF/Fs.*(0:length(sig)-1)).' ; % frquency shift and convert to power

            ana_struct.freq_offset = dF;
        end

        %%
        function signal_struct = analyze_signal_struct(sig,SF,BW,Fs)
            NPreamb = 8;
            M = 2^SF;
            N_sps = M*Fs/BW;
            signal_struct.PreampleStartInd = 1;
            signal_struct.ind_message_start = signal_struct.PreampleStartInd-1+(NPreamb + 4.25)*N_sps+1 ;
            signal_struct.Nmessage        = floor(length(sig)/N_sps - (signal_struct.ind_message_start-1)/N_sps) ;
            signal_struct.MessageEndInd   = signal_struct.Nmessage.*N_sps + signal_struct.ind_message_start-1 ;
        end


        %%
        function [sig message R ana_struct status] = demodulate_message(sig,SF,BW,Fs,Fs2,sig_name,correct_freq_offset)
            status = 0;
            if (nargin==4)
                sig_name = 'sig';
            end
            sig  = sig/max(abs(sig));

            if (nargin<7)
                correct_freq_offset = 0;
            end

            [ana_struct status] = LORA.analyze_signal(sig,SF,BW,Fs);if (status) return;end
            coarse_freq_offset = LORA.estimate_coarse_freq_offset(sig,ana_struct,Fs);
            
            if (correct_freq_offset)
                sig_coarse_freq_offset = LORA.correct_freq_offset(sig,coarse_freq_offset,Fs);
            else
                sig_coarse_freq_offset = sig;
            end

            [ana_struct status] = LORA.analyze_signal(sig_coarse_freq_offset,SF,BW,Fs);if (status) return;end
            fine_freq_offset = LORA.estimate_fine_freq_offset(sig,ana_struct,Fs);

            if (correct_freq_offset)
                sig_fine_freq_offset = LORA.correct_freq_offset(sig_coarse_freq_offset,fine_freq_offset,Fs);
            else
                sig_fine_freq_offset = sig_coarse_freq_offset;
            end

            ana_struct.coarse_freq_offset = coarse_freq_offset;
            ana_struct.fine_freq_offset = fine_freq_offset;


            sig_final = sig_fine_freq_offset;


            [symbols_mat symbols_sig] = LORA.split_signal_to_symbol_segments(sig_final,Fs2,Fs,ana_struct);
            [message R] = LORA.demodulate_symbol(symbols_mat,SF,BW,Fs2);



            %             %% down conversion ans sampling
            %             signal_demod = LORA.prepare_signal(sig,SF,BW,Fs);
            %
            %             %% divide the sig to pre-amble and message
            %             [pre_amble message] = LORA.split_signal_to_preamble_and_message(signal_demod,SF,BW,BW);
            %
            %
            %             signal_struct = LORA.analyze_signal_struct(signal_demod,SF,BW,BW);
            %
            %             pre_amble = signal_demod(signal_struct.PreampleStartInd:signal_struct.ind_message_start-1);
            %             message = signal_demod(signal_struct.ind_message_start:signal_struct.MessageEndInd);
            %             symbols_vec = LORA.split_signal_to_symbol_segments(message,SF,BW,BW,1);
            %             [message R] = LORA.demodulate_symbol(symbols_vec,SF,BW,BW);
            %
        end
        function [pre_amble message] = split_signal_to_preamble_and_message(sig,SF,BW,Fs)
            signal_struct = LORA.analyze_signal_struct(sig,SF,BW,Fs);
            pre_amble = sig(signal_struct.PreampleStartInd:signal_struct.ind_message_start-1);
            message = sig(signal_struct.ind_message_start:signal_struct.MessageEndInd);
        end

        %%
        function signal_demod = prepare_signal (sig,SF,BW,Fs,df)
            %             if (nargin==4)
            %                 df = 0;
            %             end
            %             signal_freq_demod   = sig.*exp(1j.*2.*pi.*df./Fs.*(0:length(sig)-1))' ;
            %             signal_filter       = lowpass(signal_freq_demod,BW,Fs) ;
            signal_demod = sig/max(abs(sig));
            signal_demod = resample(sig,BW,Fs);

        end
        %%
        function [symbols R] = demodulate_symbol(sig,SF,BW,Fs)
            %             if (size(sig,1)<size(sig,2))
            sig = sig.';
            %             end



            basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs,-1) ; % preamble upchirps

            for i = 1:size(sig,2)
                sig_beat_freq = sig(:,i).*basic_chirp(1:size(sig,1));
                %                 ind_mid = [1:1024]+round(length(sig_beat_freq)/2);
                R(:,i) = fft(sig_beat_freq);

                %                 R(:,i) = fft(sig(:,i).*basic_chirp(1:length(sig)));
                [~,idx] = max(abs(R(:,i)),[],1);
                symbols(i) = mod(idx-1 ,2^SF) ; % store symbol array
            end


            %             basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs,-1) ; % preamble upchirps
            %             basic_chirp_mat = repmat(basic_chirp,1,size(sig,1));
            %             R = fft(sig.*basic_chirp(1:length(sig)));
            %             [~,idx] = max(abs(R),[],1);
            %             symbols = mod(idx ,2^SF) ; % store symbol array
        end


        %%
        function [ind symbol_length status] = find_ind_start_message(sig,SF,BW,Fs,N)
            status = 0;
            basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs,1) ; % preamble upchirps
            sig = sig/max(abs(sig));
            [val loc] = xcorr(basic_chirp,sig);

            val = val/length(basic_chirp);
            MinPeakProminence = 0.9
            findpeaks(abs(val),loc,'MinPeakProminence',0.9,'Annotate','extents')
            [peaks locs] = findpeaks(abs(val),loc,'MinPeakProminence',0.9,'Annotate','extents');
            ind = -(locs(end-N+1));
            symbol_length = unique(diff(locs(end:-1:end-N+1)));
            if (length(symbol_length) ~=1)
                display(sprintf('Could not locate the end of preamble'))
                status = 6;displayFuncPath(dbstack); return;

            end


        end

        %%
        function [ana_struct status] = analyze_signal(sig,SF,BW,Fs)

            status = 0;
            ana_struct = struct;
            % generate basic chirp
            basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs,1) ; % preamble upchirps


            %% find the number of samples per symbol
            % normalize sig
            sig = sig/max(abs(sig));

            % perform correlation
            [val loc] = xcorr(basic_chirp,sig);

            % normalize correlation val
            val = val/length(basic_chirp);

            % find peaks
            MinPeakProminence = 0.9;
            %             figure;
            %             findpeaks(abs(val),loc,'MinPeakProminence',0.9,'Annotate','extents');
            [peaks_up locs_up] = findpeaks(abs(val),loc,'MinPeakProminence',0.9,'Annotate','extents');


            %% find the message start by correlating with negative chirp
            % perform correlation
            [val loc] = xcorr(conj(basic_chirp),sig);

            % normalize correlation val
            val = val/length(basic_chirp);

            % find peaks
            MinPeakProminence = 0.9;
            %             figure;
            %             findpeaks(abs(val),loc,'MinPeakProminence',0.5,'Annotate','extents');
            [peaks_down locs_down] = findpeaks(abs(val),loc,'MinPeakProminence',0.3,'Annotate','extents');

            locking_mode = 'down_chirp';
            switch locking_mode
                case 'down_chirp'
                    peaks = peaks_down;
                    locs = locs_down;
                    ana_struct.N_sps = diff(locs);
                    

                    ind_start_chirp = -(locs(2));
                case 'up_chirp'
                    peaks = peaks_up;
                    locs = locs_up;
                    ana_struct.N_sps = diff(locs);

                    ind_start_chirp = -(locs(2));

            end

            
            if (length(locs) ~= 2)
                display(sprintf('could not locate 2 opposite chirps'))
                status = 6;displayFuncPath(dbstack); return;
            end

% in case of simulated signal ana_struct.N_sps is length(basic_chirp)+1   
            ana_struct.N_sps = min(ana_struct.N_sps,length(basic_chirp));

            ana_struct.ind_message_start = round(ind_start_chirp+2.25*ana_struct.N_sps+1);
            ana_struct.N_preamble_symbols = floor(ana_struct.ind_message_start/ana_struct.N_sps);
            ana_struct.N_symbols = floor((length(sig)-ana_struct.ind_message_start)/ana_struct.N_sps);
            ana_struct.start_symbol_ind = ana_struct.ind_message_start+(1:ana_struct.N_sps:ana_struct.N_symbols*ana_struct.N_sps)-1;
            ana_struct.preamble_ind_vec = ana_struct.ind_message_start-[2.25 1.25 0.25]*ana_struct.N_sps;
            ana_struct.BW = LORA.calc_BW(sig,ana_struct,'Fs',Fs);
            ana_struct.basic_chirp = basic_chirp(1:ana_struct.N_sps);

            % [peaks locs] = findpeaks(angle(sig()),'MinPeakProminence',0.6,'Annotate','extents');
            for i = 1:length(ana_struct.start_symbol_ind)
                sig_temp = sig(ana_struct.start_symbol_ind(i)-100:ana_struct.start_symbol_ind(i)+100);
                %                 findpeaks(angle(sig_temp),'MinPeakProminence',0.6,'Annotate','extents')
                [peaks locs] = findpeaks(angle(sig_temp),'MinPeakProminence',0.6,'Annotate','extents');
                loc_final = locs(find(abs(peaks)<2.5));
                try
                    start_symbol_ind(i) = ana_struct.start_symbol_ind(i)-100+loc_final(1);
                    peaks_final(i,:) = peaks(find(abs(peaks)<2.5));

                catch
                    start_symbol_ind(i) = nan;
                end
            end
            ana_struct.start_symbol_ind_new = start_symbol_ind;

            %% get the BW
            L = 11;
            g = hanning(256);
            Ndft = 4096;
            x = spectrogram(sig,g,L,Ndft,Fs,'yaxis','centered');
            x = flipud(x);
            %             figure;image(abs(x))
            [val ind] = max(abs(x),[],1);
            ana_struct.BW_est = (max(ind)-min(ind))/Ndft*Fs;
            ana_struct.BW = BW;
            ana_struct.SF = SF;


            %             ana_struct.freq_offset = 3e3;

            %%
        end

        function [BW status] = calc_BW(sig,ana_struct,varargin)
            status = 0;
            defaultParams.Fs = 1;
            defaultParams.Ndft = 4096;
            defaultParams.L = 11;
            defaultParams.g = hanning(256);
            paramsLists = struct;

            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            %% parase parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

            [x f_t t status] = LORA.calc_freq_over_t(sig,lparams);if (status) return;end
            BW = max(f_t)-min(f_t);


            % % isolate the negative chirps
            %             for i = 1:2
            %                 start_ind
            %                 segment = f_t()
            %             end

        end

        %%
        function [message preamble ana_struct status] =  prepare_signal_for_analysis(sig,SF,BW,Fs,N_preamble_symbols)

            % chop zeros suffix
            ind  = find(abs(diff(sig))<1e-6);
            if (~isempty(ind))
                message = sig(1:ind);
            else
                ana_sig = sig;
            end

            % analyze siganl
            [ana_struct status] = LORA.analyze_signal(ana_sig,SF,BW,Fs,N_preamble_symbols);if (status) return;end

            % chop preamble
            message = ana_sig(ana_struct.ind_message_start:end);
            preamble = ana_sig(ana_struct.ind_message_start-ana_struct.N_sps*ana_struct.N_preamble_symbols:ana_struct.ind_message_start-1);

        end

        %%
        function [sig_clean status] = get_clean_signal(sig,ana_struct,N_preamble_symbols)
            status = 0;
            if (nargin==2)
                N_preamble_symbols = 3;
            end
            sig_clean = sig(ana_struct.ind_message_start-round((N_preamble_symbols+2.25)*ana_struct.N_sps):end);
            sig_clean = sig_clean/max(abs(sig_clean));

        end

        %%
        function [preamble status] = get_preamble(sig,ana_struct,N_preamble_symbols)
            status = 0;
            if (nargin==2)
                N_preamble_symbols = 3;
            end
            preamble = sig(ana_struct.ind_message_start-round((N_preamble_symbols+2.25+4)*ana_struct.N_sps):ana_struct.ind_message_start-round((N_preamble_symbols+2.25)*ana_struct.N_sps));

        end

        function [x_aux_line_ind] = get_x_aux_line_ind(ana_struct,mode)
            if (nargin==1)
                mode = 'clean';
            end
            x_aux_line_ind = [ana_struct.preamble_ind_vec ana_struct.start_symbol_ind];
            switch mode
                case 'clean'
                    x_aux_line_ind = x_aux_line_ind-x_aux_line_ind(1)+1;
                otherwise
                    x_aux_line_ind_pre_amble = x_aux_line_ind(1):-ana_struct.N_sps:1;
                    x_aux_line_ind = [x_aux_line_ind_pre_amble(1:end-1) x_aux_line_ind];
            end

        end

        %%
        function [sig_ADAFRUIT sig_SDR symbols_ADAFRUIT symbols_SDR status] = import_data_folder(in_dir,varargin)
            sig_ADAFRUIT = [];
            sig_SDR = [];
            symbols_ADAFRUIT = [];
            symbols_SDR = [];
            %% set params default vals and legal options

            %status = 6;displayFuncPath(dbstack); return;
            st = dbstack;funcname = st.name;
            defaultParams.mode = 'SDR_ADAFRUIT_comparison';
            paramsLists.mode = {'SDR_ADAFRUIT_comparison','create_symbols_for_SDR','check_SDR'};
            defaultParams.ADA_ind = [];
            defaultParams.SDR_ind = [];
            defaultParams.file_type = '.txt';
            paramsLists.file_type = {'.txt','.mat'};


            paramsStruct.defaultParams = defaultParams;
            paramsStruct.paramsLists = paramsLists;

            %% parse parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

            status = MANAGE.CheckExistance(in_dir);if (status) return;end

            test_name = FILE.GetFileNamePayLoad(in_dir);


            switch file_type
                case '.txt'
                    switch lparams.mode
                        case 'SDR_ADAFRUIT_comparison'
                            % get ADAFRUIT signal
                            [data_I status] = LORA.import_data_file([in_dir '\' test_name '_' 'ADAFRUIT' '_I.txt']);if (status) return;end
                            [data_Q status] = LORA.import_data_file([in_dir '\' test_name '_' 'ADAFRUIT' '_Q.txt']);if (status) return;end
                            sig_ADAFRUIT = data_I.VarName1+1j*data_Q.VarName1;

                            % get SDR signal
                            [data_I status] = LORA.import_data_file([in_dir '\' test_name '_' 'SDR' '_I.txt']);if (status) return;end
                            [data_Q status] = LORA.import_data_file([in_dir '\' test_name '_' 'SDR' '_Q.txt']);if (status) return;end
                            sig_SDR = data_I.VarName1+1j*data_Q.VarName1;

                            %                     % get ADAFRUIT symbols
                            %                     [symbols_ADAFRUIT status] = LORA.import_symbols_file([in_dir '\' test_name '_' 'ADAFRUIT' '_SYMBOLS.txt']);if (status) return;end
                            %
                            %                     % get SDR symbols
                            %                     [symbols_SDR status] = LORA.import_symbols_file([in_dir '\' test_name '_' 'SDR' '_SYMBOLS.txt']);if (status) return;end
                        case 'create_symbols_for_SDR'
                            % get ADAFRUIT signal
                            [data_I status] = LORA.import_data_file([in_dir '\' test_name '_' 'ADAFRUIT' '_I.txt']);if (status) return;end
                            [data_Q status] = LORA.import_data_file([in_dir '\' test_name '_' 'ADAFRUIT' '_Q.txt']);if (status) return;end
                            sig_ADAFRUIT = data_I.VarName1+1j*data_Q.VarName1;

                        case 'check_SDR'
                            % get ADAFRUIT signal
                            [data_I status] = LORA.import_data_file([in_dir '\' test_name '_' 'SDR' '_I.txt']);if (status) return;end
                            [data_Q status] = LORA.import_data_file([in_dir '\' test_name '_' 'SDR' '_Q.txt']);if (status) return;end
                            sig_SDR = data_I.VarName1+1j*data_Q.VarName1;


                        otherwise
                    end
                 case '.mat'
                     switch lparams.mode
                        case 'SDR_ADAFRUIT_comparison'
                            file_name = [in_dir '\' test_name '_ADA.mat'];
                            status = FILE.checkExistance(file_name);if (status) return;end
                            load (file_name);
                            sig_ADAFRUIT = Y;

                            file_name = [in_dir '\' test_name '_SDR.mat'];
                            status = FILE.checkExistance(file_name);if (status) return;end
                            load (file_name);
                            sig_SDR = Y;
                            


                     end
            end
            if (~isempty(ADA_ind))
                sig_ADAFRUIT = sig_ADAFRUIT(ADA_ind(1):ADA_ind(2));
            end

            if (~isempty(SDR_ind))
                sig_SDR = sig_SDR(SDR_ind(1):SDR_ind(2));
            end
            
        end
        %%
        function [symbols status] = import_symbols_file(filename, dataLines)
            %IMPORTFILE Import data from a text file
            %  symbols = IMPORTFILE(FILENAME) reads data from text file
            %  FILENAME for the default selection.  Returns the data as a cell array.
            %
            %  symbols = IMPORTFILE(FILE, DATALINES) reads data for the
            %  specified row interval(s) of text file FILENAME. Specify DATALINES as
            %  a positive scalar integer or a N-by-2 array of positive scalar
            %  integers for dis-contiguous row intervals.
            %
            %  Example:
            %  symbols = importfile("C:\gilad\work\matlab\branch_current\system_analysis\LORA\data\130223\010203040506_250_08_5_1_1_FAIL\010203040506_250_08_5_1_1_FAIL_ADAFRUIT_SYMBOLS.txt", [1, Inf]);
            %
            %  See also READTABLE.
            %
            % Auto-generated by MATLAB on 14-Feb-2023 11:17:10

            %% Input handling

            status = MANAGE.CheckExistance(filename);if (status) return;end
            % If dataLines is not specified, define defaults
            if nargin < 2
                dataLines = [1, Inf];
            end

            %% Set up the Import Options and import the data
            opts = delimitedTextImportOptions("NumVariables", 1);

            % Specify range and delimiter
            opts.DataLines = dataLines;
            opts.Delimiter = ",";

            % Specify column names and types
            opts.VariableNames = "x000";
            opts.VariableTypes = "char";

            % Specify file level properties
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";

            % Specify variable properties
            opts = setvaropts(opts, "x000", "WhitespaceRule", "preserve");
            opts = setvaropts(opts, "x000", "EmptyFieldRule", "auto");

            % Import the data
            symbols_pre = readtable(filename, opts);

            %% Convert to output type
            symbols_pre = table2cell(symbols_pre);
            numIdx = cellfun(@(x) ~isnan(str2double(x)), symbols_pre);
            symbols_pre(numIdx) = cellfun(@(x) {str2double(x)}, symbols_pre(numIdx));

            symbols = zeros(size(symbols_pre));
            for i = 1:length(symbols_pre)
                if (isnumeric(symbols_pre{i}))
                    symbols(i,:) = symbols_pre{i};
                else
                    symbols(i,:) = hex2dec(symbols_pre{i});
                end
            end

        end

        %%
        function [data status] = import_data_file(filename, dataLines)
            data = [];
            %IMPORTFILE Import data from a text file
            %  ADAFRUIT01COUNT16SF8BW500COUNT01TO16I = IMPORTFILE(FILENAME) reads
            %  data from text file FILENAME for the default selection.  Returns the
            %  data as a table.
            %
            %  ADAFRUIT01COUNT16SF8BW500COUNT01TO16I = IMPORTFILE(FILE, DATALINES)
            %  reads data for the specified row interval(s) of text file FILENAME.
            %  Specify DATALINES as a positive scalar integer or a N-by-2 array of
            %  positive scalar integers for dis-contiguous row intervals.
            %
            %  Example:
            %  data = importfile("C:\gilad\work\matlab\branch_current\system_analysis\LORA\Record11\ADAFRUIT_01_Count16_SF8_BW500_Count_01_To_16_I.txt", [1, Inf]);
            %
            %  See also READTABLE.
            %
            % Auto-generated by MATLAB on 25-Jan-2023 16:03:41

            status = MANAGE.CheckExistance(filename);if (status) return;end

            %% Input handling

            % If dataLines is not specified, define defaults
            if nargin < 2
                dataLines = [1, Inf];
            end

            %% Set up the Import Options and import the data
            opts = delimitedTextImportOptions("NumVariables", 1);

            % Specify range and delimiter
            opts.DataLines = dataLines;
            opts.Delimiter = ",";

            % Specify column names and types
            opts.VariableNames = "VarName1";
            opts.VariableTypes = "double";

            % Specify file level properties
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";

            % Import the data
            data = readtable(filename, opts);
            data = data.VarName1;

        end

        %%
        function [err_table] = compare_symbols(symbols1,symbols2)
            symbols1 = symbols1(:);
            symbols2 = symbols2(:);
            if length(symbols1) ~= length(symbols2)
                display(sprintf('length of symbols1 (%d) different than length of symbols2 (%d)',length(symbols1),length(symbols2)));
            end

            len  = min(length(symbols1),length(symbols2));
            symbols1 = symbols1(1:len);
            symbols2 = symbols2(1:len);
            err_table = table;
            ind = find(symbols1-symbols2);
            err_table.ind = ind;
            err_table.symbols1 = symbols1(ind);
            err_table.symbols2 = symbols2(ind);


        end


        %%
        function export_symbols_to_SDR(symbols,dir_name,varargin)
            %% set params default vals and legal options

            %status = 6;displayFuncPath(dbstack); return;
            st = dbstack;funcname = st.name;


            defaultParams = struct;
            paramsLists = struct;

            defaultParams.format = 'NSL'; % is a switch
            paramsLists.format = {'NSL','Keysight'}; % is a switch



            paramsStruct.defaultParams = defaultParams;
            paramsStruct.paramsLists = paramsLists;

            %% parse parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;
            file_name = [dir_name '\' FILE.GetFileNamePayLoad(dir_name) '_MATLAB_SYMBOLS.txt'];

            switch lparams.format
                case 'NSL'
                    hex_symbols = STR.StrArray2StrCellArray(dec2hex(symbols(:)));
                    hex_symbols = STR.addStrToCellArray('0x',hex_symbols,'begin');
                    writecell(hex_symbols,file_name);
                case 'Keysight'
                    [File status] = fopen(file_name,'w');
                    % header
                    for i = 1:8
                        fprintf(File,'%e,',0);
                    end
                    fprintf(File,'%e,',8);
                    fprintf(File,'%e,',16);
                    fprintf(File,'%e,',0);
                    fprintf(File,'%e,',0);

                    for i = 1:length(symbols)
                        if (i<length(symbols))
                            fprintf(File,'%e,',symbols(i));
                        else
                            fprintf(File,'%e',symbols(i));
                        end
                    end
                    fclose (File);

            end
        end

        %%
        function [SF BW Fs status] = parse_folder_name(folder_name)
            status = 0;
            folder_name = FILE.GetFileNamePayLoad(folder_name);

            ind_under_score = strfind(folder_name,'_');
            BW  = [];
            ind_under_score_start = 0;
            while isempty(BW)
                ind_under_score_start = ind_under_score_start+1;
                BW = str2num(folder_name(ind_under_score(ind_under_score_start)+1:ind_under_score(ind_under_score_start+1)-1));BW = BW*1e3;
            end
            SF = str2num(folder_name(ind_under_score(ind_under_score_start+1)+1:ind_under_score(ind_under_score_start+2)-1));
            Fs = str2num(folder_name(ind_under_score(ind_under_score_start+2)+1:ind_under_score(ind_under_score_start+3)-1));Fs = Fs*1e6;


        end

        %%
        function freq_est = estimate_coarse_freq_offset(sig,ana_struct,Fs)
            preamble = LORA.get_preamble(sig,ana_struct,0);
            preamble = preamble(1:round(length(preamble)/ana_struct.N_sps)*ana_struct.N_sps);

            %             preamble_ds = resample(preamble,ana_struct.BW,Fs);
            %             N_sps = round(ana_struct.N_sps*ana_struct.BW/Fs);
            symbols_mat = (reshape(preamble,ana_struct.N_sps,length(preamble)/ana_struct.N_sps)).';

            [symbols R] = LORA.demodulate_symbol(symbols_mat,ana_struct.SF,ana_struct.BW,Fs);
            freq_est = mean(symbols)/size(symbols_mat,2)*Fs/2;
        end

        %%
        function freq_est = estimate_fine_freq_offset(sig,ana_struct,Fs)
            freq_est = 0;

        end

        %%
        %         function freq_est = estimate_coarse_freq_offset(sig,ana_struct,Fs)
        %             [x f_t t status] = LORA.calc_freq_over_t(sig,[]);
        %             freq_est = mean(f_t)*Fs;
        % %             freq_est = 0;
        %         end

        %%
        function sig_corr = correct_freq_offset(sig,freq_offset,Fs)
            carrier_offset_sig = exp(-j*2*pi*freq_offset/Fs*(0:length(sig)-1));
            sig_corr = sig.*carrier_offset_sig.';
        end

        %%
        function chirp = get_chirp_from_signal(sig,SF,BW,Fs)
            sig = sig/max(abs(sig));
            basic_chirp = LORA.modulate_symbol(0,SF,BW,Fs);

            % perform correlation
            [val loc] = xcorr(basic_chirp,sig);

            % normalize correlation val
            val = val/length(basic_chirp);

            % find peaks
            MinPeakProminence = 0.9;
            %             figure;
            %             findpeaks(abs(val),loc,'MinPeakProminence',0.9,'Annotate','extents');
            [peaks_up locs_up] = findpeaks(abs(val),loc,'MinPeakProminence',0.9,'Annotate','extents');
            start_ind = ana_struct.ind_message_start-[3.25]*ana_struct.N_sps;
            end_ind = start_ind+ana_struct.N_sps-1;
            chirp = sig(start_ind:end_ind);
        end

        %%
        function full_corr_sig = get_full_corr_sig(sig,ana_struct)
            ref_sig = repmat(ana_struct.basic_chirp.',1, ana_struct.N_symbols);
            [symbols_mat symbols_sig] = LORA.split_signal_to_symbol_segments(sig,ana_struct);
            full_corr_sig = symbols_sig.* ref_sig';
        end

    end
end