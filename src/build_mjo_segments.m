function Seg = build_mjo_segments(olr_EQ_ave, lon, time, IO_lon, ...
                                  seg_lon1, seg_lon2)
%BUILD_MJO_SEGMENTS  Identify MJO minima at IO and build longitude segments.
%
%   Seg = BUILD_MJO_SEGMENTS(olr_EQ_ave, lon, time, IO_lon, seg_lon1, seg_lon2)
%
%   INPUT:
%       olr_EQ_ave : lon x time (equatorial mean OLR)
%       lon        : lon vector
%       time       : [N x 3] [year month day]
%       IO_lon     : reference lon for IO index (e.g. 90)
%       seg_lon1   : western lon of segment (e.g. 20)
%       seg_lon2   : eastern lon of segment (e.g. 220)
%
%   OUTPUT (struct Seg):
%       Seg.OLR        : [nLonSeg x nDay x nYear]
%       Seg.Time       : [nDay x 3 x nYear]
%       Seg.t0_year    : 1 x nYear cell, each cell is [nEventYear x 3] dates
%       Seg.Lon        : lon segment vector (deg)
%       Seg.std        : [nLonSeg x 1] std
%       Seg.mean       : [nLonSeg x 1] mean
%

%% IO index at 90E
[~, I_IO] = min(abs(lon - IO_lon));
MJO_index = olr_EQ_ave(I_IO,:); 
IO_std  = std(MJO_index);
IO_mean = mean(MJO_index);

% 极小值 + < 1SD
MJO_date_idx = [];
MJO_min_val  = [];
for s = 2:length(MJO_index)-1
    B = MJO_index(s);
    if B < MJO_index(s-1) && B < MJO_index(s+1) && ...
       B < IO_mean - IO_std
        MJO_date_idx = [MJO_date_idx s];
        MJO_min_val  = [MJO_min_val B];
    end
end

fprintf('Total MJO events (all seasons): %d\n', numel(MJO_date_idx));

% all minima dates
count2 = time(MJO_date_idx,1:3);
count2(:,4) = MJO_min_val;   % 第4列存 index

% 经向 segment
[~,I6] = min(abs(lon - seg_lon1));
[~,I7] = min(abs(lon - seg_lon2));
Segment_OLR_ALL = olr_EQ_ave(I6:I7,:);  % lonSeg x time
Segment_Lon     = lon(I6:I7);

% 1979.10.1 – 2014.5.31
idx1 = find(time(:,1)==1979 & time(:,2)==10 & time(:,3)==1);
idx2 = find(time(:,1)==2014 & time(:,2)==5  & time(:,3)==31);
seg_olr  = Segment_OLR_ALL(:,idx1:idx2);
seg_time = time(idx1:idx2,:);

% 取 boreal winter (O–M)，这一步可以将来改成可配置
winter_mask = ismember(seg_time(:,2), [10 11 12 1 2 3 4 5]);
seg_time_w = seg_time(winter_mask,:);
seg_olr_w  = seg_olr(:,winter_mask);

% 划分按“冬季”分段
Segment_anual_number = 243;   % 可以做成参数
n_year = size(seg_time_w,1) / Segment_anual_number;

Segment_OLR = zeros(size(seg_olr_w,1), Segment_anual_number, n_year);
Segment_Time = zeros(Segment_anual_number, 3, n_year);

for yr = 1:n_year
    idx = (1:Segment_anual_number) + (yr-1)*Segment_anual_number;
    Segment_OLR(:,:,yr)  = seg_olr_w(:,idx);
    Segment_Time(:,:,yr) = seg_time_w(idx,1:3);
end

% 把每一年冬季的 t0 提出来
Segment_t0_separate = cell(1, n_year);
for yr = 1:n_year
    yy1 = 1978 + yr;
    yy2 = 1979 + yr;
    a1  = count2(count2(:,1)==yy1,:);
    a2  = count2(count2(:,1)==yy2,:);
    First_Year = a1(ismember(a1(:,2), [11 12]), :);
    Last_Year  = a2(ismember(a2(:,2), [1 2 3 4]), :);
    Segment_t0_separate{yr} = [First_Year; Last_Year];
end

% std/mean over segment lon
olr_std  = std(olr_EQ_ave,0,2);
olr_mean = mean(olr_EQ_ave,2);

Seg.OLR     = Segment_OLR;
Seg.Time    = Segment_Time;
Seg.t0_year = Segment_t0_separate;
Seg.Lon     = Segment_Lon;
Seg.std     = olr_std(I6:I7);
Seg.mean    = olr_mean(I6:I7);
Seg.time_all= time;
end

