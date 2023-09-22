function [DV01, BPV, DV01_z] = sensSwap(setDate, fixedLegPaymentDates, fixedRate, dates, discounts,discounts_DV01)
% Compiutes the sensitivities for a portfolio composed by 1 plain vanilla
% 6y IR swap vs Euribor 3m 

% INPUT 
% setDate:              date in which the contract is set
% fixedLegPaymentDates: payments dates for the fixed leg
% fixedRate:            fixed rate
% dates:                complete set of dates
% discounts:            complete set of discounts
% discounts_DV01:       set of shifted discounts (in order to determine the DV01)


%% DV01

% Computing the Floating Leg Present Value 
firstRate_factor = interp1(dates(2:end), zeroRates(dates,discounts),fixedLegPaymentDates(2))/100;
firstDiscountfactor = exp(-firstRate_factor*yearfrac(setDate,fixedLegPaymentDates(2),3));
Yearly_discounts =[ firstDiscountfactor ; discounts(13:17)];
FloatingLegPresentValue = 1- Yearly_discounts(end);

% Computing the Fixed Leg Present Value 
FixedLegPresValue = fixedRate*sum(Yearly_discounts.*yearfrac(fixedLegPaymentDates(1:end-1),fixedLegPaymentDates(2:end),6));

% Computing the Net Present Value
NPV_old = FloatingLegPresentValue - FixedLegPresValue ;

% Computing the Floating Leg Present Value (DV01)
firstRate_factor_new = interp1(dates(2:end), zeroRates(dates,discounts_DV01),fixedLegPaymentDates(2))/100;
firstDiscountfactor_new = exp(-firstRate_factor_new*yearfrac(fixedLegPaymentDates(1),fixedLegPaymentDates(2),3));
Yearly_discounts_new =[ firstDiscountfactor_new ; discounts_DV01(13:17)];
FloatingLegPresentValue_new = 1 - Yearly_discounts_new(end);

% Computing the Fixed Leg Present Value (DV01)
FixedLegPresValue_new = fixedRate*sum(Yearly_discounts_new.*yearfrac(fixedLegPaymentDates(1:end-1),fixedLegPaymentDates(2:end),6));

% Computing the Net Present Value (DV01)
NPV_new = FloatingLegPresentValue_new - FixedLegPresValue_new ;

% Computing DV01
DV01 = NPV_new - NPV_old;


%% DV01z 

% Computing DV01z new rates
r = zeroRates(fixedLegPaymentDates,[1 ; Yearly_discounts])/100;
r_DV01z = (r+1e-4);
Yearly_Discounts_DV01z = exp(-r_DV01z.*yearfrac(fixedLegPaymentDates(1),fixedLegPaymentDates(2:end),3));

% Computing the Floating Leg Present Value (DV01z)
FloatingLegPresentValue_new_DV01z = 1 - Yearly_Discounts_DV01z(end);

% Computing the Fixed Leg Present Value (DV01z)
FixedLegPresValue_new_DV01z = fixedRate*sum(Yearly_Discounts_DV01z.*yearfrac(fixedLegPaymentDates(1:end-1),fixedLegPaymentDates(2:end),6));

% Computing the Net Present Value (DV01z)
NPV_new_DV01z = FloatingLegPresentValue_new_DV01z - FixedLegPresValue_new_DV01z;

% Computing DV01z
DV01_z = NPV_new_DV01z - NPV_old;

%% BPV

% Computing the Floating Leg Present Value (BPV)
FloatingLegPresentValue = 1- Yearly_discounts(end);

% Computing the Fixed Leg Present Value (BPV)
FixedLegPresValue = (fixedRate+1e-4)*sum(Yearly_discounts.*yearfrac(fixedLegPaymentDates(1:end-1),fixedLegPaymentDates(2:end),6));

% Computing the Net Present Value (BPV)
NPV_BPV = FloatingLegPresentValue - FixedLegPresValue;

% Computing BPV
BPV=abs(NPV_BPV-NPV_old);


end