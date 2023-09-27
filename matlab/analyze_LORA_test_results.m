close all
clear
figure;


dopler  = 0;
ada = 0;
measured_vs_embedded = 1;


% 17 - measured
% 9 - cable
% 6 - NF
% SNR_const = 17-9-6;
% SNR_const = 25-9-6-20;
PER_sensitivity = 0.1;
SNR_const_ADA = 19-9-6;
Pn = -114;
Ps_ASP = -63.8;

Pn = -109.4;
Ps_ASP = -68.05;

SNR_const = 41-40-6;
L_const = 40;
NF = 6;

SNR_const = Ps_ASP-Pn-L_const-NF;


% % 17 - measured
% % 9 - cable
% % 6 - NF
% % SNR_const = 17-9-6;
% % SNR_const = 25-9-6-20;
% SNR_const = 41-40-6;
% SNR_const_ADA = 19-9-6;
% dopler  = 0;
% ada = 0;
% measured_vs_embedded = 1;




% if (ada)
%     dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results\adafruit';
% elseif (~dopler)
%     dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results\SDR';
% else
%     dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results\SDR _dopler';
% end


dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results';



file_names = FILE.getFolderFileNames(dir,'fullPath');

legend_str = [];

idx = 0;
for file_name = file_names'
    idx = idx+1;
    file_name = STR.cell2Str(file_name);
    file_lines = readlines(file_name);
    parse_table = table;
    if (strfind(file_name,'_ada'))
        ADA_SDR(idx) = {'ADA'};
    else
        ADA_SDR(idx) = {'SDR'};
    end
    % parse
    for i = 1:length(file_lines)
        line = file_lines{i};
        ind = strfind(line,':');
        if (~isempty(ind))
            if (strfind(line,'bandwidth'))
                BW(idx) = str2num(line(ind+1:end-1));
            end

            if (strfind(line,'spreading_factor'))
                SF(idx) = str2num(line(ind+1:end-1));
            end

            if (strfind(line,'tx_frequency'))
                TX(idx) = str2num(line(ind+1:end-1));
            end

            if (strfind(line,'tx_frequency'))
                TX = str2num(line(ind+1:end-1));
                if (TX<915000 )
                    TX_type(idx) = 1;
                elseif(TX==915000 )
                    TX_type(idx) = 2;
                else
                    TX_type(idx) = 3;
                end
            end

        end
    end
end

tbl = table;
tbl.SF = SF(:);
tbl.BW = BW(:);
tbl.ADA_SDR = ADA_SDR(:);
tbl.TX_type = TX_type(:);

for i = 1:height(tbl)
    config{i,:} = ['BW_' num2str(tbl.BW(i)) '_' 'SF_' num2str(tbl.SF(i))];
end

tbl.config = config;
colors = PLOT.createColors(length(unique(tbl.config)));
if (ada)
config_types = unique(tbl.config);    
ind = 0;
for config_type = (unique(tbl.config))'
    ind = ind+1
    colorStruct.(cell2mat(config_type)) = colors(ind,:);
end

%     colorStruct.ADA  = [0 0 1];
%     colorStruct.SDR = [0 1 0];
%     [~,idx_sorted] = sortrows(tbl,{'ADA_SDR','SF','BW'},{'ascend','ascend', 'ascend'})
%     formatStruct.BW_125 = '*';
%     formatStruct.BW_250 = 'x';
%     formatStruct.BW_500 = 'o';


    colorStruct.SF_8  = [0 0 1];
    colorStruct.SF_10 = [0 1 0];
    colorStruct.SF_11 = [1 0 0];
   [~,idx_sorted] = sortrows(tbl,{'SF','BW','ADA_SDR'},{'ascend', 'ascend','ascend'});

elseif (~dopler)
    formatStruct.BW_125 = '*';
    formatStruct.BW_250 = 'x';
    formatStruct.BW_500 = 'o';


    colorStruct.SF_8  = [0 0 1];
    colorStruct.SF_10 = [0 1 0];
    colorStruct.SF_11 = [1 0 0];
   [~,idx_sorted] = sortrows(tbl,{'SF','BW'},{'ascend', 'ascend'})
 
else
    formatStruct.BW_125 = '*';
    formatStruct.BW_250 = 'x';
    formatStruct.BW_500 = 'o';


    colorStruct.TX_1  = [0 0 1];
    colorStruct.TX_2 = [0 1 0];
    colorStruct.TX_3 = [1 0 0];

   [~,idx_sorted] = sortrows(tbl,{'TX_type','BW'},{'ascend', 'ascend'});
    

end

tbl = tbl(idx_sorted,:);

RSSI_table = table;
RSSI_line = table;

for idx = idx_sorted.'
    file_name = file_names{idx}
    file_lines = readlines(file_name);
    parse_table = table;

    if (strfind(file_name,'_ada'))
        ADA_SDR(idx) = {'ADA'};
    else
        ADA_SDR(idx) = {'SDR'};
    end

    % parse
    for i = 1:length(file_lines)
        line = file_lines{i};
        ind = strfind(line,':');
        if (contains(line,'test ended') || (contains(line,'could not find')))
            continue
        
        elseif (~isempty(ind))
            if (strfind(line,'bandwidth'))
                BW = str2num(line(ind+1:end-1));
            end

            if (strfind(line,'spreading_factor'))
                SF = str2num(line(ind+1:end-1));
            end

            if (strfind(line,'tx_frequency'))
                TX = str2num(line(ind+1:end-1));
                if (TX<915000 )
                    TX_type = 1;
                elseif(TX==915000 )
                    TX_type = 2;
                else
                    TX_type = 3;
                end


            end


        elseif (~isempty(strfind(line,'=')))
            nodes = strsplit(line);
            parse_table_line = table;
            for j = 1:length(nodes)
                ind = strfind(nodes{j},'=');
                name = nodes{j}(1:ind-1);
                value = str2num(nodes{j}(ind+1:end));
                parse_table_line.(name) = value;
            end
            if strcmp(ADA_SDR{idx},'SDR')
                parse_table_line.SNR = SNR_const-parse_table_line.L;
            else
                parse_table_line.SNR = SNR_const_ADA-parse_table_line.L;
            end
            parse_table_line.SF = SF;
            parse_table_line.BW = BW;
            parse_table_line.RSSI = parse_table_line.SNR+Pn+NF;

            
            parse_table = cat(1,parse_table,parse_table_line);

        end

    end

    
    if (isempty(parse_table))
        continue
    end
    parse_table = sortrows(parse_table,'SNR','descend');


    RSSI_line.SF = SF;
    RSSI_line.BW = BW;
    [~,ind] = min(abs(parse_table.PER-PER_sensitivity));
    RSSI_line.RSSI = parse_table.RSSI(ind);
    RSSI_table = cat(1,RSSI_table,RSSI_line);
    
    % plot
    if (measured_vs_embedded)
        figure;
        semilogy(parse_table.SNR,parse_table.PER,'marker',formatStruct.(['BW_' num2str(BW)]),'LineWidth',2,'color',colorStruct.(['SF_' num2str(SF)]));hold on
        semilogy(parse_table.SNR_embedded,parse_table.PER,'marker',formatStruct.(['BW_' num2str(BW)]),'LineWidth',2,'color',[0 0 0]);hold on

        legend_str1 = [];
        legend_str1 = cat(1,legend_str1,STR.str2Cell(['SF=' num2str(SF(end)) ' ' 'BW=' num2str(BW(end)) ' (measured)']));
        legend_str1 = cat(1,legend_str1,STR.str2Cell(['SF=' num2str(SF(end)) ' ' 'BW=' num2str(BW(end)) ' (embedded)']));

        legend_str1 = cat(1,legend_str1,{'sensitivity PER'});
        yline (0.1,'--');
        legend(legend_str1,'FontSize',8);
        title ('PER vs. SNR');
        xlabel('SNR[dB]');
        ylabel('PER')
        legend (legend_str1)
        grid minor
        
        %
    else
        if (ada)
            axesH = semilogy(parse_table.SNR,parse_table.PER,'marker','o','LineWidth',2,'color',colorStruct.(['BW_' num2str(BW) '_' 'SF_' num2str(SF)]));hold on
            legend_str = cat(1,legend_str,STR.str2Cell(['SF=' num2str(SF) ' ' 'BW=' num2str(BW) ' ' 'TX=' cell2mat(ADA_SDR(idx))]));
        elseif (~dopler)
            if (TX_type ==2)
                axesH = semilogy(parse_table.SNR,parse_table.PER,'marker',formatStruct.(['BW_' num2str(BW)]),'LineWidth',2,'color',colorStruct.(['SF_' num2str(SF)]));hold on
                legend_str = cat(1,legend_str,STR.str2Cell(['SF=' num2str(SF) ' ' 'BW=' num2str(BW)]));
            end
        else
            axesH = semilogy(parse_table.SNR,parse_table.PER,'marker',formatStruct.(['BW_' num2str(BW)]),'LineWidth',2,'color',colorStruct.(['TX_' num2str(TX_type)]));hold on
            legend_str = cat(1,legend_str,STR.str2Cell(['BW=' num2str(BW) ' ' 'Fc=' num2str(TX/1000) '[MHz]']));
        end
    end

end


legend_str = cat(1,legend_str,{'sensitivity PER'});
yline (0.1,'--');
legend(legend_str,'FontSize',8);
title ('PER vs. SNR');
xlabel('SNR[dB]');
ylabel('PER')



%% RRSI measured vs. spec analysis
RSSI_table = groupsummary(RSSI_table, {'SF', 'BW'}, 'mean', 'RSSI');
RSSI_table = sortrows(RSSI_table,'BW');
RSSI_table.RSSI_spec = [-126 -132 -123 -128 -130 -119 -125 -128].';
RSSI_table.Symbol_length = 2.^RSSI_table.SF./RSSI_table.BW
figure;
axesH = axes;
plot(RSSI_table.mean_RSSI,'-*','color',[1 0 0],'linewidth',2);hold on;
plot(RSSI_table.RSSI_spec,'-*','color',[0 0 1],'linewidth',2);
legend ({'measured','spec'});
config_str = [];
for i = 1:height(RSSI_table)
    config_str = cat(1,config_str,{PLOT.prepareStrForPlot([num2str(RSSI_table.SF(i)) '_' num2str(RSSI_table.BW(i))])});
end
axesH.XTickLabel = config_str
set(gca, 'XTickLabelRotation', 45);
title('RRSI at sensitivity point :measured vs. spec')
ylabel(PLOT.prepareStrForPlot('RRSI[dBm]'));
xlabel(PLOT.prepareStrForPlot('mode [SF_BW]'))
% ylim([-138 -118])
%%



% if (~dopler)
%     xlim([-28 -12])
% else
% xlim([-28 -10])
% end





grid minor



