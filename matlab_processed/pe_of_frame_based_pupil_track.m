clc
clear all
close all

whicheye = input('Please enter left or right to choose eye: ','s')
rawfilepath = input('Enter raw_data location(such as /home/raw_data): ', 's');
processedpath = input('Enter processed_data location(such as /home/processed_data): ', 's');
outputFile = input('Enter output result location:','s');

% whicheye = 'left'; % select which eye to generate mask
% mkdir(['H:\processed_data\Pixel_error_evaluation\frame\',whicheye,'\']);
session_pattern_list = [1,2;2,1;2,2];  % select pattern and session with label
for user_num =  1:48  %(user_num = 1:48)
    for session_pattern = 1:3
        session = session_pattern_list(session_pattern,1);
        pattern = session_pattern_list(session_pattern,2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events read %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % DVS data folder
        path_folder = [rawfilepath,'\Data_davis\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
        % frame timestamp list
        [time_raw_png] = textread(fullfile(path_folder, 'frames\timestamps.txt'), '%f');
        %tobii eye tracker timestamp and reference read
        dir_folder = dir(fullfile(path_folder, 'frames\*.png*'));
        names_file = sort_nat({dir_folder.name}); % Name of each aps image
        % Read list of predict frame (obtained by frame-based Pupil Segmentation)
        path_folder_predict = [processedpath,'\Data_davis_predict\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
        dir_folder_predict = dir(fullfile(path_folder_predict, 'predict\*.gif*'));
        names_file_predict = sort_nat({dir_folder_predict.name});
        
        % The image frames of the DVS sensor sometimes fall out and need to be corrected
        for i = 1:length(time_raw_png)-1
            if time_raw_png(i)> time_raw_png(i+1)
                time_raw_png(i+1) = time_raw_png(i)+40*1000;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events read %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %tobii eye tracker timestamp and reference read
        [time_raw, d2x, d2y, d3x, d3y, d3z] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\session_',num2str(session),'_0_',num2str(pattern),'\gazedata.txt'], '%f %f %f %f %f %f');
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tobii and dvs( frame & event) time alignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [creation_time] = textread([rawfilepath,'\Data_davis\user',num2str(user_num),'\',whicheye,'\creation_time.txt'], '%f'); % DVS aedat4 file creation time
        
        [tobiisend] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\tobiisend.txt'], '%f'); %The pc time when the ttl signal is transmitted to tobii
        
        [tobiittl] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\tobiittl.txt'], '%f'); %The time when the tobii eye tracker receives the ttl signal
        
        label_time = (time_raw - tobiittl((session-1)*2+pattern)) * 1000000;
        time_diff = ((creation_time((session-1)*2+pattern)) - tobiisend((session-1)*2+pattern))* 1000000;
        
        png_time = time_raw_png - time_raw_png(1) + time_diff;
        png_time_start_ind = find(png_time >= 0, 1);
        
        % Reading manually marked ellipses by VGG Image Annotator: https://www.robots.ox.ac.uk/~vgg/software/via/via_demo.html
        ellipse_parameter = read_csv(rawfilepath,user_num,session,pattern,whicheye);
        find_manually_groundtruth = find((ellipse_parameter(:,1)~= 0));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        se = strel('disk',5); % A parameter of the morphological closure
        temp_y_list = []; %  Record updated pupil centre y save to list
        temp_x_list = []; %  Record updated pupil centre x save to list
        frame_pixel_error_list = []; 
        
        for i = 1:1:length(find_manually_groundtruth)-3
            
            labelled_indx = find_manually_groundtruth(i);
            I = imread(cell2mat(fullfile(path_folder_predict,'predict\', names_file_predict (labelled_indx)))); % Reading masks
            
            BW5=imclose(I,se); % Filling the infrared light reflection in the pupil with a morphological closure
            % kmeans denoising
            [aa,bb] = find(BW5 ==1);
            if ~isnan(aa) % Some masks do not have a pupil area(e.g. when the eyes are closed)
                [~, ~,~, D]=kmeans([aa,bb],1);
                distance_d = find(D>2.5*mean(D));
                drop_x =  aa(distance_d) ;
                drop_y = bb(distance_d) ;
                BW5(drop_x, drop_y )=0;
                [yind,xind] = find(BW5 == 1);  % Find the pixel in mask that represents the pupil
                
                BW5_edge=edge( BW5,'Canny');
                [y,x] = find(BW5_edge == 1);% Pupil edge detection
                center_xind = mean(xind);
                center_yind = mean(yind); % Calculate pupil centre position
                each_row = ellipse_parameter(labelled_indx,:);
                
                Cx = each_row(1); % manually_groundtruth pupil centre position
                Cy = each_row(2);
                
                frame_center_pixel_error = ((center_xind - Cx).^2+ (center_yind - Cy).^2).^0.5;  % pixel error in Euclidean distance
                frame_pixel_error_list(end+1) =  frame_center_pixel_error;
                
            end
        end
        
        matcell = [frame_pixel_error_list]';
        mean(matcell)
       if isempty(outputFile)
            save([processedpath ,'\Pixel_error_evaluation\frame\',whicheye,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');
        else
            outfile  = strcat(outputFile,'\Pixel_error_evaluation\frame\',whicheye);
            if exist(outfile, 'dir')
                disp('save results to '+outfile);
                save([outfile ,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');

            else
                mkdir(outfile);
                disp('The folder'+outfile+'has been created.');
                save([outfile ,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');
            end
        end

%       save(['H:\processed_data\Pixel_error_evaluation\frame\',whicheye,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');
        clearvars -except user_num  session  pattern whicheye session_pattern_list
        
    end
end
