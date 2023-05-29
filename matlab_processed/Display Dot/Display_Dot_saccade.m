clc;clear;close all


hold on
axis([ 0 100 0 100])
set(gca,'YLim',[0 100]);
set(gca,'XLim',[0 100]);
set(gcf,'MenuBar','none');
% axis off;
box on;
set(gcf,'color','black');
colordef black;
% set(gca,'LooseInset',get(gca,'TightInset'))
% set(gca, 'LooseInset', [0,0,0,0]);
set(gca, 'LooseInset', [500,500,500,500]);


x_list = [0:10:100]';
y_list = [0:10:100]';

for j = 1:1:11
    for k = 1:1:11
     
xy_mat((j-1)*11+k,:) = [x_list(j);y_list(k)];

    end
end


% D = randperm(xy_mat,121);
% randIndex = randperm(121);
% save randIndex randIndex

load randIndex 

xy_mat_new = xy_mat(randIndex ,:);

% plot(xy_mat_new(:,1), xy_mat_new(:,2))
% D = randperm(D,121);

Calibration_point = [0,0;
                     0,100;    
                     100,0
                     100,100
                     50,50];

xy_mat_new = [Calibration_point;xy_mat_new];

x = 50;
y = 50;
h= plot( x,y , 'Marker','o', 'MarkerEdgeColor','r','LineWidth', 60);
m= plot( x,y , 'Marker','o', 'MarkerEdgeColor','k','LineWidth', 40);
s= plot( x,y , 'Marker','o', 'MarkerEdgeColor','r','LineWidth', 20);


pause(5)


tic
for n=1:126
set(h,'xdata',xy_mat_new(n,1),'ydata',xy_mat_new(n,2));
set(m,'xdata',xy_mat_new(n,1),'ydata',xy_mat_new(n,2));
set(s,'xdata',xy_mat_new(n,1),'ydata',xy_mat_new(n,2));
pause(1.5)
end
toc