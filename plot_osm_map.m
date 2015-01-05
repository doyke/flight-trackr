function varargout = plot_osm_map(varargin)
% function h = plot_osm_map(varargin)
% Plots a OSM map on the current axes using the Static MapBox API
%
% USAGE:
% h = plot_osm_map(Property, Value,...)
% Plots the map on the given axes. Used also if no output is specified
%
%
% PROPERTIES:
%    Marker         - The marker argument is a text string with fields
%                     conforming to the MapBox API.
% OUTPUT:
%    h              - Handle to the plotted map
%
%    lonVect        - Vector of Longidute coordinates (WGS84) of the image 
%    latVect        - Vector of Latidute coordinates (WGS84) of the image 
%    imag           - Image matrix (height,width,3) of the map
%
%
% References:
%  http://www.mathworks.com/matlabcentral/fileexchange/24113
%
% Author:
%  Zohar Bar-Yehuda
%  Charlie Huynh
%  Benjamin Fovet

persistent apiKey
if isnumeric(apiKey)
    % first run, check if API key file exists
    if exist('api_key.mat','file')
        load api_key
    else
        apiKey = 'pk.eyJ1IjoiY2h1eW5oIiwiYSI6IjVVZ1pMeDgifQ.7dv9hm4hnTsh_76HPVqE0A';
    end
end
hold on

% Default parametrs
axHandle = gca;
height = 1280;
width = 1280;
scale = 1;
alphaData = 1;
figureResizeUpdate = 1;
autoAxis = 1;
marker = '';

% Handle input arguments
if nargin >= 2
    for idx = 1:2:length(varargin)
        switch lower(varargin{idx})
            case 'axis'
                axHandle = varargin{idx+1};
            case 'marker'
                marker = [varargin{idx+1} '/'];
            otherwise
                error(['Unrecognized variable: ' varargin{idx}])
        end
    end
end

% Store paramters in axis handle (for auto refresh callbacks)
ud = get(axHandle, 'UserData');
ud.gmap_params = varargin;
set(axHandle, 'UserData', ud);

curAxis = axis(axHandle);
% Enforce Latitude constraints of EPSG:900913 
if curAxis(3) < -85
    curAxis(3) = -85;
end
if curAxis(4) > 85
    curAxis(4) = 85;
end
% Enforce longitude constrains
if curAxis(1) < -180
    curAxis(1) = -180;
end
if curAxis(1) > 180
    curAxis(1) = 0;
end
if curAxis(2) > 180
    curAxis(2) = 180;
end
if curAxis(2) < -180
    curAxis(2) = 0;
end

if isequal(curAxis,[0 1 0 1]) % probably an empty figure
    % display world map
    curAxis = [-200 200 -85 85];
    axis(curAxis)
end

if autoAxis
    % adjust current axis limit to avoid strectched maps
    [xExtent,yExtent] = latLonToMeters(curAxis(3:4), curAxis(1:2) );
    xExtent = diff(xExtent); % just the size of the span
    yExtent = diff(yExtent); 
    % get axes aspect ratio
    drawnow
    org_units = get(axHandle,'Units');
    set(axHandle,'Units','Pixels')
    ax_position = get(axHandle,'position');        
    set(axHandle,'Units',org_units)
    aspect_ratio = ax_position(4) / ax_position(3);
    
    if xExtent*aspect_ratio > yExtent        
        centerX = mean(curAxis(1:2));
        centerY = mean(curAxis(3:4));
        spanX = (curAxis(2)-curAxis(1))/2;
        spanY = (curAxis(4)-curAxis(3))/2;
       
        % enlarge the Y extent
        spanY = spanY*xExtent*aspect_ratio/yExtent; % new span
        if spanY > 85
            spanX = spanX * 85 / spanY;
            spanY = spanY * 85 / spanY;
        end
        curAxis(1) = centerX-spanX;
        curAxis(2) = centerX+spanX;
        curAxis(3) = centerY-spanY;
        curAxis(4) = centerY+spanY;
    elseif yExtent > xExtent*aspect_ratio
        
        centerX = mean(curAxis(1:2));
        centerY = mean(curAxis(3:4));
        spanX = (curAxis(2)-curAxis(1))/2;
        spanY = (curAxis(4)-curAxis(3))/2;
        % enlarge the X extent
        spanX = spanX*yExtent/(xExtent*aspect_ratio); % new span
        if spanX > 180
            spanY = spanY * 180 / spanX;
            spanX = spanX * 180 / spanX;
        end
        
        curAxis(1) = centerX-spanX;
        curAxis(2) = centerX+spanX;
        curAxis(3) = centerY-spanY;
        curAxis(4) = centerY+spanY;
    end            
    % Enforce Latitude constraints of EPSG:900913
    if curAxis(3) < -85
        curAxis(3:4) = curAxis(3:4) + (-85 - curAxis(3));
    end
    if curAxis(4) > 85
        curAxis(3:4) = curAxis(3:4) + (85 - curAxis(4));
    end
    axis(axHandle, curAxis); % update axis as quickly as possible, before downloading new image
    drawnow
end

% Delete previous map from plot (if exists)
if nargout <= 1 % only if in plotting mode
    curChildren = get(axHandle,'children');
    map_objs = findobj(curChildren,'tag','gmap');
    bd_callback = [];
    for idx = 1:length(map_objs)
        if ~isempty(get(map_objs(idx),'ButtonDownFcn'))
            % copy callback properties from current map
            bd_callback = get(map_objs(idx),'ButtonDownFcn');
        end
    end
    delete(map_objs)
    
end

% Calculate zoom level for current axis limits
[xExtent,yExtent] = latLonToMeters(curAxis(3:4), curAxis(1:2) );
minResX = diff(xExtent) / width;
minResY = diff(yExtent) / height;
minRes = max([minResX minResY]);
initialResolution = 156543.033928041;
zoomlevel = floor(log2(initialResolution/minRes));

% Enforce valid zoom levels
if zoomlevel < 0 
    zoomlevel = 0;
end
if zoomlevel > 19 
    zoomlevel = 19;
end

% Calculate center coordinate in WGS1984
lat = (curAxis(3)+curAxis(4))/2;
lon = (curAxis(1)+curAxis(2))/2;

% Construct query URL
preamble = 'http://api.tiles.mapbox.com/v4/';
mapid = 'chuynh.kjigeh07/';
location = [num2str(lon,10) ',' num2str(lat,10)];
zoomStr = [',' num2str(zoomlevel)];
sizeStr = ['/' num2str(width) 'x' num2str(height)];
if (scale == 2)
    sizeStr = [sizeStr '@2x'];
end
if ~isempty(apiKey)
    keyStr = ['?access_token=' apiKey];
else
    keyStr = '';
end
    
filename = 'tmp.jpg';
format = '.jpg90';
url = [preamble mapid marker location zoomStr sizeStr format keyStr];
% Get the image
try
    urlwrite(url, filename);
catch % error downloading map
    sprintf(['Unable to download map form OSM Servers.\n' ...
        'Possible reasons: no network connection, quota exceeded, or some other error.\n' ...
        'Consider using an API key if quota problems persist.\n\n' ...
        'To debug, try pasting the following URL in your browser, which may result in a more informative error:\n%s'], url);
    varargout{1} = [];
    varargout{2} = [];
    varargout{3} = [];
    return
end
M = imread(filename);
M = cast(M,'double');
delete(filename); % delete temp file
width = size(M,2);
height = size(M,1);

% Calculate a meshgrid of pixel coordinates in EPSG:900913
centerPixelY = round(height/2);
centerPixelX = round(width/2);
[centerX,centerY] = latLonToMeters(lat, lon ); % center coordinates in EPSG:900913
curResolution = initialResolution / 2^zoomlevel/scale; % meters/pixel (EPSG:900913)
xVec = centerX + ((1:width)-centerPixelX) * curResolution; % x vector
yVec = centerY + ((height:-1:1)-centerPixelY) * curResolution; % y vector
[xMesh,yMesh] = meshgrid(xVec,yVec); % construct meshgrid 

% convert meshgrid to WGS1984
[lonMesh,latMesh] = metersToLatLon(xMesh,yMesh);

imag = M/255;
sizeFactor = 1;
uniHeight = round(height*sizeFactor);
uniWidth = round(width*sizeFactor);
latVect = linspace(latMesh(1,1),latMesh(end,1),uniHeight);
lonVect = linspace(lonMesh(1,1),lonMesh(1,end),uniWidth);
[uniLonMesh,uniLatMesh] = meshgrid(lonVect,latVect);
uniImag =  myTurboInterp2(lonMesh,latMesh,imag,uniLonMesh,uniLatMesh);

% Next, project the data into a uniform WGS1984 grid
sizeFactor = 1; % factoring of new image
uniHeight = round(height*sizeFactor);
uniWidth = round(width*sizeFactor);
latVect = linspace(latMesh(1,1),latMesh(end,1),uniHeight);
lonVect = linspace(lonMesh(1,1),lonMesh(1,end),uniWidth);

if nargout <= 1 % plot map
    % display image
    hold(axHandle, 'on');
    h = image(lonVect,latVect, uniImag, 'Parent', axHandle);
    set(axHandle,'YDir','Normal')
    set(h,'tag','gmap')
    set(h,'AlphaData', alphaData)
    
    % add a dummy image to allow pan/zoom out to x2 of the image extent
    h_tmp = image(lonVect([1 end]),latVect([1 end]),zeros(2),'Visible','off', 'Parent', axHandle);
    set(h_tmp,'tag','gmap')
   
    uistack(h,'bottom') % move map to bottom (so it doesn't hide previously drawn annotations)
    axis(axHandle, curAxis) % restore original zoom
    if nargout == 1
        varargout{1} = h;
    end
    
    % if auto-refresh mode - override zoom callback to allow autumatic 
    % refresh of map upon zoom actions.
    figHandle = axHandle;
    while ~strcmpi(get(figHandle, 'Type'), 'figure')
        % Recursively search for parent figure in case axes are in a panel
        figHandle = get(figHandle, 'Parent');
    end
    
    zoomHandle = zoom(axHandle);   
    panHandle = pan(figHandle); % This isn't ideal, doesn't work for contained axis    
   
    set(zoomHandle,'ActionPostCallback',@update_osm_map);
    set(panHandle, 'ActionPostCallback', @update_osm_map);
    
    % set callback for figure resize function, to update extents if figure
    % is streched.
    if figureResizeUpdate &&isempty(get(figHandle, 'ResizeFcn'))
        % set only if not already set by someone else
        set(figHandle, 'ResizeFcn', @update_osm_map_fig);       
    end    
    
    % set callback properties 
    set(h,'ButtonDownFcn',bd_callback);
else % don't plot, only return map
    varargout{1} = lonVect;
    varargout{2} = latVect;
    varargout{3} = uniImag;
end
end

% Coordinate transformation functions
function ZI = myTurboInterp2(X,Y,Z,XI,YI)
% An extremely fast nearest neighbour 2D interpolation, assuming both input
% and output grids consist only of squares, meaning:
% - uniform X for each column
% - uniform Y for each row
XI = XI(1,:);
X = X(1,:);
YI = YI(:,1);
Y = Y(:,1);

xiPos = nan*ones(size(XI));
xLen = length(X);
yiPos = nan*ones(size(YI));
yLen = length(Y);
% find x conversion
xPos = 1;
for idx = 1:length(xiPos)
    if XI(idx) >= X(1) && XI(idx) <= X(end)
        while xPos < xLen && X(xPos+1)<XI(idx)
            xPos = xPos + 1;
        end
        diffs = abs(X(xPos:xPos+1)-XI(idx));
        if diffs(1) < diffs(2)
            xiPos(idx) = xPos;
        else
            xiPos(idx) = xPos + 1;
        end
    end
end
% find y conversion
yPos = 1;
for idx = 1:length(yiPos)
    if YI(idx) <= Y(1) && YI(idx) >= Y(end)
        while yPos < yLen && Y(yPos+1)>YI(idx)
            yPos = yPos + 1;
        end
        diffs = abs(Y(yPos:yPos+1)-YI(idx));
        if diffs(1) < diffs(2)
            yiPos(idx) = yPos;
        else
            yiPos(idx) = yPos + 1;
        end
    end
end
ZI = Z(yiPos,xiPos,:);
end

function [lon,lat] = metersToLatLon(x,y)
% Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum
originShift = 20037508.342789244;
lon = (x ./ originShift) * 180;
lat = (y ./ originShift) * 180;
lat = 180 / pi * (2 * atan( exp( lat * pi / 180)) - pi / 2);
end

function [x,y] = latLonToMeters(lat, lon )
% Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913"
originShift = 20037508.342789244;
x = lon * originShift / 180;
y = log(tan((90 + lat) * pi / 360 )) / (pi / 180);
y = y * originShift / 180;
end

function update_osm_map(obj,evd)
% callback function for auto-refresh
drawnow;
try
    axHandle = evd.Axes;
catch ex
    % Event doesn't contain the correct axes. Panic!
    axHandle = gca;
end
ud = get(axHandle, 'UserData');
if isfield(ud, 'gmap_params')
    params = ud.gmap_params;
    plot_osm_map(params{:});
end
end

function update_osm_map_fig(obj,evd)
% callback function for auto-refresh
drawnow;
axes_objs = findobj(get(gcf,'children'),'type','axes');
for idx = 1:length(axes_objs)
    if ~isempty(findobj(get(axes_objs(idx),'children'),'tag','gmap'));
        ud = get(axes_objs(idx), 'UserData');
        if isfield(ud, 'gmap_params')
            params = ud.gmap_params;
        else
            params = {};
        end
        
        % Add axes to inputs if needed
        if ~sum(strcmpi(params, 'Axis'))
            params = [params, {'Axis', axes_objs(idx)}];
        end
        plot_osm_map(params{:});
    end
end
end