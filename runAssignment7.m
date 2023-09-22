% runAssignment7
% group 7, AY2022-2023

clear;
close all;
clc;
format long;

% yearfrac formats
act360 = 2;
act365 = 3;

%% Read market data

datesSet = load("datesSet.mat").datesSet;
ratesSet = load("ratesSet.mat").ratesSet;

% Bootstrap discounts
[dates, discounts] = BootStrap(datesSet, ratesSet);

%% CASE STUDY

% Parameters
Notional = 5e7;

% Payment dates
frequency = 4;
end_year = 7;
payment_dates = datetime(2023,02,01):calmonths(12/frequency):datetime(2023+end_year,02,01);
payment_dates = datenum(busdate(payment_dates))';

% Discount factors
B = [1; Disc_interp(discounts, dates, payment_dates(2:end))];

% Forward libor rates
B_fwd = B(2:end)./B(1:end-1);
delta_times = yearfrac(payment_dates(1:end-1),payment_dates(2:end),act360);
libor_rates = (1./B_fwd - 1)./delta_times;

% Time to maturities
TTM = yearfrac(payment_dates(1),payment_dates(2:end),act365);

%% a) SPOT VOLATILITIES

% Read flat volatilities matrix
flatMaturities = [1; 1.5; (2:10)'; 12; 15; 20];
flatStrikes = readmatrix('CapData.xls','Sheet','Flat Vol','Range','C5:C17')/100;
flatVolatilities = readmatrix('CapData.xls','Sheet','Flat Vol','Range','D5:Q17')/100;

% Bootstrap spot volatilities
spot_vols = boostrap_flat_volatilities(flatMaturities, flatStrikes, flatVolatilities, payment_dates(2:end), frequency, end_year, TTM, B, delta_times, libor_rates);

% Plot surface
mesh(payment_dates(3:end),flatStrikes,  spot_vols)
title('Spot Volatiities Surface')
xlabel('Dates') 
ylabel('Strikes')
zlabel('Volatility')

%% UPFRONT COMPUTATION

% Contract parameters
s = 1.1/100;
strikes = [4.3; 4.6; 5.1]/100 - s;
maturities = [3; 5; 7];
spread = 0.02;
first_coupon = 0.03;

% Intepolation to find the volatilities on the given strikes (spline since
% it's only on the strikes, otherwise change it to linear in time)
[X,Y] = meshgrid(strikes,payment_dates(2:end-1));
volatilities = interp2(flatStrikes,payment_dates(2:end-1),spot_vols',X,Y,'spline')';
volatilities_swap = [volatilities(1,1:11)'; volatilities(2,12:19)'; volatilities(3,20:27)'];

% Compute upfront
upfront = compute_upfront(TTM, B, delta_times, libor_rates, strikes, volatilities_swap, spread, first_coupon, s, 0);
fprintf('The upfront is: %.4f\n', upfront)

%% b) DELTA-BUCKET SENSITIVITIES

% Compute DV01 bucket shifting one rate at a time in ratesSet
tic
DV01_bucket = compute_DV01_bucket(ratesSet, datesSet, payment_dates, delta_times, flatMaturities, flatStrikes, flatVolatilities, frequency, end_year, TTM, strikes, spread, first_coupon, upfront, X, Y, s, 0);
toc

%% c) TOTAL VEGA

vega_caplets_1 = compute_vega_caplets(libor_rates(2:12), strikes(1), volatilities_swap(1:11), TTM(1:11), delta_times(2:12));
vega_caplets_2 = compute_vega_caplets(libor_rates(13:20), strikes(2), volatilities_swap(12:19), TTM(12:19), delta_times(13:20));
vega_caplets_3 = compute_vega_caplets(libor_rates(21:end), strikes(3), volatilities_swap(20:end), TTM(20:end-1), delta_times(21:end));

total_vega = sum(vega_caplets_1) + sum(vega_caplets_2) + sum(vega_caplets_3);

%% d) COARSE-GRAINED BUCKET DV01

% Compute coarse grained bucket DV01
all_buckets = 2:7;
buckets = [2, 5, 7];
DV01_cg_bucket = compute_DV01_coarse_grained_swaps(all_buckets, buckets, ratesSet, datesSet, payment_dates, delta_times, flatMaturities, flatStrikes, flatVolatilities, frequency, end_year, TTM, strikes, spread, first_coupon, upfront, X, Y, s, 0);

% Display sum results
fprintf('The sum of the DV01 bucket is: %.10f \n', sum(DV01_bucket))
fprintf('The sum of the coarse grained DV01 bucket is: %.10f \n', sum(DV01_cg_bucket))

% Set payment dates for the three swaps
payment_dates_2 = payment_dates(1:9);
payment_dates_5 = payment_dates(1:21);
payment_dates_7 = payment_dates(1:end);

% Compute DV01 for 2y, 5y, 7y swaps
DV01_swap_2 = DV01_swap(ratesSet, datesSet, payment_dates_2, 2);
DV01_swap_5 = DV01_swap(ratesSet, datesSet, payment_dates_5, 5);
DV01_swap_7 = DV01_swap(ratesSet, datesSet, payment_dates_7, 7);

% Compute notionals 
N_7 = - Notional*DV01_cg_bucket(3)/DV01_swap_7;
N_5 = - (Notional*DV01_cg_bucket(2) + N_7*DV01_swap_7)/DV01_swap_5;
N_2 = - (Notional*DV01_cg_bucket(1) + N_5*DV01_swap_5 + N_7*DV01_swap_7)/DV01_swap_2;

%% e) HEDGE THE VEGA

% Parameters of the Cap
strike = mean(ratesSet.swaps(4),2);
[X,Y] = meshgrid(strike,payment_dates_5(3:end));
volatilities_swap_5y = interp2(flatStrikes,payment_dates(3:end),spot_vols',X,Y,'spline');

% Compute vega of the cap
vega_cap_5y = sum(compute_vega_caplets(libor_rates(2:20), strike, volatilities_swap_5y, TTM(2:20), delta_times(2:20)));

% Compute notional
N_cap = -total_vega*Notional/vega_cap_5y;

%% HEDGE THE DELTA

% Compute upfront
upfront_5y = compute_upfront(TTM, B, delta_times, libor_rates, strike, volatilities_swap_5y, spread, first_coupon, s, 1);

% Compute DV01 coarse grained bucket
DV01_cg_bucket_5y = compute_DV01_coarse_grained_swaps(all_buckets, buckets, ratesSet, datesSet, payment_dates, delta_times, flatMaturities, flatStrikes, flatVolatilities, frequency, end_year, TTM, strike, spread, first_coupon, upfront_5y, X, Y, s, 1);

% Compute new notionals 
N_7_new = N_7 - N_cap*DV01_cg_bucket_5y(3)/DV01_swap_7;
N_5_new = N_5 - (N_cap*DV01_cg_bucket_5y(2) + N_7*DV01_swap_7)/DV01_swap_5;
N_2_new = N_2 - (N_cap*DV01_cg_bucket_5y(1) + N_5*DV01_swap_5 + N_7*DV01_swap_7)/DV01_swap_2;
