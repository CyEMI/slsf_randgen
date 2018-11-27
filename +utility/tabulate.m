function tabulate(fieldn, data, text, l)
    if ~isfield(data, fieldn)
        l.info('%s not found in report data', fieldn);
        return;
    end
    
    l.info(text);
    tabulate([data.(fieldn)]);
end

