function imslicer_batch(fns, fp, nrow, ncol, varargin)
%imslicer slices images for batch processing. This is the batch mode of the
%code

if nargin < 5
    varargin = {};
    if nargin < 4
        ncol = [];
        nrow = [];
        if nargin < 2
            fns = {};
            fp = '';
        end
    end
end

% Empty
if isempty(fns) || isempty(fp)
    fns = {};
    fp = '';
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
if isempty(fns) || isempty(fp)
    [fns, fp] = uigetfile(fullfile(p.defaultpath, '*.tif'), 'Select tiff files', 'MultiSelect', 'on');
end

% new folder
if ~iscell(fns)
    [~, fnsample, ~] = fileparts(fns);
    fns = {fns};
else
    [~, fnsample, ~] = fileparts(fns{1});
end

% Number of files
nim = length(fns);

% output folder
if ~exist(fullfile(fp, [fnsample, '_batch']), 'dir')
    mkdir(fullfile(fp, [fnsample, '_batch']));
end

% output filename
fpara = fullfile(fp, [fnsample, '_batch'], 'batch_sliceparam.mat');

if exist(fpara, 'file') && ~p.force
    doslice = input('Batch slices already exist, reslice all? (1 = yes, 0 - no): ');
    if doslice ~= 1
        return;
    end
end

if isempty(nrow) || isempty(ncol)
    % Get file info
    imginfo = imfinfo(fullfile(fp, fns{1}));

    % User input
    prompt = {'Enter the number of rows:', 'Enter the number of columns:',...
        'First image size:', 'First filesize (MB):'};
    dlgtitle = 'Rows and columns';
    dims = [1 35];
    definput = {'3', '2', [num2str(imginfo.Height), ' X ', num2str(imginfo.Width)],...
        num2str(round(imginfo.FileSize/1024/1024))};

    % Parse input
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    nrow = str2double(answer{1});
    ncol = str2double(answer{2});
end

% number of files
nperim = nrow * ncol;
nfiles = nperim * nim;

% Initialize file name out
fns_out = cell(nim, nperim);
sizevecs = cell(nim, 1);
panelsizevecs = cell(nim, 1);

%% Loop and process
hwait = waitbar(0, 'Processing');
for i = 1 : nim
    % index
    ind = 0;
    
    % Current file name
    fn_curr = fns{i};
    [~, fn, ext] = fileparts(fn_curr);
    fnout = fullfile(fp, [fnsample, '_batch'], [fn, '_']);
    
    waitbar(i/nim, hwait, ['Reading ', fn]);
    % Read
    try
        im = readtiff(fullfile(fp, fn_curr));
    catch
        im = imread(fullfile(fp, fn_curr));
    end

    % size
    sizevec = size(im);
    sizevecs{i} = sizevec;
    
    % panel size
    panelsizevec = ceil(sizevec ./ [nrow ncol]);
    panelsizevecs{i} = panelsizevec;
    
    waitbar(i/nim, hwait, ['Processing and writing ', fn]);
    for icol = 1 : ncol
        for irow = 1: nrow
            % Ind
            ind = ind + 1;

            % Current fileoutput
            fnout_curr = [fnout, num2str(ind), ext];
            
            % Store
            fns_out{i, ind} = [fn, '_', num2str(ind)];
            
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
end
close(hwait)

save(fpara, '-v7.3', 'fp', 'fns', 'fns_out', 'sizevecs', 'panelsizevecs',...
    'nrow', 'ncol', 'nim', 'nperim', 'nfiles');
disp('Done.')
end