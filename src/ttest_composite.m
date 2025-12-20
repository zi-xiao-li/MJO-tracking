function [t_fast, t_slow, Xn_fast, Xn_slow, std_fast, std_slow] = ...
    ttest_composite(FastEvents, SlowEvents)
%TTEST_COMPOSITE  One-sample t test for fast/slow MJO OLR composites.
%
%   [t_fast, t_slow, Xn_fast, Xn_slow, std_fast, std_slow] = ...
%       TTEST_COMPOSITE(FastEvents, SlowEvents)
%
%   INPUT
%     FastEvents : [nLon x nDay x nFast] 单个 fast MJO 事件的 OLR 切片
%     SlowEvents : [nLon x nDay x nSlow] 单个 slow MJO 事件的 OLR 切片
%
%   OUTPUT
%     t_fast     : [nLon x nDay] fast MJO 合成的 t-statistic
%     t_slow     : [nLon x nDay] slow MJO 合成的 t-statistic
%     Xn_fast    : [nLon x nDay] fast 样本均值
%     Xn_slow    : [nLon x nDay] slow 样本均值
%     std_fast   : [nLon x nDay] fast 样本标准差
%     std_slow   : [nLon x nDay] slow 样本标准差


%% Fast 部分
if isempty(FastEvents) || size(FastEvents,3) == 0
    t_fast   = [];
    Xn_fast  = [];
    std_fast = [];
else
    nFast    = size(FastEvents, 3);
    Xn_fast  = mean(FastEvents, 3, 'omitnan');
    std_fast = std(FastEvents, 0, 3, 'omitnan');

    % 避免除零
    denom_fast        = std_fast ./ sqrt(nFast);
    denom_fast(denom_fast == 0) = NaN;

    t_fast = Xn_fast ./ denom_fast;
    t_fast(isnan(t_fast)) = 0;
end

%% Slow 部分
if isempty(SlowEvents) || size(SlowEvents,3) == 0
    t_slow   = [];
    Xn_slow  = [];
    std_slow = [];
else
    nSlow    = size(SlowEvents, 3);
    Xn_slow  = mean(SlowEvents, 3, 'omitnan');
    std_slow = std(SlowEvents, 0, 3, 'omitnan');

    denom_slow        = std_slow ./ sqrt(nSlow);
    denom_slow(denom_slow == 0) = NaN;

    t_slow = Xn_slow ./ denom_slow;
    t_slow(isnan(t_slow)) = 0;
end

end
