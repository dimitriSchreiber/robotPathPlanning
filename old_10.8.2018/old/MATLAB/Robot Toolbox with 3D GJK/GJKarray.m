function flag = GJKarray(X,Y,iterations)
    % flag is 1: collision detected
    % flag is 0: no collision detected
    % X is MxN struct array, Y is 1xN
    % Assume X's are linked (each row is a different config), Y's are disjoint
    flag = ones(size(X,1),1);

    for j = 1:length(Y)
        %         if any(min(reshape([X.min],3,[]),[],2)' > Y(j).max) || any(min(reshape([X.max],3,[]),[],2)' > Y(j).min)
        %             continue;
        %         end
        for m = 1:size(X,1)
            if flag(m) == 1
                for i = 1:size(X,2)
                    % check axis-aligned bounding boxes first
                    %             if any(X(i).min > Y(j).max) || any(Y(j).min > X(i).max), continue; end
%                     if X(m,i).min(1) > Y(j).max(1) || X(m,i).min(2) > Y(j).max(2) || X(m,i).min(3) > Y(j).max(3) ...
%                             || X(m,i).max(1) < Y(j).min(1) || X(m,i).max(2) < Y(j).min(2) || X(m,i).max(3) < Y(j).min(3)
                    if any(X(m,i).min > Y(j).max) || any(Y(j).min > X(m,i).max)
                        continue;
                    end

                    if GJK(X(m,i), Y(j), iterations)
                        flag(m) = -1;
                    end
                end
            end
        end
    end
end