function [dates, discounts] = BootStrap(datesSet, ratesSet)
% function which computes the bootstrapped curve for the discount factors

% INPUT 
% datesSet:     struct with dates for options we have to compute the curve from
% ratesSet:     struct with rates for options we have to compute the curve from

% OUTPUT
% dates:        vector of the dates of the settlement date + expiry dates for the given options
% discounts:    discount factors for the corresponding dates

%% Deposits
% We start by computing the discount factors from the depos rates (max up 
% to 3 months) to be able to interpolate and get the first discount factor 
% needed for the futures

% Find the deposits we need (up to the settlement date of the first
% future)
index = datesSet.depos < datesSet.futures(1,1);
index_dep = find(index == 1);
index_dep = [index_dep; index_dep(end)+1];
T_dep = datesSet.depos(index_dep);

% Compute the discounts
Mid_depos = mean(ratesSet.depos(index_dep,:),2);
B = ( 1 + yearfrac(datesSet.settlement,datesSet.depos(index_dep),2) .* Mid_depos ).^-1;


%% Futures
% We proceed with the first seven futures in order to compute the discount
% factors at the expiry dates

% Set the number of futures we want to use
N=7;

% Compute mid for futures rate
Mid_futures = mean(ratesSet.futures(1:N,:),2);

% Set in advance length of output vectors for performance improvement
m = 1+length(index_dep);
discounts = zeros(m+N,1);
discounts(1:m)=[1 ; B];
dates = zeros(m+N,1);
dates(1:m) = [datesSet.settlement; T_dep];
dates(m+1:end) = datesSet.futures(1:N,2);

for i=1:N

 % Interpolate/extrapolate to obtain discount factor at settle date
 if datesSet.futures(i,1) < max(dates(1:m+i-1)) 
    r = -log(discounts(2:m+i-1))./yearfrac(dates(1),dates(2:m+i-1),3);
    r_fut = interp1(dates(2:m+i-1),r,datesSet.futures(i,1));
    B = exp(-r_fut*yearfrac(dates(1),datesSet.futures(i,1),3));
 else 
    r = -log(discounts(2:m+i-1))./yearfrac(dates(1),dates(2:m+i-1),3);
    r_fut = interp1(dates(2:m+i-1),r,datesSet.futures(i,1),'linear',r(end));
    B = exp(-r_fut*yearfrac(dates(1),datesSet.futures(i,1),3));
 end

 % Compute discount factor at expiry date
 discounts(m+i) = B/(1+yearfrac(datesSet.futures(i,1),datesSet.futures(i,2),2)*Mid_futures(i));

end


%% Swaps
% We conclude by using the swaps to compute the discount factors from 2y till 50y

% Compute the mid for the swap rates
Mid_swaps = mean(ratesSet.swaps,2);

% Compute a complete set of swap dates and rates from 2y till 50y
swap_dates = SwapDates(datesSet.swaps);
swap_rates = interp1(datesSet.swaps,Mid_swaps,swap_dates,'spline');

% Compute the 1y discount factor by interpolation (we checked that in 2024
% the 2nd of February isn't in the weekend)
date = datenum(2024,02,02);
r_1y = interp1(dates(2:end),-log(discounts(2:end))./ yearfrac(dates(1),dates(2:end),3),date);
swap_dates = [datesSet.settlement; date; swap_dates];

% Compute discount factors from swap rates and previous discount factors
B = zeros(50,1);
B(1) = exp(-r_1y*yearfrac(dates(1),date,3)); 
for i=2:50
    B(i) = (1 - swap_rates(i-1)*sum(yearfrac(swap_dates(1:i-1),swap_dates(2:i),6).*B(1:i-1)))/(1 + yearfrac(swap_dates(i),swap_dates(i+1),6)*swap_rates(i-1));
end

% Update output variables
dates = [dates; swap_dates(3:end)];
discounts = [discounts; B(2:end)];


end