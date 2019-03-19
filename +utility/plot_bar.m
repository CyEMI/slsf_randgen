function [f] = plot_bar(x, y, y_legends,xLab, yLab, xScale, yScale)
    % y can be a vector or matrix
    [sorted_blks_sz, row_ids] =  sort(x);% get the row id while sorting based on number of blocks /models 
    y = y(row_ids,:); % sorted y based on number of blocks per model
    %y_1= y_1(row_ids,:);% sorted y based on number of blocks per model (Avg Mutation)
    if nargin < 8 %nargin is number of input arguments of function
        xScale = 'linear';
    end
    
    if nargin < 9
        yScale = 'linear';
    end
    
    f = figure();
    
    %setting y axis tick label black 
    left_color = [0 0 0];
    right_color = [0 0 0];
    set(f,'defaultAxesColorOrder',[left_color; right_color]);
    
    % Make column vector
    if isvector(y)
        y = reshape(y, length(y), 1);
    end
    yyaxis left;
    H=bar(y,'stacked','BarWidth',0.5);
    
    %get different shades of gray of each section of stacked bar 
    colorset=gray(64); 
    %Alternate Shades of gray : except for Diff Test (6)
    for i = 1:6
       H(i).FaceColor = 'flat';
       if mod(i,2) ==0 && i~=6
           H(i).CData =  colorset(i,:); 
       elseif i ~=6
           H(i).CData =  colorset(70-6*i,:); 
       else
           H(i).CData =  [1 1 1] ;
       end
    end
   
    hold on; 
    box off;
    %xlabel(xLab);
     
    
    ylabel(yLab,'FontSize', 14,'color','k');
    set(gca, 'XScale', xScale);
    set(gca, 'YScale', yScale); 

end
