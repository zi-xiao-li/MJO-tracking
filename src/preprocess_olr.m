function [time_out, olr_out, lat, lon] = preprocess_olr(fn_in, fn_out, t_start, t_end, base_date)
%PREPROCESS_OLR  Prepare daily OLR for MJO tracking (remove leap days).
%
%   [time_out, olr_out, lat, lon] = PREPROCESS_OLR(fn_in, fn_out, t_start, t_end, base_date)
%
%   INPUT:
%       fn_in    - input NetCDF path, e.g. 'data/raw/olr.day.mean.nc'
%       fn_out   - output NetCDF path, e.g. 'data/processed/olr_1979_2013.nc'
%       t_start  - starting year, e.g. 1979
%       t_end    - ending year, e.g. 2013 or 2014
%       base_date- datetime of the "time=0" origin in fn_in, 
%                  e.g. datetime('1974-06-01')
%
%   OUTPUT:
%       time_out - [N x 3] array [year, month, day] after removing Feb-29
%       olr_out  - OLR (lon x lat x time), leap days removed
%       lat, lon - latitude and longitude vectors
%
%   This function:
%     1) reads daily OLR, lat, lon and time
%     2) converts model time to Gregorian calendar
%     3) clips to [t_start, t_end]
%     4) removes leap days
%     5) writes a clean NetCDF for later analysis
%
%   Author: Xinyu Li
%   Date  : 2025
% ---------------------------------------------------------------------

%% 1. Read original NetCDF
lat = ncread(fn_in, 'lat');
lon = ncread(fn_in, 'lon');
olr_raw  = ncread(fn_in, 'olr');
time_raw = ncread(fn_in, 'time');    % units: hours since base_date

% convert hours → days relative to first element
time_days = (time_raw - time_raw(1)) ./ 24;

% convert to calendar datetime
jd0       = juliandate(base_date);
t_jd      = jd0 + time_days;
t_dt      = datetime(t_jd, 'convertfrom', 'juliandate');
[yy, mm, dd] = ymd(t_dt);
time_full = [yy mm dd];

%% 2. Clip to [t_start, t_end]
idx = (yy >= t_start) & (yy <= t_end);
olr  = olr_raw(:,:,idx);
time = time_full(idx,:);

%% 3. Remove leap days (Feb-29)
is_leap = (time(:,2) == 2 & time(:,3) == 29);
olr(:,:,is_leap) = [];
time(is_leap,:)  = [];

% 重新构造 "日序号"（1~365），方便后面用
n_year  = t_end - t_start + 1;
n_day   = 365;
day_idx = zeros(size(time,1), 1);

for yr = 1:n_year
    this_year = t_start + yr - 1;
    mask      = (time(:,1) == this_year);
    nn        = sum(mask);
    % 理论上 nn 应该是 365，如果有问题可以加一个 assert
    day_idx(mask) = 1:nn;
end

time_out = time;
% 这里可以根据需要把 day_idx 保存到第四列
% time_out(:,4) = day_idx;

%% 4. Write to new NetCDF
if ~isempty(fn_out)
    if exist(fileparts(fn_out), 'dir') ~= 7
        mkdir(fileparts(fn_out));
    end

    ncid = netcdf.create(fn_out, 'CLOBBER');

    dim_lon  = netcdf.defDim(ncid,'lon',size(olr,1)); 
    dim_lat  = netcdf.defDim(ncid,'lat',size(olr,2));    
    dim_time = netcdf.defDim(ncid,'time',size(olr,3));

    % lon
    varid_lon = netcdf.defVar(ncid,'lon','double',dim_lon);
    netcdf.putAtt(ncid,varid_lon,'standard_name','longitude');
    netcdf.putAtt(ncid,varid_lon,'units','degrees_east');

    % lat
    varid_lat = netcdf.defVar(ncid,'lat','double',dim_lat);
    netcdf.putAtt(ncid,varid_lat,'standard_name','latitude');
    netcdf.putAtt(ncid,varid_lat,'units','degrees_north');

    % time: 简单用 1:N 表示
    varid_time = netcdf.defVar(ncid,'time','double',dim_time);
    netcdf.putAtt(ncid,varid_time,'standard_name','time');
    netcdf.putAtt(ncid,varid_time,'units', ...
        sprintf('days since %4d-01-01 00:00:00', t_start));

    % olr
    varid_olr = netcdf.defVar(ncid,'olr','double',[dim_lon dim_lat dim_time]);
    netcdf.putAtt(ncid,varid_olr,'_FillValue',-9999);
    netcdf.putAtt(ncid,varid_olr,'missing_value',-9999);

    netcdf.endDef(ncid);

    netcdf.putVar(ncid,varid_olr,olr);
    netcdf.putVar(ncid,varid_lon,lon);
    netcdf.putVar(ncid,varid_lat,lat);
    netcdf.putVar(ncid,varid_time,1:size(olr,3));

    netcdf.close(ncid);
end

olr_out = olr;
end

