clc 
close all
clear all

[angle_left,distance_left] = textread(['left_dod.txt'], '%f %f'); 
[angle_right,distance_right] = textread(['right_dod.txt'], '%f %f'); 

distance = (distance_left+distance_right)/2;

distance_list = [] ;
for i = 1:4:192
   distance_list(end+1) = mean(distance(i:i+3));
end

% DoD = arctan (Pd/dz) where dz is the distance between the virtual screen to the scene camera of Tobii which can be easily obtained from the device
% depth of tobii pro glasses 3 virtual screen is 905 (take screen-space pixels as the dimension)  
distance_list = atan(distance_list./905)*180/3.14; 

mean(distance_list) 

x = [1:48];
figure(2);
hold on;

b = bar(x,distance_list ,1.05);
b(1).FaceColor = '[0,0.4470,0.7410]';
xlabel('Subject ID')
set(gca,'xtick',[0:4:48])
legend('Ours');
ylabel('DoD')
box on
set(gca,'FontSize',25,'FontWeight','bold')
set(gca,'linewidth',4.0)
set(gca,'LooseInset',get(gca,'TightInset'))
set(gcf,'color','white');
colordef white
