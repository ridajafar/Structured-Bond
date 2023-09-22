function swap_dates = SwapDates(swaps)
% Computes the complete set of swap dates 

% INPUT:
% swaps: swaps dates we already have

swap_dates = zeros(49,1);
swap_dates(1:11) = swaps(1:11);

for i=12:49
    day = weekday(datenum(2023+i+1,02,02));
    if day==1
        swap_dates(i) = datenum(2023+i+1,02,03);
    elseif day==7
        swap_dates(i) = datenum(2023+i+1,02,04);
    else 
        swap_dates(i) = datenum(2023+i+1,02,02);
    end
end

end