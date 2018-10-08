function P = generateArmPolyhedra(R,q,w)
    % face info for a rectangular prism
    F = [1 2 6 5; 2 4 8 6; 3 4 8 7; 1 3 7 5; 1 2 4 3; 5 6 8 7]';

    a = R.a;
    [~,allT] = R.fkine(q);
    
%     T = transl(R.base)
    T = zeros(4,8);
    T(2, [1 2 5 6]) = -w/2;
    T(2, [3 4 7 8]) = w/2;
    T(3, 1:4) = -w/2;
    T(3, 5:end) = w/2;
    T(4,:) = 1;
    for i = size(q,1):-1:1
        for n = R.n:-1:1
            linkT = allT(1:3,:,n,i);
            T(1,1:2:end) = -a(n);
            P(i,n) = V2shapeMex((linkT*T)', F);
        end
    end
end