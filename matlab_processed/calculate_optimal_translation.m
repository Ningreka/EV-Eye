
function [Ts] = Calculate_t(P,Q, polarity_list)
max_iterations = 50; % Maximum number of iterations
NS = createns(Q,'NSMethod','kdtree'); % Create Kdtree
Ts = [0,0];
j=0; 
while j<max_iterations
    j=j+1;
    [idx,~] = knnsearch(NS,P,'k',1);% kdtree finds the nearest points to a point and returns the position of the corresponding point and the distance to that point
    mapPoint= Q(idx,:);
    
    Ts_temp(1) = mean(mapPoint(:,1)-P(:,1));
    Ts_temp(2) = mean(mapPoint(:,2)-P(:,2));
    
    if  ((abs(Ts_temp(1))<0.001) && (abs(Ts_temp(2))<0.001))
        break
    end

    Ts(1) =  Ts(1)+ Ts_temp(1);
    Ts(2) =  Ts(2)+ Ts_temp(2);
    
   P(:,1) = P(:,1)+ Ts_temp(1);
   P(:,2) = P(:,2)+ Ts_temp(2);   

end

end




