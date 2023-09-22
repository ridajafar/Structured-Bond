function DV01_cg_bucket = compute_DV01_coarse_grained_swaps(all_buckets, buckets, ratesSet, datesSet, payment_dates, delta_times, flatMaturities, flatStrikes, flatVolatilities, frequency, end_year, TTM, strikes, spread, first_coupon, upfront, X, Y, s, flag)
% Computes the DV01 coarse grained bucket for the caps as difference between the upfronts
%
% INPUT:
% all_buckets:      swaps macro buckets
% buckets:          coarse grained buckets
% ratesSet:         set of rates
% datesSet:         set of dates
% payment_dates:    dates for which we want the spot volatilities
% delta_times:      delta in time between one time and the next one
% flatMaturities:   maturities corresponding to the flat volatility surface
% flatStrikes:      strikes corresponding to the flat volatility surface
% flatVolatilities: flat volatility surface
% frequency:        (yearly) frequency of the dates
% end_year:         maturity of the contract
% TTM:              vector of times to maturity
% strikes:          strikes of the different caps
% spread:           spol paid by the bank
% first_coupon:     first coupon paid (not a caplet)
% upfront:          upfront computed without shifting the rates
% X:                x dimension in the mesh to interpolate the spot volatilities
% Y:                y dimension in the mesh to interpolate the spot volatilities
% s:                spol paid by the IB
% flag:             0 -> consider the three caps paid by the investment bank
%                   1 -> consider the 5y ATM cap


% Parameters
bp = 1e-4;
n_buckets = length(buckets);
DV01_cg_bucket = zeros(n_buckets,1);

% Computing the weights for the shifts
weights = compute_weights(all_buckets, buckets)';

% Compute shift
shift = zeros(17,2);

for i = 1:n_buckets

    % Copy rate structure
    ratesSet_new = ratesSet;
    
    % If we are in the first bucket we must set to one the shift of the
    % depos and futures too
    if i==1
        ratesSet_new.depos = ratesSet.depos + bp;
        ratesSet_new.futures = ratesSet.futures - bp;
    end

    % Compute shift
    shift(all_buckets-1,:) = bp*ones(length(all_buckets),2).*weights(:,i);
    
    % Compute shifted rates
    ratesSet_new.swaps = ratesSet.swaps + shift;

    % Compute bootstrapped disocunts
    [dates, discounts_new] = BootStrap(datesSet, ratesSet_new);
    
    % Compute new discounts and libor rates
    B_new = [1; Disc_interp(discounts_new, dates, payment_dates(2:end))];
    B_fwd_new = B_new(2:end)./B_new(1:end-1);
    libor_rates_new = (1./B_fwd_new - 1)./delta_times;

    % Bootstrap spot volatilities
    spot_vols_new = boostrap_flat_volatilities(flatMaturities, flatStrikes, flatVolatilities, payment_dates(2:end), frequency, end_year, TTM, B_new, delta_times, libor_rates_new);
    switch flag
        case 0
            volatilities_new = interp2(flatStrikes,payment_dates(2:end-1),spot_vols_new',X,Y,'spline')';
            volatilities_swap_new = [volatilities_new(1,1:11)'; volatilities_new(2,12:19)'; volatilities_new(3,20:27)'];
        case 1
            volatilities_swap_new = interp2(flatStrikes,payment_dates(2:end-1),spot_vols_new',X,Y,'spline');
    end
    
    % Compute upfront
    upfront_new = compute_upfront(TTM, B_new, delta_times, libor_rates_new, strikes, volatilities_swap_new, spread, first_coupon, s, flag);
    
    % Compute DV01
    DV01_cg_bucket(i) = upfront_new - upfront;

end

end
