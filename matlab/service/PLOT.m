classdef PLOT
    %PLOT Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)


        function [defaultParams paramsLists] = get_standard_plot_params()

            defaultParams.fig_name = 'signal';
            defaultParams.title_str = 'signal';
            defaultParams.axesH = [];
            defaultParams.legend = [];
            defaultParams.colors =[];
            defaultParams.line_style = '-';
            defaultParams.line_width = 1;
            defaultParams.x_grid = 'off'; % whether to add x grid
            defaultParams.y_grid = 'off'; % whether to add x grid
            defaultParams.x_label =[];
            defaultParams.y_label = [];
            defaultParams.yLim_val = [];
            defaultParams.xLim_val = [];
            defaultParams.fig_file_format = {'fig','png'};
            defaultParams.save_figure = 0;
            defaultParams.close_figure = 0;
            defaultParams.out_dir = [];
            defaultParams.marker = [];
            defaultParams.grid = 0;
            defaultParams.x_mark = [];  % x mark points
            defaultParams.y_mark = [];  % y mark points
            defaultParams.x_marker_color = [1 0 0];
            defaultParams.y_marker_color = [1 0 0];
            defaultParams.title_str = [];   % titles for all axes (cell array)
            defaultParams.side_str = [];   % text displayed on the side of the axes
            paramsLists.x_grid = {'on','off'};
            paramsLists.y_grid = {'on','off'};
            defaultParams.sub_plots_map = [];
            defaultParams.full_screen_before_save = 0;
            defaultParams.legend_en = 1;
            defaultParams.add_side_str = 1;
            defaultParams.ext_line_struct = [];
        end


        %%
        function str = prepareStrForPlot (str,type)
            if (nargin==1)
                type = 'title';
            end
            str = STR.str2Cell(str);
            for i = 1:length(str)
                if (~isempty(strfind(str{i},'\_')))
                    continue;
                else
                    switch (type)
                        case 'title'
                            str{i} = strrep (str{i},'_','\_');
                        case 'legend'
                            str{i} = strrep (str{i},'_','\_');
                    end
                end
            end
            if (length(str)==1)
                str = STR.cell2Str(str);
            end
        end


        %%
        function [axesH status] = plot_signal (signals,varargin)


            status = 0;
            fig_vec = [];
            %status = 6;displayFuncPath(dbstack); return;
            axesH = [];

            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;


            defaultParams.fig_name = 'signal';
            defaultParams.time_units = 'us';
            defaultParams.fig = [];
            defaultParams.fs = []; % sampling frequency. If empty taken as 1 for all signals. If a scalar, it is assigned to all signals. Otherwise should be in the length of signals
            defaultParams.legend = [];
            defaultParams.plot_ind = [];
            defaultParams.x_data_type = 'ind';
            defaultParams.colors =[];
            defaultParams.IQ = 'IQ';
            paramsLists.IQ = {'IQ','I','Q'};

            defaultParams.line_style = '-';
            defaultParams.line_width = 1;
            defaultParams.marker = [];

            defaultParams.x_grid = 'off'; % whether to add x grid
            defaultParams.y_grid = 'off'; % whether to add x grid
            defaultParams.x_scale = 'linear';   % x scale type
            defaultParams.y_scale = 'linear';   % y scale type
            defaultParams.x_label =[];
            defaultParams.y_label = 'amp[v]';
            defaultParams.x_data = [];
            defaultParams.yLim_val = [];
            defaultParams.xLim_val = [];
            defaultParams.axesH = [];
            defaultParams.delay = [];
            defaultParams.refresh = 0;
            defaultParams.fig_file_format = {'fig','png'};
            defaultParams.dec_factor = 1;   % decimation factor
            defaultParams.save_figure = 0;
            defaultParams.close_figure = 0;
            defaultParams.out_dir = [];
            defaultParams.x_mark = [];  % x mark points
            defaultParams.y_mark = [];  % y mark points
            defaultParams.x_marker_color = [1 0 0];
            defaultParams.y_marker_color = [1 0 0];
            defaultParams.title_str = [];   % titles for all axes (cell array)
            defaultParams.side_str = [];   % text displayed on the side of the axes
            defaultParams.y_aux_line = [];
            defaultParams.y_aux_line_color= [0 0 0];
            defaultParams.x_aux_line = [];
            defaultParams.x_aux_line_color= [0 0 0];
            defaultParams.display_grid = 'on';
            paramsLists.display_grid = {'on','off'};


            defaultParams.max_num_axeses = 5;


            paramsLists.x_grid = {'on','off'};
            paramsLists.y_grid = {'on','off'};
            paramsLists.x_scale = {'linear','log'};
            paramsLists.y_scale = {'linear','log'};

            paramsLists.time_units = {'s','ms','us','ns'};
            paramsLists.x_data_type = {'ind','time','custom'};
            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;


            %% parase parameters



            if (nargin==1)
                lparams = defaultParams;
            else
                % [lparams status] = ParseFunctionParams (mfilename,defaultParams,paramsLists,varargin);if (status) return;end
                [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            end
            create_lparams_vars;
            clear legend
            complexPlot = 0;


            if (isempty(signals))
                myDisplay(sprintf('empty plot_signals'));
                status = 6;displayFuncPath(dbstack); return;
            end





            if (isempty(marker))
                marker = 'none';
            end

            if (isempty(out_dir))
                out_dir = pwd;
            end


            if save_figure && (~exist(out_dir,'dir'))
                stat = mkdir(out_dir);
                if (~stat)
                    myDisplay(sprintf('%s: could not create %s',mfilename,out_dir));
                    status = 6;displayFuncPath(dbstack); return;
                end
            end

            if (~iscell(signals))
                temp = PLOT.apply_IQ(signals,IQ);
                clear signals;
                signals{1} = {temp};
            elseif (size(signals,1) == 1)
                if (~iscell(signals{1}))
                    temp = PLOT.apply_IQ(signals,IQ);
                    clear signals;
                    signals{1} = temp;
                end
            else
                for i = 1:size(signals,1)
                    if (~iscell(signals{i}))
                        temp = apply_IQ(signals{i},IQ);
                        signals{i} = {temp};
                    end
                end
            end



            if (~iscell(x_aux_line))
                x_aux_line = {x_aux_line};
            end


            % in the case of a single title make the axes title same is fig_name
            % if (size(signals,1)==1) && (isempty(title_str))
            %     title_str = fig_name;
            % end

            % get the total number of signals
            num_signals = 0;
            for i = 1:size(signals,1)
                %     for j = 1:length(signals{i})
                num_signals = num_signals+length(signals{i});
                %     end
            end

            if (isempty(fs))
                fs = ones(num_signals,1);
            elseif (length(fs)==1)
                fs = ones(num_signals,1)*fs;
            else
                status = check_input_length ('fs',fs,num_signals);if (status) return;end
            end

            % normalizing fs's
            fs_max = max(fs);
            fs_norm = fs/fs_max;
            fs_norm = fs_norm/min(fs_norm);
            fs_norm_max = max(fs_norm);
            ts_norm = 1./fs_norm;
            ts_norm = ts_norm/min(ts_norm);

            if (save_figure)
                if (isempty(out_dir))
                    myDisplay(sprintf('%s: empty out_dir',mfilename));
                    status = 6;displayFuncPath(dbstack); return;

                end
            end

            %% setting the time vector
            switch time_units
                case 's'
                    time_factor = 1;
                case 'ms'
                    time_factor = 1e3;
                case 'us'
                    time_factor = 1e6;
                case 'ns'
                    time_factor = 1e9;
            end



            % get the maximum signal length
            max_sig_length = 0;
            for i = 1:size(signals,1)
                for j = 1:length(signals(i))
                    max_sig_length = max(max_sig_length,length(signals{i}{j}));
                end
            end

            time = (0:max_sig_length*fs_norm_max)'/fs_max*time_factor;


            % apply dec_factor on time and signals

            time = time(1:dec_factor:end);


            for i = 1:size(signals,1)
                for j = 1:length(signals{i})
                    %         signals{i}{j} = resample(signals{i}{j},1,dec_factor);
                    signals{i}{j} = signals{i}{j}(1:dec_factor:end);
                end
            end


            % check for empty signal
            for i = 1:size(signals,1)
                for j = 1:length(signals(i))
                    if (isempty(signals{i}{j}))
                        signals{i}{j} = nan(length(time),1);
                        %             myDisplay(sprintf('%s: signal #(%d,%d) is empty',mfilename,i,j));
                        %             status = 6;displayFuncPath(dbstack); return;
                    end
                end
            end


            % set x label
            if (isempty(x_label))
                switch x_data_type
                    case 'ind'
                        x_label = ['time' '[' 'index' ']'];
                    case 'time'
                        x_label = ['time' '[' time_units ']'];
                    case 'custom'
                        x_label = lparams.x_label;
                end
            end

            %% determining xScale settings
            max_sig_length = 0;


            % if signals is a column vector make it a real vector
            if (size(signals,1)~=1)
                for i = 1:size(signals,1)
                    %     for j = 1:size(signals,2)
                    for j = 1:length(signals{i})
                        signals{i}{j} = real(signals{i}{j});
                    end
                end
            end

            %% refer to the complex case



            % determine if there is a complex signal
            for i = 1:size(signals,1)
                %     for j = 1:size(signals,2)
                for j = 1:length(signals{i})
                    if (~isreal(signals{i}{j}))
                        complexPlot = 1;
                        break;
                    end
                end
            end


            %% arrange titles
            if (complexPlot)
                clear temp;
                temp{1} = [title_str ' real'];
                temp{2} = [title_str ' imag'];
                title_str = temp;

            else
                title_str = STR.str2Cell(title_str);

            end

            side_str = STR.str2Cell(side_str);
            %% apply delay
            % set default delay if needed
            if (isempty(delay))
                delay = zeros(num_signals,1);
            end

            if (strcmp(x_data_type,'time'))
                delay = round(delay*fs_max);
            end



            % prerpare the signals
            sig_count = 0;
            for i = 1:size(signals,1)
                for j = 1:length(signals{i})
                    sig_count = sig_count+1;
                    % add delay
                    delayVec = nan(delay(sig_count),1);
                    signals{i}{j} = [delayVec;VEC.transVec(signals{i}{j},'column')];

                    % convert to complex
                    %                     signals{i}{j} = fixed2Complex(signals{i}{j});
                    max_sig_length = max(max_sig_length,length(signals{i}{j}));
                end
            end



            %% set the legends
            if (isempty(lparams.legend))
                lparams.legend = STR.addStrToCellArray('sig',STR.num2StrCellArray(1:num_signals),'begin');
            else
                lparams.legend = lparams.legend;
            end


            lparams.legend = STR.str2Cell(lparams.legend);


            for i = 1:length(lparams.legend)
                lparams.legend{i} = PLOT.prepareStrForPlot(lparams.legend{i});
            end


            if (length(lparams.legend) ~= sig_count)
                myDisplay(sprintf('%s:length of %s(%d) does not match signals number(%d)',mfilename,'legend',length(lparams.legend),sig_count));
                status = 6;displayFuncPath(dbstack); return;
            end

            %% re-calculate the time vector as the delay migh have changed the vectors
            % length
            time = (0:max_sig_length*fs_norm_max)'/fs_max*time_factor*dec_factor;


            % set the colors
            if (~isempty(lparams.colors))
                colors = [];
                for i = 1:size(signals,1)
                    axes_colors = lparams.colors;
                    temp = [];
                    for j = 1:length(signals{i})
                        temp{1,j} = axes_colors(j,:);
                    end
                    colors = cat (1,colors,{temp});
                end
            else
                colors = [];
                for i = 1:size(signals,1)
                    axes_colors = PLOT.createColors(length(signals{i}));
                    temp = [];
                    for j = 1:length(signals{i})
                        temp{1,j} = axes_colors(j,:);
                    end
                    colors = cat (1,colors,{temp});
                end
                %     end
            end

            if (isempty(fig_name))
                fig_name = '';
            end


            %% set the colors


            %% set the colors
            if (complexPlot)
                if (size(signals,1)~=1)
                    myDisplay(sprintf('%s: complex plot supports only a single line of signals',mfilename));
                    status = 6;displayFuncPath(dbstack); return;
                end

                colors1 = [];
                legend1 = [];
                % split the i'th signal into to 2 sub signals (I and Q)
                for i = 1:length(signals{1})
                    signals1{i} = real(signals{1}{i}) ;
                    signals2{i} = imag(signals{1}{i}) ;
                end

                % re-unite the 2 lists to a single one with 2 lines (one for each component/axes)
                signals = cat(1,{signals1},{signals2});
                ts_norm1 = repmat(ts_norm,1,2);
                colors1 = repmat(colors,2,1);
                legend1 = [STR.addStrToCellArray('(I)',lparams.legend,'end') STR.addStrToCellArray('(Q)',lparams.legend,'end')];



                ts_norm = ts_norm1;
                colors = colors1;
                lparams.legend = legend1;
            end


            if (complexPlot)
                delay = [delay delay];
            end

            % diveide the axeses between figures if necessary
            num_axeses = size(signals,1);

            num_figures = 1;
            if (~isempty(axesH))

                fig_vec = [];
                for i = 1:length(axesH)
                    if i==1
                        fig_vec{i} = axesH{i}.Parent;
                        fig_num_vec = axesH{i}.Parent.Number;
                    else
                        if (~ismember(axesH{i}.Parent.Number,fig_num_vec))
                            fig_ind = length(fig_vec)+1;
                            fig_vec{fig_ind} = axesH{i}.Parent;
                            fig_num_vec = [fig_num_vec axesH{i}.Parent.Number];
                        end
                    end


                end

            end



            sig_count = 0;

            % if axesH was not configured
            axes_cnt = 0;
            if (isempty(axesH))

                max_num_axeses = min(max_num_axeses,num_axeses);
                num_figures = ceil(num_axeses/max_num_axeses);

                for i = 1:num_figures
                    if (num_figures==1)
                        fig_name_post = fig_name;
                    else
                        fig_name_post = [fig_name '-' num2str(i)];
                    end

                    if (~isempty(lparams.fig))
                        fig_vec{i} = lparams.fig(i);
                    else
                        fig_vec{i} = figure('name',fig_name_post);

                    end
                end




                for k = 1:num_axeses
                    axes_cnt = mod(axes_cnt,max_num_axeses);
                    axes_cnt = axes_cnt+1;
                    current_figure_num = floor((k-1)/max_num_axeses)+1;
                    fig_vec{current_figure_num};
                    axesH{k} = subplot(max_num_axeses,1,axes_cnt);

                end
            else
                if (~iscell(axesH))
                    temp = axesH;
                    clear axesH;
                    axesH{1} = temp;
                end
                for k = 1:length(axesH)
                    axes(axesH{k});
                end

            end

            sub_plots_map = PLOT.get_sub_plots_map(length(axesH),[]);

            max_xAxis_val = 0;
            min_xAxis_val = inf;
            for k = 1:size(signals,1)
                if (strcmp(display_grid,'on'))
                    grid on
                end
                axes_signals = signals{k,:};
                plot_legend = [];
                for i = 1:length(axes_signals)
                    sig_count = sig_count+1;


                    plot_ind_base = 1:ts_norm(sig_count):length(axes_signals{i})*ts_norm(sig_count);

                    if (isempty(lparams.plot_ind))
                        firstDataInd = 1;

                        % get the index of the last non zero sample
                        lastDataInd = length(axes_signals{i});

                        plot_ind = plot_ind_base([firstDataInd:min(lastDataInd,length(plot_ind_base))]);

                    else
                        if (length(lparams.plot_ind)==2)
                            plot_ind = lparams.plot_ind(1):lparams.plot_ind(2);
                        else
                            plot_ind = lparams.plot_ind;
                        end

                    end



                    sig = axes_signals{i};
                    %                     [sig] = fixed2Real(sig);


                    % refer to the signal inds
                    y_plot_ind_1 = ceil((plot_ind(1)-1)/ts_norm(sig_count)+1);
                    y_plot_ind_2 = ceil((plot_ind(end)-1)/ts_norm(sig_count)+1);

                    y_plot_ind = y_plot_ind_1:y_plot_ind_2;

                    % refers to the x data inds
                    plot_ind_step = ts_norm(sig_count);
                    %         x_plot_ind =  plot_ind(1):plot_ind_step:plot_ind(2);
                    x_plot_ind = plot_ind;

                    % truncate the signal inds according to the length of the signal
                    sig_len = min([length(x_plot_ind) length(y_plot_ind) length(sig)]);
                    y_plot_ind = y_plot_ind(1:sig_len);
                    x_plot_ind = x_plot_ind(1:sig_len);

                    switch (x_data_type)
                        case 'ind'
                            x_data = x_plot_ind;
                        case 'time'
                            x_data = time(x_plot_ind);
                        case 'custom'
                            x_data = lparams.x_data;
                    end
                    % update the max_xAxis_val, holding the maximum x_axis value, used later for setting the xLim for all axeses
                    max_xAxis_val = max(max_xAxis_val,x_data(end));
                    min_xAxis_val = min(min_xAxis_val,x_data(1));

                    %         axesH{k}.setHandler('type','line','name',lparams.legend{sig_count},'color',colors{k}{i},'yData',real(sig(y_plot_ind)),'xData',x_data,'LineStyle',line_style,'Marker',marker,'LineWidth',line_width);
                    lineH = line('parent',axesH{k},'color',colors{k}{i},'yData',real(sig(y_plot_ind)),'xData',x_data,'LineStyle',line_style,'Marker',marker,'LineWidth',line_width);

                    plot_legend = cat (2,plot_legend,lparams.legend(sig_count));
                end

                % add legend
                axes(axesH{k})
                legend(plot_legend);

                if (~isempty(yLim_val))
                    axesH{k}.YLim = yLim_val;
                end

                if (~isempty(xLim_val))
                    axesH{k}.XLim = xLim_val;
                end

            end




            %% finalize axes
            for k = 1:size(signals,1)
                axes(axesH{k});

                % set the  xLim for all axeses
                if (isempty(xLim_val))
                    x_val_min = inf;
                    x_val_max = -inf;
                    for i = 1:length(axesH{k}.Children)
                        handler = axesH{k}.Children(i);
                        if (strcmp(handler.Type,'line'))
                            x_val_min = min(x_val_min,handler.XData(1));
                            x_val_max = max(x_val_max,handler.XData(end));
                        end
                    end


                    xlim ([x_val_min x_val_max]);
                else
                    xlim (xLim_val);
                end

                % add aux_lines
                for y_aux_val = y_aux_line
                    line ('xData',axesH{k}.XLim,'yData',[y_aux_line y_aux_line],'LineStyle','--');
                    axesH{k}.YTick = unique(sort([axesH{k}.YTick y_aux_val]));
                end

                aux_colors = [0 0 0;1 0 0];
                for num = 1:length(x_aux_line)
                    [x_data_mod y_data_mod] = PLOT.create_vertical_auxilery_grid_line(x_aux_line{num},axesH{k}.YLim);
                    line ('yData',y_data_mod,'xData',x_data_mod,'LineStyle','--','color',[aux_colors(num,:)]);
                end

                % set the title if configured
                if (~isempty(title_str))
                    title(PLOT.prepareStrForPlot(title_str{k}));
                end

                %   add markers
                if (~isempty(x_mark))
                    for m = 1:length(x_mark)
                        lineH = line('color',x_marker_color,'yData',axesH{k}.YLim,'xData',[x_mark(m) x_mark(m)],'LineStyle','--');

                    end

                    axesH{k}.XTick = unique(sort([axesH{k}.XTick x_mark(m)]));
                end


                if (~isempty(y_mark))
                    for m = 1:length(y_mark)
                        lineH = line('color',y_marker_color,'yData',axesH{k}.XLim,'xData',[y_mark(m) y_mark(m)],'LineStyle','--');

                    end

                    axesH{k}.YTick = unique(sort([axesH{k}.YTick y_mark(m)]));

                end



                xlabel(x_label);
                ylabel(y_label);



                % make the side_str for each axes a cell array
                max_num_side_str = 0;
                for i= 1:size(side_str,1)
                    if (~iscell(side_str{i}))
                        temp = side_str{i};
                        side_str{i} = {side_str{i}};
                    end
                    max_num_side_str = max(max_num_side_str,length(side_str{i}));
                end





                %% add side strings
                for j = 1:length(side_str)
                    sub_plots_map.side_str_height_total = 0.2;
                    side_str_height_pos = axesH{k}.Position(2)+axesH{k}.Position(4)-sub_plots_map.side_str_height_total;
                    side_str_left_pos = max(0.01,axesH{k}.Position(1)-0.3*(axesH{k}.Position(3)));
                    side_str_width = sub_plots_map.side_str_width;
                    side_str_height = sub_plots_map.side_str_height;



                    side_text_box = text;
                    side_text_box = uicontrol('style','text');
                    side_text_box.Units = 'normalized';
                    side_text_box.HorizontalAlignment = 'left';

                    side_str_bottom_pos = axesH{k}.Position(2)+axesH{k}.Position(4)-sub_plots_map.side_str_height_total*j;
                    if (~isnan(sub_plots_map.side_str_font_size))
                        set(side_text_box,'String',side_str{j},'position',[side_str_left_pos side_str_bottom_pos side_str_width side_str_height],'fontSize',sub_plots_map.side_str_font_size);
                    end
                end

            end


            %% add side strings







            % link the axes for zoom in
            for k = 1:length(axesH)
                axesH_vec(k) = axesH{k};
                ZoomHandle = zoom(axesH_vec(k));
                set(ZoomHandle,'Motion','horizontal')

            end
            linkaxes(axesH_vec,'x');




            %% add figure title
            % mTextBox = uicontrol('style','text');
            % mTextBox.Units = 'normalized';
            % set(mTextBox,'String',lparams.fig_name,'position',[0.1 0.925 0.902 0.08],'fontSize',12);

            out_dir = FILE.prepare_dir_name(out_dir);
            if (save_figure)
                if (~exist(out_dir))
                    mkdir(out_dir);
                end
                for j = 1:length(fig_vec)
                    fig_name = fig_vec{j}.Name;
                    if (isempty(fig_name))
                        myDisplay(sprintf('%s: cannot save figure, since fig_name is empty'));
                        return;
                    end

                    fig_file_name = prepare_dir_name([out_dir '\' prepareStr(fig_name)]);
                    fig_file_format = STR.str2Cell(fig_file_format);

                    for i  = 1:length(fig_file_format)
                        set(fig_vec{j}, 'InvertHardCopy', 'off');
                        saveas (fig_vec{j} ,fig_file_name,fig_file_format{i});
                    end

                    if (close_figure)
                        close(fig_vec{j});
                    end
                end
            end


        end






        %% function body


        function status = check_input_length (param_name,param,num_signals)
            status = 0;
            if (length(param) ~= num_signals)
                myDisplay(sprintf('%s: length of %s input (%d) does not match length of signals list (%d)','plot_signal',param_name,length(param),num_signals));
                status = 6;displayFuncPath(dbstack); return;
            end
        end





        function sig = apply_IQ(sig,IQ)
            if (~iscell(sig))
                switch (IQ)
                    case 'IQ'
                        sig = sig;
                    case 'I'
                        sig = real(sig);
                    case 'Q'
                        sig = imag(sig);
                end
            else
                for i = 1:length(sig)
                    switch (IQ)
                        case 'IQ'
                            sig{i} = sig{i};
                        case 'I'
                            sig{i} = real(sig{i});
                        case 'Q'
                            sig{i} = image(sig{i});
                    end
                end
            end

        end

        %%
        function [mp] = createColors(nca,varargin)
            %status = 6;displayFuncPath(dbstack); return;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;


            defaultParams.npa = [];
            defaultParams.pfa = [];
            defaultParams.exclude_colors = [];
            defaultParams.plot_graphs = 0;

            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            %% parase parameters
            if (nargin==1)
                lparams = defaultParams;
            else
                [lparams status] = ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            end
            create_lparams_vars;


            mp = PLOT.get_colors(nca,npa,pfa);

            %% if there are excluded colors check if they were chosen, and if needed re-choose
            num_gen = nca;
            mp_ext = [];
            while (size(mp_ext,1)<nca)
                ind_total = PLOT.check_colors(mp,exclude_colors);
                num_gen = num_gen+length(ind_total);

                if (~isempty(ind_total))
                    mp = get_colors(num_gen,npa,pfa);
                end

                ind_total = PLOT.check_colors(mp,exclude_colors);
                mp_ext = mp;
                mp_ext(ind_total,:) = [];
            end


            mp  = mp_ext(1:nca,:);

            if (lparams.plot_graphs)
                figure;

                for i = 1:nca
                    data = (1:100)*i;
                    plot(data,'color',mp(i,:));hold on;
                end
            end

        end


        %%
        function ind_total = check_colors(mp,exclude_colors)
            ind_total = [];
            if (~isempty(exclude_colors))
                mp_str = [];
                for i = 1:size(mp,1)
                    mp_str = cat(1,mp_str,STR.str2Cell(num2str(mp(i,:))));
                end

                exclude_colors_str = [];
                for i = 1:size(exclude_colors,1)
                    exclude_colors_str = cat(1,exclude_colors_str,STR.str2Cell(num2str(exclude_colors(i,:))));
                end


                ind_total = [];
                for i = 1:length(exclude_colors_str)
                    ind = findStringInCellArray(exclude_colors_str{i},mp_str);
                    if (~isempty(ind))
                        ind_total = cat(1,ind_total,ind);
                    end
                end
            end
        end

        %%
        function mp = get_colors(nca,npa,pfa)
            if (nca==1)
                mp = [0 0 1];
                return;
            end


            if (nca<=7)
                mpBase = [0 0 1;1 0 0;0 1 0;1 1 0;0 1 1;1 0 1;0 0 0];
                mp = mpBase (1:nca,:);
                return;
            end

            %ColorSpiral: Generates a monotonic colormap with maximum color depth
            %
            %   [m] = ColorSpiral(n,np,pf);
            %
            %   nc   Number of colors (length of the colormap). Default = 64.
            %   np   Number of sinusoidal periods. Default = 2.
            %   pf   Plot flag: 0=none (default), 1=screen.
            %
            %   m    Color map.
            %
            %   This function returns an n x 3 matrix containing the RGB entries
            %   used for colormaps in MATLAB figures. The colormap is designed
            %   to have a monotonically increasing intensity, while maximizing
            %   the color depth. This is achieved by generating a spiral through
            %   the RGB cube that ranges from RBG = [0 0 0] to RGB = [1 1 1].
            %
            %   Example: Create a world map of the GEOID datat with the new color
            %   scale.
            %      load geoid;
            %      figure;
            %      worldmap(geoid,geoidlegend);
            %      contourcmap([0:2.5:50],'ColorSpiral');
            %      h = colorbar('SouthOutside');
            %
            %   J. McNames, "An effective color scale for simultaneous color and
            %   gray-scale publications," IEEE Signal Processing Magazine, in
            %   press (January 2006).
            %
            %   Version 1.01 JM
            %
            %   See also colormap, jet, and caxis.

            %====================================================================
            % Error Checking
            %====================================================================
            nca = nca+1;
            if nargin<1,
                help ColorSpiral;
                return;
            end;

            %====================================================================
            % Process Function Arguments
            %====================================================================
            nc = 64;                                                   % Default number of colors in the colormap
            if exist('nca') & ~isempty(nca),
                nc = nca;
            end;

            np = 2;                                                    % Default number of sinusoidal periods
            if exist('npa') & ~isempty(npa),
                np = npa;
            end;

            pf = 0;                                                    % Default - no plotting
            if nargout==0,                                             % Plot if no output arguments
                pf = 1;
            end;
            if exist('pfa') & ~isempty(pfa),
                pf = pfa;
            end;

            nc = nc+1;

            %====================================================================
            % Preprocessing
            %====================================================================
            %wn = sqrt(3/8)*[0;triang(nc-2);0];                        % Triangular window function
            wn = sqrt(3/8)*Hyperbola(nc);                              % Hyperbolic window function
            a12 = asin(1/sqrt(3));                                     % First  rotation angle (radians)
            a23 = pi/4;                                                % Second rotation angle (radians)

            %====================================================================
            % Main Routine
            %====================================================================
            t = linspace(sqrt(3),0,nc).';                              % Independent variable
            r0 = t;                                                    % Initial red values = independent variable (t)
            g0 = wn.*cos(((t-sqrt(3)/2)*np*2*pi/sqrt(3)));             % Initial green values = real part of complex sinusoid
            b0 = wn.*sin(((t-sqrt(3)/2)*np*2*pi/sqrt(3)));             % Initial blue values = imaginary part of complex sinusoid

            [ag,rd] = cart2pol(r0,g0);                                 % Convert to RG polar coordinates
            [r1,g1] = pol2cart(ag+a12,rd);                             % First rotation & conversion back to cartesian coordiantes
            b1      = b0;

            [ag,rd] = cart2pol(r1,b1);                                 % Convert RB to polar coordinates
            [r2,b2] = pol2cart(ag+a23,rd);                             % Second rotation & conversion back to cartesian coordinates
            g2      = g1;

            %====================================================================
            % Postprocessing
            %====================================================================
            r  = max(min(r2,1),0);                                     % Make sure rotated color cubes don't excede the unit
            g  = max(min(g2,1),0);                                     % color cube boundaries due to finite-precision effects
            b  = max(min(b2,1),0);

            mp = [r g b];                                              % The final colormap matrix
            %remove the white
            mp = mp (2:end-1,:);
            mp = flipud(mp);

            %====================================================================
            % Plot Default Figure
            %====================================================================
            if pf,
                figure;
                h = plot([mp,sum(mp,2)/3]);
                set(h(1),'Color','r');
                set(h(2),'Color','g');
                set(h(3),'Color','b');
                set(h(4),'Color','k');
                set(h,'LineWidth',1.5);
                xlim([1 nc]);
                ylim([0 1]);
                box off;
                xlabel('Map Index');
                legend('Red','Green','Blue','Intensity');
                if nc<=256,                                            % MATLAB doesn't display colormaps with more than 256 colors correctly
                    colormap(mp);
                    colorbar;
                end;
                ylim([0 1.03]);
            end;

            %====================================================================
            % Process Return Arguments
            %====================================================================
            if nargout==0,                                             % If no output arguments, don't return anything.
                clear('mp');
            end;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Hyperbola Function
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function [y] = Hyperbola(x,ymaxa,pfa);
                %Hyperbola: Generates a hyperbolic window function
                %
                %   [y] = Hyperbola(x);
                %
                %   x    If scalar, window length. If vector, indices of window.
                %   ymax Maximum value of the window amplitude. Default = 0.95.
                %   pf   Plot flag: 0=none (default), 1=screen.
                %
                %   y    Window.
                %
                %   This function returns a vector that represents a hyperbolic
                %   window function. Visually, this is very similar to a triangular
                %   or tent window function. However, the hyperbola is analytic
                %   (all it's derivatives exist at all points) and has a rounded
                %   peak. The parameter ymax controls how rounded the peak is.
                %   This function is used in the ColorSpiral colormap to prevent
                %   a discontinuity at the midpoint of the colormap.
                %
                %   Example: Generate the spectrogram of an intracranial pressure
                %   signal using a Hyperbola window that is 45 s in duration.
                %
                %      load ICP.mat;
                %      icpd = decimate(icp,15);
                %      wl   = round(45*fs/15);
                %      Spectrogram(icpd,fs/15,Hyperbola(wl));
                %
                %   C. H. Edwards, D. E. Penney, "Calculus and Analytic Geometry,"
                %   2nd edition, Prentice-Hall, 1986.
                %
                %   Version 1.00 JM
                %
                %   See also triang, window, and ColorSpiral.

                %   See http://mathworld.wolfram.com/Hyperbola.html for details.

                %====================================================================
                % Process Function Arguments
                %====================================================================
                if length(x)==1,                                           % If is an integer, make it into an array
                    x = 1:x;
                end;

                ymax = 0.95;
                if exist('ymaxa') & ~isempty(ymaxa),
                    ymax = ymaxa;
                end;

                pf = 0;                                                    % Default - no plotting
                if nargout==0,                                             % Plot if no output arguments
                    pf = 1;
                end;
                if exist('pfa') & ~isempty(pfa),
                    pf = pfa;
                end;

                %====================================================================
                % Preprocessing
                %====================================================================
                a    = sqrt((1-ymax).^2/(1-(1-ymax).^2));                  % Pick a to obtain desired maximum
                xmin = min(x);
                xmax = max(x);
                xs   = 2*(x-xmin)/(xmax-xmin) - 1;                         % Scale so it ranges from -1 to 1
                nx   = length(x);

                %====================================================================
                % Main Routine
                %====================================================================
                y = 1-sqrt(xs.^2+a^2)/sqrt(1+a^2);                         % Constrained to range from 0 to ymax

                %====================================================================
                % Postprocessing
                %====================================================================
                y(y<0) = 0;                                                % Make sure y is not negatative due to finite precision effects
                y      = y(:);                                             % Convert into a column vector

            end
        end
        %%
        function [ sub_plots_map ] = get_sub_plots_map(N_sub_plots,varargin )
            %status = 6;displayFuncPath(dbstack); return;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;


            defaultParams.max_N_rows = [];
            defaultParams.max_N_cols = [];
            defaultParams.max_N_side_str = 4;
            defaultParams.square_map = 1;
            defaultParams.show = 0;
            defaultParams.side_str_margine = 0.01;

            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;

            %% parase parameters
            [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            create_lparams_vars;

            if (N_sub_plots==1)
                N_cols = 1;
                N_rows = 1;
            else
                switch square_map
                    case 0
                        if (isempty(max_N_cols))
                            if (isempty(max_N_rows))
                                N_rows = max(1,ceil(sqrt(N_sub_plots)));
                            else
                                N_rows = min(ceil(sqrt(N_sub_plots)),max_N_rows);
                            end

                            N_cols = ceil(N_sub_plots/N_rows);

                        else
                            N_cols = min(ceil(sqrt(N_sub_plots)),max_N_cols);
                            N_rows = ceil(N_sub_plots/N_cols);
                        end



                        if (N_cols*N_rows)<N_sub_plots
                            N_cols = N_cols+1;
                        end

                    case 1
                        N_rows = max(1,ceil(sqrt(N_sub_plots)));
                        N_cols = max(1,ceil(sqrt(N_sub_plots)));
                        if (N_cols*N_rows)<N_sub_plots
                            N_cols = N_cols+1;
                        end

                        N_rows = N_cols;
                        %     N_rows = N_cols;
                end
            end
            sub_plots_map.N_cols = N_cols;
            sub_plots_map.N_rows = N_rows;

            fig = figure;
            if (show)
                fig.Visible = 'on';
            else
                fig.Visible = 'off';

            end
            for i = 1:N_cols*N_rows
                axesH{i} = subplot(N_rows,N_cols,i);
                title(num2str(i));
            end


            if (N_cols==1)
                sub_plots_map.v_margine = nan;
                sub_plots_map.h_margine = nan;
            else
                sub_plots_map.v_margine = (axesH{1}.Position(2)-(axesH{N_cols+1}.Position(2)+axesH{N_cols+1}.Position(4)));
                sub_plots_map.h_margine = (axesH{2}.Position(1)-(axesH{1}.Position(1)+axesH{1}.Position(3)));
            end


            % [left bottom width height]
            sub_plots_map.left_margine = axesH{1}.Position(1);
            sub_plots_map.right_margine = axesH{N_cols}.Position(1)+axesH{N_cols}.Position(3);
            sub_plots_map.top_margine = axesH{1}.Position(2)+axesH{1}.Position(4);
            sub_plots_map.bottom_margine = axesH{N_cols*(N_rows-1)+1}.Position(2);


            sub_plots_map.side_str_width = min(sub_plots_map.left_margine,sub_plots_map.h_margine)-0.01;
            sub_plots_map.side_str_height_total = axesH{1}.Position(4)/(max_N_side_str+side_str_margine);
            sub_plots_map.side_str_height = sub_plots_map.side_str_height_total-side_str_margine;

            % sub_plots_map,start_height_pos = axesH{i}.Position(2)+axesH{i}.Position(4)-side_str_height_total;



            side_str{1} = 'kuk=0.5';
            side_str = repmat(side_str,4,1);


            if (N_cols==1)
                sub_plots_map.side_str_font_size = 8;
            elseif (N_cols==2)
                sub_plots_map.side_str_font_size = 7;
            elseif (N_cols==3)
                sub_plots_map.side_str_font_size = 5;
            else
                sub_plots_map.side_str_font_size = nan;
            end

            if (~isnan(sub_plots_map.side_str_font_size))
                for i = 1:N_cols*N_rows
                    side_str_height_pos = axesH{i}.Position(2)+axesH{i}.Position(4)-sub_plots_map.side_str_height_total;
                    side_str_left_pos = max(0.01,axesH{i}.Position(1)-0.3*(axesH{i}.Position(3)));
                    side_str_width = sub_plots_map.side_str_width;
                    side_str_height = sub_plots_map.side_str_height;

                    for j = 1:length(side_str)
                        side_text_box = text;
                        side_text_box = uicontrol('style','text');
                        side_text_box.Units = 'normalized';
                        side_text_box.HorizontalAlignment = 'left';

                        side_str_bottom_pos = axesH{i}.Position(2)+axesH{i}.Position(4)-sub_plots_map.side_str_height_total*j;

                        set(side_text_box,'String',side_str{j},'position',[side_str_left_pos side_str_bottom_pos side_str_width side_str_height],'fontSize',sub_plots_map.side_str_font_size);
                    end




                end



            end
            fig.Visible = 'on';
            close (fig);
        end

        %%
        function [x_data_mod y_data_mod] = create_vertical_auxilery_grid_line(x_data,y_data)
            x_data_mod = [];
            y_data_mod = [];
            for x = x_data
                x_data_mod = cat (2,x_data_mod,[x x nan]);
                y_data_mod = cat (2,y_data_mod,[y_data nan]);

            end
        end


        %%
        function [SIG F status] = plot_spectra (signals,varargin)

            %status = 6;displayFuncPath(dbstack); return;



            %% set params default vals and legal options
            paramsLists = struct;
            defaultParams = struct;

            defaultParams.units = [];
            paramsLists.units = {'Hz','KHz','MHz','GHz'};

            defaultParams.title_str = [];
            defaultParams.fig_name = 'spectra';
            defaultParams.figure = [];
            defaultParams.legend = [];
            defaultParams.axesH =[];
            defaultParams.axesObjQ =[];
            defaultParams.marker = [];
            defaultParams.colors =[];
            defaultParams.yLim_val = [];
            defaultParams.M = [];
            defaultParams.fs = 1;
            defaultParams.save_figure = 0;
            defaultParams.close_figure = 0;
            defaultParams.side_str = [];   % text displayed on the side of the axes

            defaultParams.out_dir = [];
            defaultParams.fig_file_format = {'fig','png'};
            defaultParams.f_range = [];
            defaultParams.W = [];
            defaultParams.D = [];
            defaultParams.xLim_val = [];
            defaultParams.LineWidth = [];
            defaultParams.h = [];
            defaultParams.h_legend = [];
            defaultParams.fs_h = [];
            defaultParams.legend_en = 1;
            defaultParams.ch_colors_table = [];
            defaultParams.display_grid = 'on';
            defaultParams.add_max_line = 0;
            paramsLists.display_grid = {'on','off'};
            defaultParams.vertical_line_freq_vec = []; % frequencies were vertical boundry lines are added (optional)
            defaultParams.vertical_line_freq_vec_thresh = 256;
            paramsStruct.paramsLists = paramsLists;
            paramsStruct.defaultParams = defaultParams;
            %% parase parameters


            if (nargin==1)
                lparams = defaultParams;
            else
                % [lparams status] = ParseFunctionParams (mfilename,defaultParams,paramsLists,varargin);if (status) return;end
                [lparams status] = PARSE.ParseFunctionParams (mfilename,paramsStruct,[],varargin);if (status) return;end
            end

            lparams.legend = STR.str2Cell(PLOT.prepareStrForPlot(lparams.legend));

            if (isempty(lparams.fs_h))
                lparams.fs_h = lparams.fs;
            end



            create_lparams_vars;


            if (isempty(title_str))
                title_str = fig_name;
            end



            complexPlot = 0;

            side_str = STR.str2Cell(side_str);


            if (~isempty(ch_colors_table))
                status = CheckStructFields(ch_colors_table,{'color','f1','f2'});if (status) return;end
            end


            % if the channle res is too high ignore vertical_line_freq_vec_thresh
            % if (length(vertical_line_freq_vec)>vertical_line_freq_vec_thresh)
            %     vertical_line_freq_vec = [];
            % end

            if (isempty(LineWidth))
                if (isempty(vertical_line_freq_vec))
                    LineWidth = 1;
                else
                    LineWidth = 2;
                end
            end

            if (isempty(ch_colors_table))
                ch_colors_table = table;
            end
            if (~iscell(signals))
                temp = signals;
                clear signals;
                signals{1} = {temp};
            elseif (size(signals,1) == 1)
                temp = signals;
                clear signals;
                signals{1} = temp;
            else
                for i = 1:size(signals,1)
                    if (~iscell(signals{i}))
                        temp = signals{i};
                        signals{i} = {temp};
                    end
                end
            end

            min_length = 0;
            for i = 1:length(signals)
                min_length = min(min_length,length(signals{i}));
            end


            if (isempty(lparams.W))
                lparams.W = hamming(max(min_length,1024));
            end





            if (isempty(marker))
                marker = 'none';
            end


            fs_axes = max(fs);
            if (isempty(units))
                if (fs_axes<1e3)
                    units = ['Hz'];
                elseif (1e3<=fs_axes && fs_axes<1e6)
                    units = ['KHz'];
                elseif (1e6<=fs_axes)
                    units = ['MHz'];
                elseif (1e9<=fs_axes)
                    units = ['GHz'];
                end
            end

            switch units
                case 'Hz'
                    df = 1;
                case 'KHz'
                    df = 1e3;
                case 'MHz'
                    df = 1e6;
                case 'GHz'
                    df = 1e9;
            end
            if ~isempty(xLim_val)
                xLim_val = xLim_val/df;
            end
            x_label = ['f' '[' units ']'];
            y_label = ['power[dB]'];


            num_signals = 0;
            for i = 1:size(signals,1)
                num_signals = num_signals+length(signals{i,:}) ;
            end


            % handle default legends
            % if (isempty(lparams.legend))
            %     lparams.legend = addStrToCellArray('sig',num2StrCellArray(1:num_signals),'begin');
            % else
            %     lparams.legend = lparams.legend;
            % end

            if (~isempty(lparams.colors))
                colors =lparams.colors;
            else
                colors = PLOT.createColors(num_signals);
            end




            % set the colors
            if (~isempty(lparams.colors))
                colors = [];
                for i = 1:size(signals,1)
                    axes_colors = lparams.colors;
                    temp = [];
                    for j = 1:length(signals{i})
                        temp{1,j} = axes_colors(j,:);
                    end
                    colors = cat (1,colors,{temp});
                end
            else
                %     if (complexPlot)
                %         colors = repmat(createColors(num_signals/2),2,1);
                %     else
                colors = [];
                for i = 1:size(signals,1)
                    axes_colors = PLOT.createColors(length(signals{i}));
                    temp = [];
                    for j = 1:length(signals{i})
                        temp{1,j} = axes_colors(j,:);
                    end
                    colors = cat (1,colors,{temp});
                end
                %     end
            end



            if (isempty(lparams.legend))
                legendStr = STR.addStrToCellArray('sig',STR.num2StrCellArray(1:num_signals),'begin');
            else
                legendStr = lparams.legend;
            end

            legendStr = STR.str2Cell(legendStr);





            clear legend
            complexPlot = 1;
            % if (isempty(lparams.yLim_val))

            % end

            axesH = lparams.axesH;
            if (isempty(axesH))
                fig = figure('name',fig_name);
                for k = 1:size(signals,1)
                    axesHI(k) = subplot(size(signals,1),1,k);
%                     axesObj{k} = AXES_OBJ;
%                     axesObj{k}.init('axesH',axesHI(k),'title','real');
                end

            else
%                 axesObj{1} = AXES_OBJ;
%                 axesObj{1}.init('axesH',axesH,'title','real');
            end
            sig_count = 0;

            sub_plots_map = PLOT.get_sub_plots_map(length(axesH),[]);

            for k = 1:size(signals,1)
                yLim_val_min(k) = inf;
                yLim_val_max(k) = -inf;
                yLim_val_max_no_DC(k) = -inf;
                axes(axesH(k));
                if (strcmp(display_grid,'on'))
                    grid on
                end
                %             for i = 1:length(signals)
                axes_signals = signals{k,:};

                plot_legend = [];
                for i = 1:length(axes_signals)
                    sig_count = sig_count+1;
                    sig = axes_signals{i};

                    % if sig is a scalar, continue
                    if (length(sig)==1)
                        continue;
                    end
                    [sig] = fixed2Complex(sig);
                    %                 sig = sig+j*100;
                    %         if (isempty(f_range))
                    my_pwelch_params = lparams;
                    if (length(fs)>1)
                        my_pwelch_params.fs = fs(i);
                        A = pow2db(fs(i)/max(fs));
                    else
                        my_pwelch_params.fs = fs;
                        A = 0;
                    end
                    [SIG F status] = my_pwelch(sig,my_pwelch_params);if (status) return;end
                    F = F/df;

                    %         else

                    %         end
                    plot_SIG_abs = 10*log10(abs(SIG));
                    plot_SIG_abs = plot_SIG_abs-A;

                    yLim_val_min(k) = min(yLim_val_min(k),min(plot_SIG_abs));
                    yLim_val_max(k) = max(yLim_val_max(k),max(plot_SIG_abs));
                    plot_SIG_abs_no_DC = plot_SIG_abs;
                    plot_SIG_abs_no_DC(floor(length(plot_SIG_abs)/2)+1+[-10:10]) = [];
                    yLim_val_max_no_DC(k) = max(yLim_val_max_no_DC(k),max(plot_SIG_abs_no_DC));
                    if (isempty(lparams.yLim_val))
                        yLim_val = [yLim_val_min(k) yLim_val_max(k)];
                    end

                    %         axesObj{k}.setHandler('type','line','name',legendStr{sig_count},'color',colors{k}{i},'yData',plot_SIG_abs,'xData',F,'LineStyle','-','Marker',marker,'YLim',yLim_val,'XLim',[min(F) max(F)]);
                    %         axesObj{k}.setHandler('type','line','name',legendStr{sig_count},'color',colors{k}{i},'yData',plot_SIG_abs,'xData',F,'LineStyle','-','Marker',marker);

                    line('yData',plot_SIG_abs,'xData',F,'LineStyle','-','Marker',marker,'color',colors{k}{i},'LineStyle','-','LineWidth',LineWidth)
                    %         xlim ([-fs_axes/2/df fs_axes/2/df]);
                    xlim([min(F) max(F)]);
                    %         if (~isempty(axesObj{k}.legends))
                    %             plot_legend = cat (2,axesObj{k}.legends.String,lparams.legend(sig_count));
                    %             axesObj{k}.setHandler('type','legend','name','legend','String',plot_legend);
                    %         end

                    if (~isempty(lparams.legend))
                        plot_legend = cat (2,plot_legend,lparams.legend(sig_count));
                    end

                end


                if (legend_en)
                    if (~isempty(lparams.legend))
                        legend(PLOT.prepareStrForPlot(plot_legend));
                    end
                end

                axesH(k).Title.String = PLOT.prepareStrForPlot(title_str);
            end

%             if (legend_en)
%                 if (~isempty(lparams.legend))
%                     for k = 1:length(axesH)
%                         axesObj{k}.setHandler('type','axes','name',lparams.legend{sig_count});
%                     end
%                 end
%             end



            %finalize axes
            for k = 1:size(signals,1)
                axesH = axesObj{k}.axesH;
                axes(axesH);
                if (~isempty(yLim_val) && (length(yLim_val)==2)) && (~any(abs(yLim_val)==inf)) && (diff(yLim_val) ~= 0)
                    ylim(yLim_val);
                end
                % set the  xLim for all axeses
                %     axesObj{k}.setHandler('type','axes','name',lparams.legend{sig_count},'xLim',[min_xAxis_val max_xAxis_val]);
                %     if ~isempty(lparams.legend)
                %         axesObj{k}.setHandler('type','axes','name',lparams.legend{sig_count},'xLabel',xlabel (x_label));
                %         axesObj{k}.setHandler('type','axes','name',lparams.legend{sig_count},'yLabel',ylabel (y_label));
                %     end

                xlabel (x_label);
                ylabel (y_label);
                %% color spectra segments
                for i = 1:height(ch_colors_table)
                    color_ind = find(F>=ch_colors_table.f1(i)/df & F<=ch_colors_table.f2(i)/df);
                    xColorData = F(color_ind);
                    yColorData = plot_SIG_abs(color_ind);

                    color_lineH_vec(i) = line('yData',yColorData,'xData',xColorData,'LineStyle','-','Marker',marker,'color',ch_colors_table.color(i,:),'LineStyle','-','LineWidth',LineWidth);
                end


                %% add vertical lines

                for i = 1:length(vertical_line_freq_vec)
                    linH = line('xdata',[vertical_line_freq_vec(i)/df vertical_line_freq_vec(i)/df],'ydata',axesObj{k}.axesH.YLim,'color',[0 0 0],'LineStyle','--','LineWidth',0.01);
                    if (legend_en)

                        if (~isempty(lparams.legend))
                            legend(PLOT.prepareStrForPlot(lparams.legend));
                        end
                    end
                end
                if (~isempty(xLim_val))
                    xlim(xLim_val);
                end



                if (legend_en)

                    if (~isempty(ch_colors_table))
                        % remove name duplicants
                        ind_vec = [];
                        for name = (unique(ch_colors_table.name(:)))'
                            filter = FILTER;
                            filter.AddLayer('name','x=',name);
                            [ind status] = FilterTable(ch_colors_table,filter,0);
                            ind_vec = [ind_vec;ind(1)];
                        end
                        legend(color_lineH_vec(ind_vec),ch_colors_table.name(ind_vec));
                    end
                end

                if (~isempty(axesH.Legend))
                    legend_pre = axesH.Legend.String;
                end
                if (add_max_line)
                    line ('ydata',[yLim_val_max_no_DC(k) yLim_val_max_no_DC(k)],'xData',xLim_val,'LineStyle','--');
                    YTick = sort([get(axesH,'YTick') yLim_val_max_no_DC(k)]);
                    axesH.YTick = YTick;
                end
                if (~isempty(axesH.Legend))

                    legend(legend_pre);
                end
                %% add filter if desired
                if (~isempty(h))
                    if (isstruct(h))
                        h_legend = fields(h);
                        for h_ind = 1:length(h_legend)
                            h_cell{h_ind} = h.(h_legend{h_ind});
                        end
                        h = h_cell;

                    else
                        % make the h a cell array of vectors in any case
                        if (~iscell(h))
                            h = {h};
                        end
                        h = h(:);

                        % take care of h_legends
                        if (isempty(h_legend))
                            if (length(h)==1)
                                h_legend = {'h'};
                            else
                                h_legend = num2StrCellArray(1:length(h));
                                h_legend = addStrToCellArray('h',h_legend,'begin');
                                h_legend = h_legend(:);
                            end
                        else
                            h_legend = STR.str2Cell(h_legend);
                        end

                        status = check_size_equality(h,h_legend,'h','h_legend');if (status) return;end
                    end

                    for h_ind = 1:length(h)

                        [H,f] = freqz(double(h{h_ind}),1,F,fs_h/df);
                        yyaxis right
                        plot(f,10*log10(abs(H)),'color',[0 0 0]);hold on
                        legendStr = cat(2,legendStr,PLOT.prepareStrForPlot(h_legend(h_ind)));
                        if (legend_en)
                            legend(legendStr)
                        end
                    end
                end
                % make the side_str for each axes a cell array
                max_num_side_str = 0;
                for i= 1:size(side_str,1)
                    if (~iscell(side_str{i}))
                        temp = side_str{i};
                        side_str{i} = {side_str{i}};
                    end
                    max_num_side_str = max(max_num_side_str,length(side_str{i}));
                end


                %% add side strings
                for j = 1:length(side_str)
                    sub_plots_map.side_str_height_total = 0.2;
                    side_str_height_pos = axesObj{k}.axesH.Position(2)+axesObj{k}.axesH.Position(4)-sub_plots_map.side_str_height_total;
                    side_str_left_pos = max(0.01,axesObj{k}.axesH.Position(1)-0.3*(axesObj{k}.axesH.Position(3)));
                    side_str_width = sub_plots_map.side_str_width;
                    side_str_height = sub_plots_map.side_str_height;



                    side_text_box = text;
                    side_text_box = uicontrol('style','text');
                    side_text_box.Units = 'normalized';
                    side_text_box.HorizontalAlignment = 'left';

                    side_str_bottom_pos = axesObj{k}.axesH.Position(2)+axesObj{k}.axesH.Position(4)-sub_plots_map.side_str_height_total*j;
                    if (~isnan(sub_plots_map.side_str_font_size))
                        set(side_text_box,'String',side_str{j},'position',[side_str_left_pos side_str_bottom_pos side_str_width side_str_height],'fontSize',sub_plots_map.side_str_font_size);
                    end
                end

            end










            if (isempty(out_dir))
                out_dir = pwd;
            end

            if (save_figure)
                if (~exist(out_dir,'dir'))
                    mkdir(out_dir);
                end

                fig_file_name = [out_dir '\' prepareStr(fig_name)];
                fig_file_format = STR.str2Cell(fig_file_format);
                for i  = 1:length(fig_file_format)
                    set(fig, 'InvertHardCopy', 'off');
                    saveas (fig ,fig_file_name,fig_file_format{i});
                end
            end

            if (close_figure)
                close(fig);
            end



        end
        %% function body







    end
end

