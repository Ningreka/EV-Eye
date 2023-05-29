clc
clear all
close all
whicheye = input('Please enter left or right to choose eye: ','s')
rawfilepath = input('Enter raw_data location(such as /home/raw_data): ', 's');
processedpath = input('Enter processed_data location(such as /home/processed_data): ', 's');
% whicheye = 'left'; % choose which eye to start tracking the pupil
alist = [1,2,3,4,5];
for user_num = 1:1 %(user_num = 1:48)
    for session = 1:1 %(session = 1:2)
        for pattern = 1:1 %(pattern = 1:2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events timestamp read %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % DVS data folder
            path_folder = [rawfilepath ,'\Data_davis\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
            % frame timestamp list
            [time_raw_png] = textread(fullfile(path_folder, 'frames\timestamps.txt'), '%f');
            % The image frames of the DVS sensor sometimes fall out and need to be corrected
            for i = 1:length(time_raw_png)-1
                if time_raw_png(i)> time_raw_png(i+1)
                    time_raw_png(i+1) = time_raw_png(i)+40*1000;
                end
            end
            % First timestamp of event
            [time_event_start] = textread(fullfile(path_folder, 'events\event_startime.txt'), '%f');
             % Read event data with timestamp 
            [time_raw_event,event_x,event_y,event_polarity] = textread(fullfile(path_folder, 'events\events.txt'),'%f %f %f %f ');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events timestamp read%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %tobii eye tracker timestamp and reference read
            [time_raw, d2x, d2y, d3x, d3y, d3z] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\session_',num2str(session),'_0_',num2str(pattern),'\gazedata.txt'], '%f %f %f %f %f %f');
            
            errorindex = find((d2y>1)|(d2y<0)|(d2x>1)|(d2x<0));
            d2x(errorindex) = 0;
            d2y(errorindex) = 0;
            d3x(errorindex) = 0;
            d3y(errorindex) = 0;
            d3z(errorindex) = 0;
            
            d2x = d2x * 1920;
            d2y = d2y * 1080; % 
            zero_none1 = find(d2x+d2y~=0);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tobii and dvs( frame & event) time alignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [creation_time] = textread([rawfilepath,'\Data_davis\user',num2str(user_num),'\',whicheye,'\creation_time.txt'], '%f'); % DVS aedat4 file creation time
            [tobiisend] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\tobiisend.txt'], '%f'); %The pc time when the ttl signal is transmitted to tobii
            [tobiittl] = textread([rawfilepath,'\Data_tobii\user',num2str(user_num),'\tobiittl.txt'], '%f'); %The time when the tobii eye tracker receives the ttl signal
            
            % PC time and tobii time aligned using ttl signals
            label_time = (time_raw - tobiittl((session-1)*2+pattern)) * 1000000; 
            time_diff = ((creation_time((session-1)*2+pattern)) - tobiisend((session-1)*2+pattern))* 1000000;
            
             
            % Check the event and frame to see which one happened first and use it as the starting point
            if time_raw_png(1)<time_raw_event(1)
                png_time = time_raw_png - time_raw_png(1) + time_diff;
                event_time = time_raw_event - time_raw_png(1) + time_diff;
                fprintf('png<event\n');
            else
                png_time = time_raw_png - time_raw_event(1) + time_diff;
                event_time = time_raw_event - time_raw_event(1) + time_diff;
                fprintf('event<png\n');
            end
            
            png_time_start_ind = find(png_time >= 0, 1);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tobii and dvs( frame & event) time alignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            temp_label_x_list = []; % tobii reference coordinates
            temp_label_y_list = [];
            temp_3dlabel_x_list = [];
            temp_3dlabel_y_list = [];
            temp_3dlabel_z_list = [];
            
            temp_y_list = [];
            temp_x_list = [];
            temp_timestamp_list = [];
            frame_or_event = [];
            sort_label_value_list = [];
            frame_or_event = [];
            pixel_num_list = [];
            
            %Load all pupil update results
            load([processedpath ,'\Frame_event_pupil_track_result\',whicheye,'\update_20_point_user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'])

            startobii = find(label_time>png_time(png_time_start_ind),1);
            
            
            parfor i = startobii: length(label_time)
                [sort_label_value, sort_label_ind] = min((abs(matcell(:,3) - (label_time(i))) / 1000)); % For each reference label find the closest pupil update result to it (including frame and events)
                
                temp_y_list(i) =  matcell(sort_label_ind,5); % the updated pupil centre y 
                temp_x_list(i) =  matcell(sort_label_ind,4); % the updated pupil centre x 
                temp_timestamp_list (i) =  matcell(sort_label_ind,3); % timestamp of each pupil update result
                frame_or_event (i) = matcell(sort_label_ind,6); % Is the record updated by frame or events
                pixel_num_list (i) = matcell(sort_label_ind,2); % the number of pixel points contained in the pupil area. Help with blink detection
                
                temp_label_x_list (i)  = (d2x(i)); 
                temp_label_y_list (i) = (d2y(i)); % tobii 2d reference 
                temp_3dlabel_x_list (i) = (d3x(i));
                temp_3dlabel_y_list (i) = (d3y(i));
                temp_3dlabel_z_list (i) = (d3z(i)); % tobii 3d reference 
                sort_label_value_list (i) = sort_label_value; % Time difference between tobii reference and pupil update result
                
            end
            
            matcell_with_reference = [ pixel_num_list', temp_timestamp_list',temp_x_list',temp_y_list',frame_or_event',temp_label_x_list', temp_label_y_list' , temp_3dlabel_x_list', temp_3dlabel_y_list', temp_3dlabel_z_list', sort_label_value_list'];
            % save(['H:\processed_data\Frame_event_pupil_track_result\',whicheye,'\update_20_point_with_reference_user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell_with_reference');

        end
    end
end