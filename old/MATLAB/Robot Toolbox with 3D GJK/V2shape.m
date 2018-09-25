function shape = V2shape(V, F)
    % convert vertex-specified shape to patch-like object given face info
    V1 = V(:,1);
    V2 = V(:,2);
    V3 = V(:,3);
    
    shape.V = V;
    
    shape.XData = V1(F);
    shape.YData = V2(F);
    shape.ZData = V3(F);
    
    %% AABB
    shape.min = min(V);
    shape.max = max(V);
end