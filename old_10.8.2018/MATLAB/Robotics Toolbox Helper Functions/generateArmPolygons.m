function P = generateArmPolygons(R,q,w)
    P = cell(1, R.n);
    linkT = R.base;
    T = zeros(4); T(end,:) = 1; T(2, [1 3]) = w/2; T(2, [2 4]) = -w/2;
    T(1,1:2) = -1;
    RA = eye(4);
    for n = 1:R.n
        RA([1 6 13]) = cos(q(n)); RA([2 14]) = sin(q(n)); RA(5) = -RA(2);
        linkT(:) = linkT*RA;
        P{n} = (linkT([1,end-1],:)*T)';
    end
end