function pause2(seconds)
    t = tic;
    while toc(t) < seconds, end
end