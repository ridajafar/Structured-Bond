function vega_caplets = compute_vega_caplets(libor_rates, strike, volatilities, TTM, delta_times)
% Computes the vega of a series of caplets
%
% INPUT
% libor_rates:  libor rates for each time
% strike:       strike of the caplets (same for all of them)
% volatilities: vector of volatilities (one for each caplet)
% TTM:          vector of times to maturity
% delta_times:      delta in time between one time and the next one


d1 = log((libor_rates)./(strike))./(volatilities.*sqrt(TTM)) + 0.5*volatilities.*sqrt(TTM);
vega_caplets = delta_times.*libor_rates.*normpdf(d1).*sqrt(TTM);

end