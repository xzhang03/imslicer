function imslicer(tifpath, nrow, ncol, varargin)
%imslicer slices images for batch processing

if nargin < 4
    varargin = {};
    if nargin < 3
        ncol = [];
        nrow = [];
        if nargin < 1
            tifpath = '';
        end
    end
end

p = inputParser;

addOptional(p, 'defaultpath', '\\nasquatch\data\2p'); % Give default path for ui
addOptional(p, 'force', false);

% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% IO
% Path parsing
if isempty(tifpath)
    [fn, fp] = uigetfile(fullfile(p.defaultpath, '*.tif'));
    [~, fn, ext] = fileparts(fn);
else
    [fp, fn, ext] = fileparts(tifpath);
end


% output folder
if ~exist(fullfile(fp, fn), 'dir')
    mkdir(fullfile(fp, fn))
end

% output filename
fnout = fullfile(fp, fn, [fn, '_']);
fpara = fullfile(fp, fn, [fn, '_sliceparam.mat']);

% Get parameters
if exist(fpara, 'file') && p.force
    doslice = true;
elseif exist(fpara, 'file') && ~p.force
    doslice = input('Slices already exist, reslice? (1 = yes, 0 - no): ');
    doslice = doslice == 1;
else
    doslice = true;
end


%% Sizes
if doslice
    % Read
    try
        im = readtiff(fullfile(fp, [fn, ext]));
    catch
        im = imread(fullfile(fp, [fn, ext]));
    end

    % size
    sizevec = size(im);
    
    if isempty(nrow) || isempty(ncol)
        % Figures
        figure;
        imshow(im);
        
        % User input
        prompt = {'Enter the number of rows:','Enter the number of columns:'};
        dlgtitle = 'Rows and columns';
        dims = [1 35];
        definput = {'3','2'};
        
        % Parse input
        answer = inputdlg(prompt,dlgtitle,dims,definput);
        nrow = str2double(answer{1});
        ncol = str2double(answer{2});
    end
    
    % number of files
    nfiles = nrow * ncol;
    
    % panel size
    panelsizevec = ceil(sizevec ./ [nrow ncol]);
end

%% Output
ind = 0;
for icol = 1 : ncol
    for irow = 1: nrow
        % Ind
        ind = ind + 1;
        
        % Current fileoutput
        fnout_curr = [fnout, num2str(ind), ext];
        
        % vert inds
        i1 = (irow-1) * panelsizevec(1) + 1;
        if irow  == nrow
            i2 = sizevec(1);
        else
            i2 = irow * panelsizevec(1);
        end
        
        % hor inds
        i3 = (icol-1) * panelsizevec(2) + 1;
        if icol == ncol
            i4 = sizevec(2);
        else
            i4 = icol * panelsizevec(2);
        end
        
        % Write tiff and parameters
        writetiff(im(i1:i2, i3:i4, :), fnout_curr);
    end
end

save(fpara, '-v7.3', 'fp', 'fn', 'sizevec', 'panelsizevec', 'nrow', 'ncol', 'nfiles');

end

