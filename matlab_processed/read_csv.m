function ellipse_parameter = read_csv(path,user_num,session,pattern,whicheye) 

% path_folder_label= ['E:\label_ellipse\Data_Dvs_Unlabelled_',num2str(session),'_0_',num2str(pattern),'\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\events\','user_',num2str(user_num),'.csv'];
path_folder_label = [path ,'\Data_davis\user',num2str(user_num),'\',whicheye,'\','session_',num2str(session),'_0_',num2str(pattern),'\user_',num2str(user_num),'.csv'];


M =  readtable(path_folder_label);

table_row_6 = M(:,6);
row_cell = table_row_6.region_shape_attributes;

for i = 1:length(row_cell)
row_str =strsplit( char(row_cell(i)),{',',':','}'},'CollapseDelimiters',true);

if length(row_str) == 13

cx(i) = str2num(cell2mat(row_str(:,4)));
cy(i) =  str2num(cell2mat(row_str(:,6)));
rx(i) =  str2num(cell2mat(row_str(:,8)));
ry(i) =  str2num(cell2mat(row_str(:,10)));
theta(i) = str2num(cell2mat(row_str(:,12)));

else
cx(i) = 0;
cy(i) =  0;
rx(i) =  0;
ry(i) =  0;
theta(i) = 0; 
end
    
end

ellipse_parameter = [cx;cy;rx;ry;theta]';
end