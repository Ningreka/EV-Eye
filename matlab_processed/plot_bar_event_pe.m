clc
clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%left pixel_error_each_user %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

processedpath = input('Enter processed_data location(such as /home/EV_Eye_dataset/processed_data) to use Pixel_error_evaluation: ', 's');
session_2_0_1_list = [];
for user_num = 1:48
    
    for session = 2:2
        
        for pattern = 1:1
            
            load([processedpath,'\Pixel_error_evaluation\event\left\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            
            session_2_0_1_list(end+1) =  mean(matcell);
            
            
        end
        
    end
end

session_1_0_2_list = [];
for user_num = 1:48
    
    for session = 1:1
        
        for pattern = 2:2
            
            load([processedpath,'\Pixel_error_evaluation\event\left\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            
            session_1_0_2_list(end+1) =  mean(matcell);
            
            
        end
        
    end
end


session_2_0_2_list = [];
for user_num = 1:48
    
    for session = 2:2
        
        for pattern = 2:2
            
            load([processedpath,'\Pixel_error_evaluation\event\left\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            
            session_2_0_2_list(end+1) =  mean(matcell);
            
            
        end
        
    end
end

left_pixel_error = [session_1_0_2_list;session_2_0_1_list;session_2_0_2_list];
left_pixel_error_each_user = mean(left_pixel_error,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%right pixel_error_each_user %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

session_2_0_1_list = [];
for user_num = 1:48
    
    for session = 2:2
        
        for pattern = 1:1
            
            load([processedpath,'\Pixel_error_evaluation\event\right\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            
            session_2_0_1_list(end+1) =  mean(matcell);
            
            
        end
        
    end
end

session_1_0_2_list = [];
for user_num = 1:48
    
    for session = 1:1
        
        for pattern = 2:2
            
            load([processedpath,'\Pixel_error_evaluation\event\right\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            
            session_1_0_2_list(end+1) =  mean(matcell);
            
            
        end
        
    end
end


session_2_0_2_list = [];
for user_num = 1:48
    
    for session = 2:2
        
        for pattern = 2:2
            
            load([processedpath,'\Pixel_error_evaluation\event\right\user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
            
            session_2_0_2_list(end+1) =  mean(matcell);

        end
        
    end
end

right_pixel_error = [session_2_0_1_list;session_1_0_2_list;session_2_0_2_list];
right_pixel_error_each_user = mean(right_pixel_error,1);

pixel_error_each_user_ours  = ( right_pixel_error_each_user + left_pixel_error_each_user)/2;

mean(pixel_error_each_user_ours)

x = [1:48];
figure(1);
hold on;
b = bar(x,[pixel_error_each_user_ours'],1.05);
b(1).FaceColor = '[0,0.4470,0.7410]';
xlabel('Subject ID')
set(gca,'xtick',[0:4:48])
legend('Matching-based');

ylabel('PE')
box on;
set(gca,'FontSize',25,'FontWeight','bold')
set(gca,'linewidth',4.0)
% remove white space around the figure
set(gca,'LooseInset',get(gca,'TightInset'))
set(gcf,'color','white');
colordef white
hold off;




