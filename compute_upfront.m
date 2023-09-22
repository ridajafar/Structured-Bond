function upfront = compute_upfront(TTM, discounts, delta_times, libor_rates, strikes, volatilities, spread, first_coupon, s, flag)
% Computes the upfront of a swap by setting the NPV equal to 0
%
% INPUT
% TTM:          vector of times to maturity
% discounts:    discount factors for each time
% delta_times:  delta in time between one time and the next one
% libor_rates:  libor rates for each time
% strikes:      strikes of the different caps
% volatilities: vector of volatilities (one for each caplet)
% spread:       spol paid by the bank
% first_coupon: first coupon paid (not a caplet)
% s:            spol paid by the IB
% flag:         0 -> consider the three caps paid by the investment bank
%               1 -> consider the 5y ATM cap


% Compute prices for the caps
switch flag
    case 0
        Cap = price_cap(TTM(1:11), discounts(3:13), delta_times(2:12), libor_rates(2:12), strikes(1), volatilities(1:11));
        Cap = Cap + price_cap(TTM(12:19), discounts(14:21), delta_times(13:20), libor_rates(13:20), strikes(2), volatilities(12:19));
        Cap = Cap + price_cap(TTM(20:end-1), discounts(22:end), delta_times(21:end), libor_rates(21:end), strikes(3), volatilities(20:end));
    case 1
        Cap = price_cap(TTM(1:19), discounts(3:21), delta_times(2:20), libor_rates(2:20), strikes, volatilities(1:19));
end

% Compute the BPV 
BPV = delta_times'*discounts(2:end);
BPV_s = delta_times(2:end)'*discounts(3:end);

% Compute the upfront
upfront = (spread)*BPV - BPV_s*s + 1 - 1*discounts(2) + Cap - (first_coupon*delta_times(1))*discounts(2);

end