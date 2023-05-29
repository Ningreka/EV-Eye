clc
clear all
close all

% We leverage the VGG Image Annotator to label the pupil region of 9,011 near-eye images selected uniformly across the whole image dataset.
% Normally, the pupil region is regarded as an ellipse. Therefore, we label the region by adjusting the major axis, minor axis,tilt angle, and center of the ellipse.
% Then inpolygon function is applied to generate binarized masks G as the groundtruth according to the region of the ellipse.
% generate data & label to hdf5 file
whicheye = input('Please enter left or right to choose eye: ','s')
rawfilepath = input('Enter raw_data location(such as /home/raw_data): ', 's');
processedpath = input('Enter processed_data location(such as /home/processed_data): ', 's');

session_pattern_list = [1,2;2,1;2,2];  % select pattern and session with label
for user_num = 1:48
    for session_pattern = 1:3
        session = session_pattern_list(session_pattern,1);
        pattern = session_pattern_list(session_pattern,2);
        
        path_folder = [rawfilepath ,'\Data_davis\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\'];
        dir_folder = dir(fullfile(path_folder, 'frames\*.png*'));
        names_file = sort_nat({dir_folder.name});
        
        ellipse_parameter = read_csv(user_num,session,pattern,whicheye) ; % Reading manually marked ellipses  by VGG Image Annotator  https://www.robots.ox.ac.uk/~vgg/software/via/via_demo.html
        
        find_pupil = find((ellipse_parameter(:,1)~= 0));
        
        for i = 1:length(find_pupil)
            
            labelled_indx = find_pupil(i);
            
            I = imread(cell2mat(fullfile(path_folder,'frames\', names_file(labelled_indx))));
            
            t = linspace(0,2*pi);
            
            each_row = ellipse_parameter(labelled_indx,:);
            
            Cx = each_row(1) ;
            Cy = each_row(2) ;
            Rx = each_row(3);
            Ry = each_row(4);
            Rotation = each_row(5);
            
            x = Rx * cos(t);
            y = Ry * sin(t);
            nx = x*cos(Rotation)-y*sin(Rotation) + Cx;
            ny = x*sin(Rotation)+y*cos(Rotation) + Cy;
            
            for ii = 1:260
                for jj = 1:346
                    if inpolygon(ii,jj,ny,nx)
                        I_new(ii,jj) = 1;
                    else
                        I_new(ii,jj) = 0;
                    end
                end
            end
            
            %%%%%%%%%%%%%%plot mask%%%%%%%%%%%%%%%
            figure(1)
            imshow(I);
            hold on
            plot(nx,ny,'r.');
            set(gca,'YLim',[ 0,260]);
            set(gca,'XLim',[ 0,346]);
            hold off
            figure(2)
            imshow((I_new))
            pause(0.01)
            %%%%%%%%%%%%%%plot mask%%%%%%%%%%%%%%%
            matcell(i, :, :) =  (I);
            label(i, :, :) =  (I_new);
        end
        
        
        % hdf5write(['H:\raw_data\Data_davis_labelled_with_mask\',whicheye,'\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.h5'], '/data', matcell, '/label', label);
        clearvars -except user_num  session  pattern session_pattern_list whicheye
        
    end
end
