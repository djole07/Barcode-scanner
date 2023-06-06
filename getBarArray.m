function [one_bar_arr, two_bar_arr, three_bar_arr, four_bar_arr] = getBarArray(arr)
    m = mean(arr);
    one_bar_arr = arr(arr < m);
    arr = arr(arr > m);
    
    m = mean(arr);
    two_bar_arr = arr(arr < m);
    arr = arr(arr > m);
    
    m = mean(arr);
    three_bar_arr = arr(arr < m);
    
    four_bar_arr = arr(arr>m);
end

