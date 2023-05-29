clc 
clear all
close all

for user_num = 13:13
for session = 1:1
for pattern = 1:1

processedpath = input('Enter processed_data location(such as /home/processed_data): ', 's');

load([processedpath,'\Frame_event_pupil_track_result\update_factor_1\left\update_20_point_user',num2str(user_num),'_session_',num2str(session),'_0_',num2str(pattern),'.mat']);
matcell_with_label =[ matcell(:,1),matcell];
frame_indx =find((matcell_with_label(:,6) == 1)&(~isnan(matcell_with_label(:,4)))&(~isnan(matcell_with_label(:,5))));
event_indx =find((matcell_with_label(:,6) == 0)&(~isnan(matcell_with_label(:,4)))&(~isnan(matcell_with_label(:,5))));
matcell_with_label(:,3) =( matcell_with_label(:,3) -matcell_with_label(1,3))/1000000 ;

figure(1)
scatter(matcell_with_label(event_indx,3),abs(matcell_with_label(event_indx,5)) ,10, 'o','MarkerFaceColor','r','MarkerEdgeColor', 'r','linewidth',2) 
hold on 
scatter(matcell_with_label(frame_indx,3),abs(matcell_with_label(frame_indx,5)) ,10, 'o','MarkerFaceColor','b','MarkerEdgeColor', 'b','linewidth',2) 

legend('Event','Frame');
ylabel('Vertical')
title('Ours','FontSize',25,'FontWeight','bold')
set(gca,'xLim',[110+40 190]);
set(gca,'YLim',[100 180]);
set(gca,'xtick',[110+40:10 :190])
set(gca,'xTickLabel',[0:10 :40])
set(gca,'ytick',[100:20:180])
set(gca,'yTickLabel',[100:20:180])
box on;
set(gca,'FontSize',30,'FontWeight','bold')
set(gca,'linewidth',5)
set(gcf,'color','white');
set(gca,'LooseInset',get(gca,'TightInset'))
xlabel('Seconds')
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
scatter(matcell_with_label(event_indx,3),abs(matcell_with_label(event_indx,4)) ,10, 'o','MarkerFaceColor','r','MarkerEdgeColor', 'r','linewidth',2)
hold on 
scatter(matcell_with_label(frame_indx,3),abs(matcell_with_label(frame_indx,4)) ,10, 'o','MarkerFaceColor','b','MarkerEdgeColor', 'b','linewidth',2) 

legend('Ours','Angelopoulos et al.');
legend('Event','Frame');
ylabel('Horizontal')
title('Ours','FontSize',25,'FontWeight','bold')

set(gca,'xLim',[110+40 190]);
set(gca,'YLim',[100 250]);
set(gca,'xtick',[110+40:10 :190])
set(gca,'xTickLabel',[0:10 :40])
box on;
set(gca,'FontSize',30,'FontWeight','bold')
set(gca,'linewidth',5)
set(gcf,'color','white');
set(gca,'LooseInset',get(gca,'TightInset'))

xlabel('Seconds')
hold off;

end
end
end
