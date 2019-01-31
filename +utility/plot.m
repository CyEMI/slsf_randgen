function plot(x, y, y_legends, xLab, yLab, xScale, yScale)
    % y can be a vector or matrix
    
    if nargin < 6
        xScale = 'linear';
    end
    
    if nargin < 7
        yScale = 'linear';
    end
    
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
        
        ydata = ydata + eps;
        
        scatter(x, ydata, markers{i}, 'MarkerEdgeColor', 'k');
        hold on;
    end
    
    hold off;
    
    if ~ isempty(y_legends)
        legend(y_legends{:});
    end

    xlabel(xLab);
    ylabel(yLab);

    set(gca, 'XScale', xScale);
    set(gca, 'YScale', yScale);

end
