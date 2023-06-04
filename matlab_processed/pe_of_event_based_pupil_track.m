clc
clear all
close all
whicheye = input('Please enter left or right to choose eye: ','s')
rawfilepath = input('Enter raw_data location(such as /home/EV_Eye_dataset/raw_data): ', 's');
processedpath = input('Enter processed_data location(such as /home/EV_Eye_dataset/processed_data): ', 's');
outputFile = input('Enter output result location (if you press enter directly, the default path is ./EV_Eye_dataset/processed_data/Pixel_error_evaluation/frame):','s');
session_pattern_list = [1,2;2,1;2,2];  % select pattern and session with label
for user_num = 1:48 %(user_num = 1:48)
    for session_pattern = 1:1
        session = session_pattern_list(session_pattern,1);
        pattern = session_pattern_list(session_pattern,2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events read %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % DVS data folder
        path_folder = [rawfilepath ,'\Data_davis\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
        % frame timestamp list
        [time_raw_png] = textread(fullfile(path_folder, 'frames\timestamps.txt'), '%f');
        dir_folder = dir(fullfile(path_folder, 'frames\*.png*'));
        names_file = sort_nat({dir_folder.name}); % Name of each aps image
        % Read list of predict frame (obtained by frame-based Pupil Segmentation)
        path_folder_predict = [processedpath ,'\Data_davis_predict\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
        dir_folder_predict = dir(fullfile(path_folder_predict, 'predict\*.gif*'));
        names_file_predict = sort_nat({dir_folder_predict.name});
        
        % The image frames of the DVS sensor sometimes fall out and need to be corrected
        for i = 1:length(time_raw_png)-1
            if time_raw_png(i)> time_raw_png(i+1)
                time_raw_png(i+1) = time_raw_png(i)+40*1000;
            end
        end
        % First timestamp of event
        [time_event_start] = textread(fullfile(path_folder, 'events\event_startime.txt'), '%f');
        % Read event data
        [time_raw_event,event_x,event_y,event_polarity] = textread(fullfile(path_folder, 'events\events.txt'),'%f %f %f %f ');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events read %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %tobii eye tracker timestamp and reference read
        
        [time_raw, d2x, d2y, d3x, d3y, d3z] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\session_',num2str(session),'_0_',num2str(pattern),'\gazedata.txt'], '%f %f %f %f %f %f');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tobii and dvs( frame & event) time alignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        [creation_time] = textread([rawfilepath,'\Data_davis\user',num2str(user_num),'\',whicheye,'\creation_time.txt'], '%f'); % DVS aedat4 file creation time
        
        [tobiisend] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\tobiisend.txt'], '%f'); %The pc time when the ttl signal is transmitted to tobii
        
        [tobiittl] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\tobiittl.txt'], '%f'); %The time when the tobii eye tracker receives the ttl signal
        
        
        label_time = (time_raw - tobiittl((session-1)*2+pattern)) * 1000000;
        time_diff = ((creation_time((session-1)*2+pattern)) - tobiisend((session-1)*2+pattern))* 1000000;
        
        % Check the event and frame to see which one happened first and use it as the starting point
        if time_raw_png(1)<time_raw_event(1)
            png_time = time_raw_png - time_raw_png(1) + time_diff;
            event_time = time_raw_event - time_raw_png(1) + time_diff;
%             fprintf('png<event\n');
        else
            png_time = time_raw_png - time_raw_event(1) + time_diff;
            event_time = time_raw_event - time_raw_event(1) + time_diff;
%             fprintf('event<png\n');
        end
        png_time_start_ind = find(png_time >= 0, 1);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tobii and dvs( frame & event) time alignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Reading manually marked ellipses by VGG Image Annotator: https://www.robots.ox.ac.uk/~vgg/software/via/via_demo.html
        ellipse_parameter = read_csv(rawfilepath,user_num,session,pattern,whicheye);
        find_manually_groundtruth = find((ellipse_parameter(:,1)~= 0));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        se = strel('disk',5); % A parameter of the morphological closure
        temp_y_list = []; %  Record updated pupil centre y save to list
        temp_x_list = []; %  Record updated pupil centre x save to list
        event_pixel_error_list= [];
        
        for i = 2:length(find_manually_groundtruth)-2

            labelled_indx = find_manually_groundtruth(i);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Frame-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            I = imread(cell2mat(fullfile(path_folder_predict,'predict\', names_file_predict (labelled_indx-1)))); % Reading masks
            BW5=imclose(I,se); % Filling the infrared light reflection in the pupil with a morphological closure
            % kmeans denoising
            [aa,bb] = find(BW5 ==1);
            if ~isnan(aa) % Some masks do not have a pupil area(e.g. when the eyes are closed)
                [~, ~,~, D]=kmeans([aa,bb],1);
                distance_d = find(D>2.5*mean(D));
                drop_x =  aa(distance_d) ;
                drop_y = bb(distance_d) ;
                BW5(drop_x, drop_y )=0;
                [yind,xind] = find(BW5 == 1); % Find the pixel in mask that represents the pupil
                BW5_edge=edge(BW5,'Canny');
                [y,x] = find(BW5_edge == 1); % Pupil edge detection
                center_xind = mean(xind);
                center_yind = mean(yind); % Calculate pupil centre Coordinate position
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Frame-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Event-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
                radius =  mean(((y - center_yind).^2  + (x - center_xind).^2).^0.5);  %We denote the averaged distance for all pixels of pupil edge as radius
                start_index = find(event_time>=png_time(labelled_indx -1),1); %Find the first event point larger than the current frame
                end_event_time = png_time(labelled_indx);  %Find the timestamp of the last event point before the next frame as the event-based pupil centre update cut-off point 
                
                A_x = []; % candidate point set
                A_y = [];
                event_time_list = [];  % Record the timestamp of event point in the candidate point set
                y_list = [];
                x_list = [];
                event_timestamp = 0;
                
                for k = 1:1000000000  
                    % Constructing candidate point sets
                    contain_index = start_index+k-1;   
                    event_x_candidate =  event_x( contain_index) ;
                    event_y_candidate =  event_y( contain_index) ;
                    event_time_candidate = event_time(contain_index);
                    
                    if((radius*0.80<(((event_y_candidate - center_yind).^2  + (event_x_candidate - center_xind).^2).^0.5))&((((event_y_candidate - center_yind).^2  + (event_x_candidate - center_xind).^2).^0.5)<radius*1.2))
                        event_time_list(end+1) = event_time_candidate;
                        A_x (end+1) =  event_x_candidate;
                        A_y (end+1) =  event_y_candidate;
                    end
                    
                    if length(A_x)>=20
                        P = [A_x; A_y]';
                        Q  = [x,y];
                        Ts = calculate_optimal_translation(P,Q);
                        
                        update_factor = 0.3;
                        x =  (1-update_factor)*x + (x - Ts(1))*update_factor ;% pupil edge update
                        y =  (1-update_factor)*y + (y - Ts(2))*update_factor ;
                        center_xind = center_xind - Ts(1)*update_factor; %pupil center update
                        center_yind = center_yind - Ts(2)*update_factor;
                        
                        event_timestamp = mean(event_time_list); % If the event point timestamp is greater than the location of the next frame, then the event update is skipped
                        x_list(end+1) =center_xind;
                        y_list(end+1) =center_yind;

                        A_x = []; % Clear the candidate point set
                        A_y = [];
                        event_time_list = [];
                    end
                    
                    if  event_timestamp>=end_event_time
                        break
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Event-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                each_row = ellipse_parameter(labelled_indx,:);
                Cx = each_row(1); % manually_groundtruth pupil centre position
                Cy = each_row(2);
                
                if ~isnan(x_list)>0
                    event_center_pixel_error = (( Cx- x_list(end)).^2+ ( Cy- y_list(end)).^2).^0.5; % pixel error in Euclidean distance
                    event_pixel_error_list(end+1) =  event_center_pixel_error;
                end
            end
        end
        matcell = [event_pixel_error_list]';
        mean(event_pixel_error_list);
        if isempty(outputFile)
            save([processedpath ,'\Pixel_error_evaluation\event\',whicheye,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');
        else
            outfile  = strcat(outputFile,'\Pixel_error_evaluation\event\',whicheye);
            if exist(outfile, 'dir')
                disp('save results to'+outfile);
                save([outfile ,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');

            else
                mkdir(outfile);
                disp('The folder'+outfile+'has been created.');
                save([outfile ,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');
            end
        end

        clearvars -except user_num  session  pattern whicheye session_pattern_list
        
    end
end
