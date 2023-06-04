clc
clear all
close all
rawfilepath = input('Enter raw_data location(such as /home/raw_data): ', 's');
processedpath = input('Enter processed_data location(such as /home/processed_data): ', 's');
whicheye = input('Please enter left or right to choose eye: ','s')
for user_num = 3:3 %user(1-48)
    for session = 1:2
        for pattern = 1:2
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%DVS frame & events read %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % DVS data folder
            path_folder = [rawfilepath,'\Data_davis\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
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
            
            [time_raw, d2x, d2y, d3x, d3y, d3z] = textread([rawfilepath ,'\Data_tobii\user',num2str(user_num),'\session_',num2str(session),'_0_',num2str(pattern),'\gazedata.txt'], '%f %f %f %f %f %f');
            
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
%                 fprintf('png<event\n');
            else
                png_time = time_raw_png - time_raw_event(1) + time_diff;
                event_time = time_raw_event - time_raw_event(1) + time_diff;
%                 fprintf('event<png\n');
            end
            png_time_start_ind = find(png_time >= 0, 1);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tobii and dvs( frame & event) time alignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%start pupil tracking%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            se = strel('disk',5);  % A parameter of the morphological closure
            temp_y_list = []; %  Record updated pupil centre y save to list
            temp_x_list = []; %  Record updated pupil centre x save to list
            temp_timestamp_list = []; % Record the timestamp of each update
            frame_or_event = []; % Is the record updated by frame or events?
            timeinterval_list = []; % Record tSave update resultshe time interval between the first point and the last point of the candidate point set
            pixel_num_list = []; % Calculate the number of pixel points contained in the pupil area. Help with blink detection
            q = 1; % Count the number of pupil updates
            
            if (length(names_file) == length(names_file_predict)) % Checking the number of predict masks against the original image
                for i = png_time_start_ind+1000:1:length(png_time) - 200
                    I_raw = imread(cell2mat(fullfile(path_folder,'frames\', names_file(i))));
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Frame-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    I = imread(cell2mat(fullfile(path_folder_predict,'predict\', names_file_predict(i)))); % Reading masks
                    BW5=imclose(I,se); % Filling the infrared light reflection in the pupil with a morphological closure
                    % kmeans denoising
                    [aa,bb] = find(BW5 ==1);
                    if ~isnan(aa) % Some masks do not include the pupil area (e.g. when the eyes are closed)
                        [~, ~,~, D]=kmeans([aa,bb],1);
                        distance_d = find(D>2.5*mean(D));
                        drop_x =  aa(distance_d) ;
                        drop_y = bb(distance_d) ;
                        BW5(drop_x, drop_y)=0;
                        [yind,xind] = find(BW5 == 1); % Find the pixel in mask that represents the pupil
                        
                        pixel_num_list(end+1) = length(yind); % Record the number of pixels contained in the pupil area
                        
                        BW5_edge=edge(BW5,'Canny');
                        [y,x] = find(BW5_edge == 1);% Pupil edge detection
                        
                        center_xind = mean(xind);
                        center_yind = mean(yind);  % Calculate pupil centre Coordinate position
                        
                        temp_y_list(end+1) = center_yind;
                        temp_x_list(end+1) = center_xind;
                        temp_timestamp_list (end+1) = png_time(i); % Record the timestamp of the current update (frame)
                        frame_or_event (end+1) = 1; % indicates that this update is based on the frame
                        timeinterval_list (end+1) = 0; %  frame does not contain a candidate point set
                        q = q +1; % Record the number of updates
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Frame-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        figure(1)
                        imshow(I_raw,'InitialMagnification','fit')
                        hold on
                        scatter(x,y ,20, '.','MarkerFaceColor','r','MarkerEdgeColor', 'y')
                        title('frame','FontSize',16,'Color','k','FontWeight','bold')
                        hold off
                        
                        
                        figure(2)
                        plot(q,center_xind  ,'xr','linewidth',3)
                        title('pupil center x','FontSize',16,'Color','k','FontWeight','bold')
                        hold on
                        set(gca,'YLim',[ 0 346]);
                        figure(3)
                        plot(q,center_yind ,'xr','linewidth',3)
                        title('pupil center y','FontSize',16,'Color','k','FontWeight','bold')
                        set(gca,'YLim',[ 0 260]);
                        hold on
                        
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Event-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        radius =  mean(( (y - center_yind).^2  + (x - center_xind).^2).^0.5); %We denote the averaged distance for all pixels of pupil edge as radius
                        
                        start_index = find(event_time>=png_time(i),1); %Find the first event point larger than the current frame
                        end_event_time = png_time(i+1); %Find the last event point before the next frame as the event-based pupil centre update cut-off time
                        
                        A_x = []; % candidate point set
                        A_y = [];
                        event_time_list = []; % Record the timestamp of event point in the candidate point set
                        
                        for k = 1:1000000000
                            % Constructing candidate point sets
                            contain_index = start_index+k-1;
                            event_x_candidate =  event_x(contain_index) ;
                            event_y_candidate =  event_y(contain_index) ;
                            event_time_candidate = event_time(contain_index);
                            if((radius*0.8<(((event_y_candidate - center_yind).^2  + (event_x_candidate - center_xind).^2).^0.5))&((((event_y_candidate - center_yind).^2  + (event_x_candidate - center_xind).^2).^0.5)<radius*1.2))
                                event_time_list(end+1) = event_time_candidate;
                                A_x (end+1) =  event_x_candidate;
                                A_y (end+1) =  event_y_candidate;
                            end
                            if length(A_x)>=20
                                P = [A_x; A_y]'; %candidate point sets
                                Q  = [x,y]; % Pupil edge
                                Ts = calculate_optimal_translation(P,Q);
                                
                                update_factor = 1;
                                x =  (1-update_factor)*x + (x - Ts(1))*update_factor ;% pupil edge update
                                y =  (1-update_factor)*y + (y - Ts(2))*update_factor ;
                                center_xind = center_xind - Ts(1)*update_factor; %pupil center update
                                center_yind = center_yind - Ts(2)*update_factor;
                                
                                event_timestamp = mean(event_time_list); % Take the average of the timestamps of all candidate points as the current update timestamp
                                temp_y_list(end+1) = center_yind; % Save event update results
                                temp_x_list(end+1) = center_xind;
                                temp_timestamp_list (end+1) = event_timestamp ;
                                frame_or_event (end+1) = 0;
                                timeinterval_list (end+1) = event_time_list(end) - event_time_list(1);
                                pixel_num_list(end+1) = length(yind); %  Record the number of pixels contained in the pupil area, consistent with frame
                                q = q +1;
                                
                                figure(2)
                                plot( q,center_xind  ,'.b','linewidth',3)
                                set(gca,'YLim',[ 0 346]);
                                figure(3)
                                plot( q,center_yind  ,'.b','linewidth',3)
                                set(gca,'YLim',[ 0 260]);
                                
                                
                                figure(4)
                                scatter(A_x,A_y ,20, '.','MarkerFaceColor','r','MarkerEdgeColor', 'r')
                                hold on
                                scatter(x,y ,20, '.','MarkerFaceColor','r','MarkerEdgeColor', 'b')
                                set(gca,'yLim',[ 0 260]);
                                set(gca,'xLim',[ 0 346]);
                                title('events','FontSize',16,'Color','k','FontWeight','bold')
                                hold off
                                
                                
                                A_x = []; % Clear the candidate point set
                                A_y = [];
                                event_time_list = [];
                            end
                            if event_time_candidate>=end_event_time % If the event point timestamp is greater than the location of the next frame, then the event update is skipped
                                break
                            end
                            
                        end
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Event-based pupil centre update%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    end
                    
                end
                
                % Save update results
                matcell = [timeinterval_list;pixel_num_list;temp_timestamp_list ;temp_x_list ;temp_y_list; frame_or_event ]';
                % save(['E:\update_result\our_methods\0.7\',whicheye,'\kmeans_update_20_point_user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat'], 'matcell');

                clearvars -except user_num  session  pattern
                
                
            else
                fprintf('error!!!!!!!!!!');
            end
            
        end
    end
end