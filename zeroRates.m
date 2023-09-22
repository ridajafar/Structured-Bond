function zRates = zeroRates(dates, discounts) 
% Compute zero rates ( in percentage unit, e.g. 2.13 stands for 2.13%) from 
% dates and discounts
%
% INPUT
% dates:        dates on which we have discounts
% discounts:    discounts 

zRates = -100*log(discounts(2:end))./yearfrac(dates(1),dates(2:end),3);

end