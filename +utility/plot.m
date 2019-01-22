function plot(x, y, y_legends, xLab, yLab)
    % y can be a vector or matrix
    figure();
    
    % Make column vector
    if isvector(y)
        y = reshape(y, length(y), 1);
    end
    
    n_y = size(y, 2);
    
%     markers = {'o', 's', 'd', '^', 'v', '<', '>'};
    
    markers = {'o', '+', '*', '^', 'x', '<', '>'};
    
    assert(length(markers) >= n_y );
    
    for i = 1: n_y
        ydata = y(:, i);
        
        if iscell(ydata)
            ydata = cell2mat(ydata);
        end
        
        scatter(x, ydata, markers{i}, 'MarkerEdgeColor', 'k');
        hold on;
    end
    
    hold off;
    
    legend(y_legends{:});

    xlabel(xLab);
    ylabel(yLab);
end
