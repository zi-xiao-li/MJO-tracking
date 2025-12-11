function [olr_EQ_ave, olr_std, olr_mean, eq_time] = ...
    compute_equatorial_olr(fn_mjo, lat_N, lat_S, t_start, t_end)
%COMPUTE_EQUATORIAL_OLR  Zonal mean OLR over equatorial band.
%
%   [olr_EQ_ave, olr_std, olr_mean, time] = COMPUTE_EQUATORIAL_OLR(
%       fn_mjo, lat_N, lat_S, t_start, t_end)
%
%   fn_mjo : NetCDF file with variables 'olr','lat','lon'
%   lat_N  : northern bound (deg, e.g. 5)
%   lat_S  : southern bound (deg, e.g. -5)
%   t_start, t_end : years for clipping (e.g. 1979, 2014)
%

lat      = ncread(fn_mjo,'lat');
lon      = ncread(fn_mjo,'lon');
olr      = ncread(fn_mjo,'olr');

% time 仍然从原始 OLR 文件转换
time_raw = ncread('D:\project\data\0\olr.day.mean.nc','time');
time_days = (time_raw - time_raw(1))/24;

t1       = datetime('1974-06-01');
jd1      = juliandate(t1);
t_jd     = jd1 + time_days;
t_dt     = datetime(t_jd, 'convertfrom','juliandate');
[yy,mm,dd] = ymd(t_dt);
time_full  = [yy mm dd];

% clip to [t_start, t_end]
idx  = (yy >= t_start) & (yy <= t_end);
time = time_full(idx,:);
olr  = olr(:,:,idx);

% remove leap days (和 preprocess_olr 一样逻辑)
is_leap   = (time(:,2)==2 & time(:,3)==29);
time(is_leap,:) = [];
olr(:,:,is_leap) = [];

% equatorial averaging
[~,I1] = min(abs(lat - lat_N));
[~,I2] = min(abs(lat - lat_S));
olr_EQ  = olr(:,I1:I2,:);   % lon x lat x time

olr_EQ_ave = squeeze(mean(olr_EQ, 2));   % lon x time

% 每个 longitude 的 climatology mean/std
olr_std  = std(olr_EQ_ave, 0, 2);  % lon x 1
olr_mean = mean(olr_EQ_ave, 2);    % lon x 1

eq_time = time;
end

