function spot_vols = boostrap_flat_volatilities(flatMaturities, flatStrikes, flatVolatilities, payment_dates, frequency, end_year, TTM, discounts, delta_times, libor_rates)
% Computes the spot volatilities by bootstrapping the flat ones
%
% INPUT
% flatMaturities:   maturities corresponding to the flat volatility surface
% flatStrikes:      strikes corresponding to the flat volatility surface
% flatVolatilities: flat volatility surface
% payment_dates:    dates for which we want the spot volatilities
% frequency:        (yearly) frequency of the dates
% end_year:         maturity of the contract
% TTM:              vector of times to maturity
% discounts:        discount factors for each time
% delta_times:      delta in time between one time and the next one
% libor_rates:      libor rates for each time


% Parameters
act365 = 3;

% Initialize the volatilities up until the first date
spot_vols = zeros(length(flatStrikes), length(payment_dates)-1);
index_1 = frequency*flatMaturities(1);
spot_vols(:, 1:index_1-1 ) =  flatVolatilities(:,1)*ones(1,length(1:index_1-1));

% Initialize price of the first cap
cap_1 = arrayfun(@(strike, volatility) price_cap( TTM(1:index_1-1), ...
                                                  discounts(3:index_1+1), ...
                                                  delta_times(2:index_1), ...
                                                  libor_rates(2:index_1), ...
                                                  strike, ...
                                                  volatility ), ...
                                                  flatStrikes, flatVolatilities(:,1));

% Compute volatilities for all the payment dates 
end_index = find(end_year == flatMaturities);

for i = 1:end_index-1

    % Set indices for readability
    index_1 = frequency*flatMaturities(i);
    index_2 = frequency*flatMaturities(i+1);

    % Compute difference in cap prices
    cap_2 = arrayfun(@(strike, volatility) price_cap( TTM(1:index_2-1), ...
                                                      discounts(3:index_2+1), ...
                                                      delta_times(2:index_2), ...
                                                      libor_rates(2:index_2), ...
                                                      strike, ...
                                                      volatility ), ...
                                                      flatStrikes, flatVolatilities(:,i+1));
    DeltaC = cap_2 - cap_1;

    % Set new cap price to old
    cap_1 = cap_2;

    % Define linear interpolation constraints function
    sigma_now = @(sigma_end, T_now) spot_vols(:,index_1-1) + yearfrac(payment_dates(index_1-1), T_now, act365)./yearfrac(payment_dates(index_1-1), payment_dates(index_2-1), act365) * (sigma_end - spot_vols(:,index_1-1));

    % Compute sum of prices of caplets left
    indices = index_1:(index_2-1);
    caplets_old = @(sigma_end) 0;
    for j = 1:length(indices)
        caplets_new = @(sigma_end) caplets_old(sigma_end) + arrayfun(@(strike, volatility) price_cap( TTM(indices(j)), ...
                                                                                                      discounts(indices(j)+2), ...
                                                                                                      delta_times(indices(j)+1), ...
                                                                                                      libor_rates(indices(j)+1), ...
                                                                                                      strike, ...
                                                                                                      volatility ), ...
                                                                                                      flatStrikes, sigma_now(sigma_end, payment_dates(indices(j))));
        caplets_old = caplets_new;
    end
    
    % Compute the spot volatility corresponding to the last caplet
    f = @(sigma_end) caplets_new(sigma_end) - DeltaC;
    options = optimset('Display','off'); % set to on to see output of fsolve 
    sigma_end = fsolve(f,spot_vols(:,index_1-1),options);

    % Compute spot volatilities
    spot_vols(:,index_2-1) = sigma_end;
    for j = 1:length(indices)-1
        spot_vols(:,index_1+j-1) = sigma_now(sigma_end, payment_dates(index_1+j-1));
    end
    
end

end