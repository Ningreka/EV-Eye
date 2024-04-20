clc
clear all
close all

anglerror =[];
distance_list= [];
x_distance = [];
y_distance = [];

whicheye = input('Please enter left or right to choose eye: ','s')
filepath = input('Enter procesed_data location: ', 's');
if isempty(dir(filepath))
     disp([filepath, '" does not exist.']);
end
for user_num = 1:1 %(user_num = 1:48)
    for session = 1:2 %(session = 1:2)
        for pattern = 1:2 %(pattern = 1:2)
            load([filepath,'/Frame_event_pupil_track_result/',whicheye,'/update_20_point_with_reference_user',num2str(user_num),'/session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            frame_event_update_rate = matcell_with_reference (:,5);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Remove blink update results （frames&events）%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            frame_ind = find(matcell_with_reference(:,5) == 1) ;
            frame_mat = matcell_with_reference(frame_ind,:);
            threshold = 0.2*mean(frame_mat(:,1));     
            blink_ind = find(frame_mat(:,1)<threshold); %Find blink frame, blinking is considered when the number of pixels in the pupil area is too small
            
            blink_start_timestamp = [];
            blink_end_timestamp = [];
            drop_blink_frame = 3; %Consider the 3 frames before and after the blink frame as a blink process
            for j = 1:length(blink_ind)
                if  blink_ind(j)+drop_blink_frame < length(frame_mat)
                    if  blink_ind(j)-drop_blink_frame > 0
                        blink_start_timestamp(end+1) =  (frame_mat(blink_ind(j)-drop_blink_frame,2));
                        blink_end_timestamp(end+1) =  (frame_mat(blink_ind(j)+drop_blink_frame,2));
                    else  
                        blink_start_timestamp(end+1) =  (frame_mat(1,2));
                        blink_end_timestamp(end+1) =  (frame_mat(blink_ind(j)+drop_blink_frame,2));
                    end
                else
                    blink_start_timestamp(end+1) =  (frame_mat(blink_ind(j)-drop_blink_frame,2));
                    blink_end_timestamp(end+1) =  (frame_mat(end,2));
                end
            end
          
            for jj = 1 : length(blink_end_timestamp) 
                [blink_del,~] = find((blink_start_timestamp(jj)<=matcell_with_reference(:,2))&(matcell_with_reference(:,2)<=blink_end_timestamp(jj)));
                matcell_with_reference(blink_del,:) = [];
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Remove blink update results（frames&events）%%%%%%%%%%%%%%%%%%%%%%%


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Remove error reference %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Remove update results where timestamp differs from tobii reference by more than 2ms
            nearlabel = find(matcell_with_reference(:,11)>2);
            matcell_with_reference(nearlabel,:) = [];
            
            %Remove tobii reference with nan and 0 values
            no_zero = find(((matcell_with_reference(:,6))~=0)&(matcell_with_reference(:,7)~=0));
            matcell_with_reference_no_zero_label  = matcell_with_reference(no_zero,:);
            no_nan = find(~isnan(matcell_with_reference_no_zero_label (:, 4)));
            matcell_with_reference_no_zero_label  = matcell_with_reference_no_zero_label(no_nan ,:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Remove error reference %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            

            
            %A partial sample of frame-based updates result (66 point) was taken to calculate the polynomial coefficients 
            frame_ind = find(matcell_with_reference_no_zero_label (:,5) == 1) ;
            frame_mat = matcell_with_reference_no_zero_label(frame_ind,:);  %Find results updated by frame
            train_tobii_reference_x_frame = frame_mat (:,6); % tobii reference for frame update results 
            train_tobii_reference_y_frame  = frame_mat (:,7); 
            train_pupil_centers_x_frame  = frame_mat  (:,3)/346; % normalisation of pupil centre coordinates
            train_pupil_centers_y_frame  = frame_mat (:,4)/260; 
            r = 1:floor(length(train_tobii_reference_x_frame) / 60):length(train_tobii_reference_x_frame);  % sampling points for subject calibration
            list_r = r;
            % Get polynomial coefficients 
            fitsurface_x=fit([train_pupil_centers_x_frame(list_r),train_pupil_centers_y_frame(list_r)],train_tobii_reference_x_frame(list_r), 'poly53'); 
            fitsurface_y=fit([train_pupil_centers_x_frame(list_r),train_pupil_centers_y_frame(list_r)],train_tobii_reference_y_frame(list_r), 'poly53');
            % Find results updated by event
            event_ind = find(matcell_with_reference_no_zero_label (:,5) == 0);
            event_mat = matcell_with_reference_no_zero_label (event_ind,:);
            
            frame_mat(list_r,:)=[]; % Delete samples (66 point)  used to calculate polynomial coefficients
            test_tobii_reference_x_frame_del =  frame_mat (:,6);
            test_tobii_reference_y_frame_del  = frame_mat (:,7);
            test_pupil_centers_x_frame_del  = frame_mat (:,3);
            test_pupil_centers_y_frame_del  = frame_mat (:,4);
            
            test_tobii_reference_x = [test_tobii_reference_x_frame_del ;event_mat(:,6)]; % tobii reference for frame & event update results 
            test_tobii_reference_y = [test_tobii_reference_y_frame_del ;event_mat(:,7)];
            test_pupil_centers_x = [test_pupil_centers_x_frame_del ;event_mat(:,3)]/346; % normalisation of pupil centre coordinates 
            test_pupil_centers_y = [test_pupil_centers_y_frame_del ;event_mat(:,4)]/260;
            
           
            x_gaze = fitsurface_x(test_pupil_centers_x,test_pupil_centers_y);% the estimated horizontal coordinate of the PoG on the screen
            y_gaze  = fitsurface_y(test_pupil_centers_x,test_pupil_centers_y);% the estimated vertical coordinate of the PoG on the screen
            
            distance = ((test_tobii_reference_x-x_gaze).^2+(test_tobii_reference_y-y_gaze).^2).^0.5; % screen-space Euclidean distance between tobii_reference and estimated PoG
            distance_x = mean(abs(test_tobii_reference_x -x_gaze));
            distance_y = mean(abs(test_tobii_reference_y -y_gaze));
            
            distance_list(end+1) = mean(distance);
            
            fprintf('user_num: %d session: %d pattern: %d,distance: %f\n',user_num,session,pattern,mean(distance));

            pause(2);
            % clearvars -except user_num  session  pattern anglerror count_max_list distance_list distance_x distance_y whicheye
            
        end
    end
end


angle_error = atan(mean(distance_list)/905)*180/pi;
% depth of tobii pro glasses 3 virtual screen is 905 (take screen-space pixels as the dimension)
fprintf('angle error: %f\n',angle_error)


