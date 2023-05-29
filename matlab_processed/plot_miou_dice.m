clc
clear all
close all

% The IoU, F1 score (Dice coefficient) calculated from the DL-based Pupil Segmentation output mask and the manually marked pupil area

processedpath = input('Enter processed_data location(such as /home/processed_data): ', 's');

[diceleft,miouleft] = textread([processedpath ,'\Pre-trained_models\left.txt'], '%f %f');
[diceright,miouright] = textread([processedpath,'\Pre-trained_models\right.txt'], '%f %f');

diceleft= (((diceleft)+(diceright)))/2;
miouleft= (((miouleft)+(miouright)))/2;
mean(diceleft)
mean(miouleft)

x = [1:48];
figure(1);
hold on;
bar(x,[miouleft'],1.05)

b(1).FaceColor = '[0.85,0.3250,0.0980]';
xlabel('Subject ID')
set(gca,'xtick',[0:4:48])

legend('DL-based')
ylabel('IoU')
set(gca,'YLim',[0.75 0.95]);
set(gca,'YTick',[0.75 0.8 0.85 0.9 0.95])
box on;
set(gca,'FontSize',25,'FontWeight','bold')
set(gca,'linewidth',4.0)
set(gca,'LooseInset',get(gca,'TightInset'))
set(gcf,'color','white');

colordef white
hold off;

% exportgraphics(gcf,'export.pdf'); %'jpg' 'jpeg' 'png' 'tif' 'tiff''pdf' 'emf' 'eps'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = [1:48];
figure(2);
hold on;

bar(x,[diceleft'],1.05);

b(1).FaceColor = '[0.85,0.3250,0.0980]';
xlabel('Subject ID')
set(gca,'xtick',[0:4:48])

legend('DL-based')
ylabel('F1 Score')
set(gca,'YLim',[0.85 1]);
set(gca,'YTick',[0.85 0.9 0.95 1])

box on;
set(gca,'FontSize',25,'FontWeight','bold')
set(gca,'linewidth',4.0)

set(gca,'LooseInset',get(gca,'TightInset'))
set(gcf,'color','white');
colordef white
hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






