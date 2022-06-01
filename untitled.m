startFile = 80;
endFile = 80;

fid = fopen('htmau/fileList.txt', 'r');
i = 1;
while ~feof(fid)
    fscanf(fid, '%d ', 1); % skip the line count in the first column
    fileNames{i} = fscanf(fid, '%s ', 1);
    i = i+1;
end
fclose (fid);
%fprintf(1, '\n %d files to process in total', i);
close all;


min_val_longest_seq = zeros(4053,1);
below_min_val_longest_seq = zeros(4053,1);
max_val_longest_seq = zeros(4053,1);
above_max_val_longest_seq = zeros(4053,1);


predicted_val_seq = zeros(4053,1);
predicted_below_min_val = zeros(4053,1);
predicted_max_val = zeros(4053,1);
predicted_above_max_val = zeros(4053,1);

for i=startFile:endFile
    [~, name, ~] = fileparts(fileNames{i});
    load (sprintf('htmau/Output/HTM_SM_%s.mat', name));
    readData = importdata (sprintf('htmau/%s',fileNames{i}));
    %load(sprintf("matlabHTM/Output/HTM_SM_%s_L.mat",name));
    
    data_range = max(readData) - min(readData);
    step_value = data_range/(data.nBits(1)-21);
    running_value = min(readData);
    
    values_table = zeros(data.nBits(1),1);
        
    for k=1:data.nBits(1)
        values_table(k) = running_value + step_value;
        running_value = running_value + step_value;
    end
    
    scalar_encoding_reconstructions = SM.every_prediction*SP.synapse;
    [B,I] = maxk(scalar_encoding_reconstructions(:,1:data.nBits(1)),21,2);
      
    predicted_scr = sort(I,2);
    for j=1:size(predicted_scr,1)
        longuest_sequence = find(bwareafilt([0, diff(predicted_scr(j,:))] == 1, 1));
        if ~isempty(longuest_sequence)
            min_val_longest_seq(j) = predicted_scr(j,longuest_sequence(1))-1;
            below_min_val_longest_seq(j) = predicted_scr(j,longuest_sequence(1)) - find(predicted_scr(j,:)==min_val_longest_seq(j));
            max_val_longest_seq(j) = predicted_scr(j,max(longuest_sequence));
            above_max_val_longest_seq(j) = max_val_longest_seq(j) + (size(predicted_scr(j,:),2)-find(predicted_scr(j,:)==max_val_longest_seq(j)));
        else
            min_val_longest_seq(j) = round(mean(predicted_scr(j,:)));
            below_min_val_longest_seq(j) = round(mean(predicted_scr(j,:)));
            max_val_longest_seq(j) = round(mean(predicted_scr(j,:)));
            above_max_val_longest_seq(j) = round(mean(predicted_scr(j,:)));
        end
        
        predicted_val_seq(j,1) = values_table(min_val_longest_seq(j));
        predicted_below_min_val(j,1) = values_table(below_min_val_longest_seq(j));
        predicted_max_val(j,1) = values_table(max_val_longest_seq(j));
        predicted_above_max_val(j,1) = values_table(above_max_val_longest_seq(j));
    end
    
     predicted_val_seq = predicted_val_seq;

    csvwrite (sprintf('htmau/Output/predicted_value_HTM_SM_%s.csv', name),predicted_val_seq);
    
    
end