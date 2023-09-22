function DV01 = DV01_swap(ratesSet, datesSet, payment_dates, maturity)
% Compute the DV01 for an IR swap
%
% INPUT
% ratesSet:         set of rates
% datesSet:         set of dates
% payment_dates:    payment dates of the swaps
% maturity:         maturity of the swap


% Compute bootstrapped disocunts
[dates, discounts] = BootStrap(datesSet, ratesSet);

% Define the shift 
bp = 1e-4;

% Compute shifted rates
ratesSet_new = ratesSet;
ratesSet_new.depos = ratesSet.depos + bp;
ratesSet_new.futures = ratesSet.futures - bp;
ratesSet_new.swaps = ratesSet.swaps + bp; 

% Compute new bootstrapped disocunts
[~, discounts_new] = BootStrap(datesSet, ratesSet_new);

% Compute fixed rates
fixed_rate = mean(ratesSet.swaps(maturity-1),2); %%?
%fixed_rate_new = mean(ratesSet.swaps(maturity-1),2); %%?

% Compute discounts
B = Disc_interp(discounts, dates, payment_dates(2:end));
B_new = Disc_interp(discounts_new, dates, payment_dates(2:end));

% Compute NPV
delta_time = yearfrac(payment_dates(1:end-1),payment_dates(2:end),6);
BPV = sum(delta_time.*B);
BPV_shifted = sum(delta_time.*B_new);
NPV = 1 - B(end) - fixed_rate.*BPV;
NPV_shifted = 1 - B_new(end) - fixed_rate.*BPV_shifted;

% DV01 computation
DV01 = NPV_shifted - NPV;

end