function B = Disc_interp(discounts, dates, target)
% Interpolates the discounts on target
%
% INPUT
% discounts:    discounts on dates
% dates:        dates on which we have discounts
% target:       dates on which we have B as discounts


r=zeroRates(dates,discounts)/100;
B=zeros(length(target),1);
 
for i=1:length(target)

 if target(i) < max(dates) 
    r_fut = interp1(dates(2:end),r,target(i));
    B(i) = exp(-r_fut*yearfrac(dates(1),target(i),3));
 else 
    r_fut = interp1(dates,r,target(i),'linear',r(end));
    B(i) = exp(-r_fut*yearfrac(dates(1),target(i),3));
 end

end

end