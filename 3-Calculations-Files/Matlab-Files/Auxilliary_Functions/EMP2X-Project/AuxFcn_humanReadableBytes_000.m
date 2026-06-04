function s = AuxFcn_humanReadableBytes_000(n)
if isempty(n) || isnan(n)
    s = 'N/A';
    return;
end
if n >= 1e9
    s = sprintf('%.2f GB', n/1e9);
elseif n >= 1e6
    s = sprintf('%.2f MB', n/1e6);
elseif n >= 1e3
    s = sprintf('%.2f kB', n/1e3);
else
    s = sprintf('%d B', n);
end
end
