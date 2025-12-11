function [AllComp, FastComp, SlowComp, AllEvents, FastEvents, SlowEvents] = ...
    composite_olr(time, olr_EQ_ave, data_all, data_fast, data_slow, win)
%COMPOSITE_OLR  Composite OLR fields around MJO Day0 for all/fast/slow events.
%
%   [AllComp, FastComp, SlowComp, AllEvents, FastEvents, SlowEvents] = ...
%       COMPOSITE_OLR(time, olr_EQ_ave, data_all, data_fast, data_slow, win)
%
%   INPUT
%     time        : [nTime x 3] 时间数组 [year month day]
%     olr_EQ_ave  : [nLon x nTime] 赤道带平均 OLR (2.5°×2.5°，或其他经向分辨率)
%     data_all    : classify_mjo_speed 输出的 data_all
%     data_fast   : classify_mjo_speed 输出的 data_fast
%     data_slow   : classify_mjo_speed 输出的 data_slow
%     win         : 合成窗口半宽 (天)，默认 30，即 [-30:+30]
%
%   OUTPUT
%     AllComp     : [nLon x (2*win+1)] 所有事件的 OLR 合成
%     FastComp    : [nLon x (2*win+1)] 快速 MJO 的 OLR 合成
%     SlowComp    : [nLon x (2*win+1)] 慢速 MJO 的 OLR 合成
%     AllEvents   : [nLon x (2*win+1) x nEvt_all] 全部单个事件的切片
%     FastEvents  : [nLon x (2*win+1) x nFast]    fast 子集切片
%     SlowEvents  : [nLon x (2*win+1) x nSlow]    slow 子集切片
%
%   说明：
%     - 逻辑：
%         对每个事件，找到 Day0 日期 → 截取 [Day0-win : Day0+win] →
%         在最后对所有事件做平均。
%     - 若 Day0 接近时间序列边缘，导致 window 越界，则该事件会被跳过并警告。
%

if nargin < 6 || isempty(win)
    win = 30;
end

[nLon, nTime] = size(olr_EQ_ave);
nDayWin       = 2*win + 1;

%% 帮助函数：给一组事件 dataX 做合成
    function [Comp, Events] = do_composite(dataX, label)
        if isempty(dataX)
            Comp   = nan(nLon, nDayWin);
            Events = nan(nLon, nDayWin, 0);
            return;
        end

        evt_cells = {};  % 每个 cell 一个 [nLon x nDayWin] 事件切片

        for ii = 1:size(dataX,1)
            Y = dataX(ii,7);
            M = dataX(ii,8);
            D = dataX(ii,9);

            % 查找 time 中对应日期
            idx = find(time(:,1)==Y & time(:,2)==M & time(:,3)==D, 1);
            if isempty(idx)
                warning('%s: Day0 not found in time array: %04d-%02d-%02d', ...
                        label, Y, M, D);
                continue;
            end

            if (idx - win < 1) || (idx + win > nTime)
                warning('%s: Day0 window out of range, skip event: %04d-%02d-%02d', ...
                        label, Y, M, D);
                continue;
            end

            % 截取 [Day0-win : Day0+win]
            bb = olr_EQ_ave(:, idx-win : idx+win);  % [nLon x nDayWin]
            evt_cells{end+1} = bb;                  %#ok<AGROW>
        end

        nEvt = numel(evt_cells);
        if nEvt == 0
            Comp   = nan(nLon, nDayWin);
            Events = nan(nLon, nDayWin, 0);
            return;
        end

        Events = zeros(nLon, nDayWin, nEvt);
        for k = 1:nEvt
            Events(:,:,k) = evt_cells{k};
        end

        Comp = mean(Events, 3, 'omitnan');
    end

%% All / Fast / Slow 三类合成
[AllComp,  AllEvents]  = do_composite(data_all,  'ALL');
[FastComp, FastEvents] = do_composite(data_fast, 'FAST');
[SlowComp, SlowEvents] = do_composite(data_slow, 'SLOW');

end

