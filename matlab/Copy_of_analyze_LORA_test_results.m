close all
clear
figure;

% 17 - measured
% 9 - cable
% 6 - NF
SNR_const = 17-9-6;
SNR_const_ADA = 19-9-6;
dopler  = 0;
ada = 1;

if (ada)
    dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results\adafruit';
elseif (~dopler)
    dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results\SDR';
else
    dir = 'C:\Users\gilad\OneDrive - nslcomm.com\Documents\gilad\work\projects\asaf\LORA\lora_test\results\SDR _dopler';
end


dir = 'W:\RnD Backup\gilad\results'


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

   [~,idx_sorted] = sortrows(tbl,{'TX_type','BW'},{'ascend', 'ascend'})
    

end

tbl = tbl(idx_sorted,:)

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
        if (~isempty(ind))
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
            parse_table = cat(1,parse_table,parse_table_line);
        end

    end

    parse_table = sortrows(parse_table,'SNR','descend');




    % plot
    if (ada)
        axesH = semilogy(parse_table.SNR,parse_table.PER,'marker','o','LineWidth',2,'color',colorStruct.(['BW_' num2str(BW) '_' 'SF_' num2str(SF)]));hold on
        legend_str = cat(1,legend_str,STR.str2Cell(['SF=' num2str(SF) ' ' 'BW=' num2str(BW) ' ' 'TX=' cell2mat(ADA_SDR(idx))]));
    elseif (~dopler)
        axesH = semilogy(parse_table.SNR,parse_table.PER,'marker',formatStruct.(['BW_' num2str(BW)]),'LineWidth',2,'color',colorStruct.(['SF_' num2str(SF)]));hold on
        legend_str = cat(1,legend_str,STR.str2Cell(['SF=' num2str(SF) ' ' 'BW=' num2str(BW)]));
    else
        axesH = semilogy(parse_table.SNR,parse_table.PER,'marker',formatStruct.(['BW_' num2str(BW)]),'LineWidth',2,'color',colorStruct.(['TX_' num2str(TX_type)]));hold on
        legend_str = cat(1,legend_str,STR.str2Cell(['BW=' num2str(BW) ' ' 'Fc=' num2str(TX/1000) '[MHz]']));
    end
end

legend_str = cat(1,legend_str,{'sensitivity PER'})
yline (0.1,'--')
legend(legend_str,'FontSize',8)
title ('PER vs. SNR')
xlabel('SNR[dB]')
ylabel('PER')
if (~dopler)
    xlim([-28 -12])
else
xlim([-28 -10])
end

grid minor


