function price = price_cap(TTM, discounts, delta_times, libor_rates, strike, volatilities)
% It compute a vector of prices of caplets with different maturities and
% volatilities and then it sums them up to obtain the price of the
% corresponding Cap
% TTM, discounts, libor_rates, delta_times, alpha must have same lenght of
% the vector of caplet composing the Cap
% Strike is the same for every caplet

% Shifted_LMM

% INPUT
%
% TTM:          vector of times to maturity
% discounts:    discount factors for each time
% delta_times:  delta in time between one time and the next one
% libor_rates:  libor rates for each time
% alpha:        vector of alphas (one for each caplet)
% strikes:      strikes of the different caps
% volatilities: vector of volatilities (one for each caplet)


% Compute the price of the caplets
d1 = log((libor_rates)./(strike))./(volatilities.*sqrt(TTM)) + 0.5*volatilities.*sqrt(TTM);
d2 = log((libor_rates)./(strike))./(volatilities.*sqrt(TTM)) - 0.5*volatilities.*sqrt(TTM);
price_caplet = discounts.*delta_times.*((libor_rates).*normcdf(d1)-(strike).*normcdf(d2));

% Cap is sum of caplet (option on libor rate)
price = sum(price_caplet);

end