function weights = compute_weights(Ti, Tj)
% Computes the weights for the coarse grained bucket DV01
%
% INPUT:
% Ti:   all the buckets 
% Tj:   coarse grained buckets


% Paramters
n_elements = length(Ti);
weights = zeros(length(Tj),n_elements);
aux = zeros(1,n_elements);

for j = 1:length(Tj)
    if j==1
        for i = 1:n_elements
            if Ti(i) <= Tj(j)
                auxi = 1;
            elseif Ti(i) >= Tj(j) && Ti(i) <= Tj(j+1)
                auxi = Ti(i)/(Tj(j) - Tj(j+1)) + Tj(j+1)/(Tj(j+1)-Tj(j));            
            else
                auxi = 0;
            end
            aux(i) = auxi;
        end
        weights(j,:) = aux;
    elseif j == length(Tj)
        for k = 1:n_elements
            if Ti(k) <= Tj(j-1)
                auxi = 0;
            elseif Ti(k) >= Tj(j)
                auxi = 1;
            else
                auxi = Ti(k)/(Tj(j)-Tj(j-1)) - Tj(j-1)/(Tj(j) - Tj(j-1));
            end
             aux(k) = auxi;
        end
        weights(j,:) = aux;
    else
        for n = 1:n_elements
            if Ti(n) <= Tj(j-1)
                auxi = 0;
            elseif Ti(n) <= Tj(j) &&  Ti(n) > Tj(j-1)
                auxi = Ti(n)/(Tj(j) - Tj(j-1)) -  Tj(j-1)/(Tj(j) - Tj(j-1));
            elseif Ti(n) <= Tj(j + 1) &&  Ti(n) > Tj(j)
                auxi = Ti(n)/(Tj(j) - Tj(j+1)) + Tj(j+1)/(Tj(j+1)-Tj(j)); 
            else
                auxi = 0;
            end
            aux(n) = auxi;
        end
        weights(j,:) = aux;
    end
end
end

     