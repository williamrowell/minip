%% SETUP

clear all

% Define the ranges of frames that you want to see by providing the length
% of a video fragment in seconds
% frag_length = 60; % in seconds
% defined_range = []; % couplets of first_frame last_frame
defined_range = [1 90; 1801 1890; 3601 3690; 5401 5490; 7201 7290; 9001 9090; 10801 10890; 12601 12690]; % 3 seconds per minute
% defined_range = [1 150; 1801 1950; 3601 3750; 5401 5550; 7201 7350; 9001 9150; 10801 10950; 12601 12750]; % 5 seconds per minute
% defined_range = [1 300; 1801 2100; 3601 3900; 5401 5700; 7201 7500; 9001 9300; 10801 11100; 12601 12900]; % 10 seconds per minute

% Define the set size for output
set_size = 10;

% Add to path
addpath(genpath(pwd));

% Set the directory
path = uigetdir %#ok<NOPTS>
cd(path);

% Open logfile
now_str = datestr(now,30);

% Get a list of all video files in the directory
filetype = 'avi' %#ok<NOPTS>
ls(['*.' filetype])
contents = dir(fullfile(path,['*.' filetype]));

dir_minipmat = [];

width = 0;
height = 0;

%% PROCESS

% for each video in the directory
for file_index = 1:length(contents)
    
    % Grab a stack of images from the video
    mov = VideoReader(contents(file_index).name); %#ok<TNMLP>
    
    % Determine the ranges to examine
    if exist('defined_range','var')
        range = defined_range;
    elseif exist('frag_length','var')
        % Create a list of ranges using frag_length
        if mod(mov.Duration,frag_length) ~= 0
            error('The length of the movie, %d seconds, must be evenly divisible by the fragment length, %d seconds.',mov.Duration,frag_length);
        end
        num_rows = mov.Duration/frag_length;
        range = [];
        for row_idx = 1:num_rows
            range(row_idx,:) = [(row_idx-1)*mov.FrameRate*frag_length+1 (row_idx)*mov.FrameRate*frag_length]; %#ok<SAGROW>
        end
    else
        error('You must provide time ranges.')
    end
    
    % For each pair of start/stop values, convert to grayscale and
    % calculate the minimum intensity projection
    minipmat = [];
    for range_idx = 1:length(range(:,1))
        % Convert to RGB
        img_stack = [];
        counter = 1;
        for stack_index = range(range_idx,1):range(range_idx,2)
            img_stack(:,:,counter) = rgb2gray(read(mov,stack_index)); 
            counter = counter + 1;
        end
        
        % Calculate the minimum intensity for each pixel along the Z dimension
        minipmat = horzcat(minipmat,min(img_stack,[],3)); %#ok<AGROW>

    end
    
    % Add it to the final image
    dir_minipmat = vertcat(dir_minipmat,minipmat); %#ok<AGROW>
end

%% MAKE IMAGES

num_sets = ceil(length(contents)/set_size);

for set_idx = 1:num_sets
    if set_idx < num_sets
        % Display the minimum intensity for each pixel along the Z dimension
        % (set_idx-1)*num_sets*mov.Height+1:set_idx*num_sets*mov.Height
        h = image(dir_minipmat(((set_idx-1)*set_size*mov.Height)+1:set_idx*set_size*mov.Height,:));
        set(gca,'Units','normalized','Position',[0 0 1 1])
        truesize(gcf,[mov.Height*set_size mov.Width*length(range(:,1))]);
                
        % Annotate output
        for file_index = ((set_idx-1)*set_size)+1:set_idx*set_size
            text(5,(mod(file_index-1,set_size)+1)*mov.Height-10,contents(file_index).name,'Color','w','FontSize',12,'FontWeight','bold','Interpreter','none')
        end
        
        % Save output
        % saveas(h,['minimum_intensity_projection_' now_str '_' mat2str(set_idx) '.jpg']);
        set(gca,'Units','normalized','Position',[0 0 1 1])
        [frame,map]=frame2im(getframe(gcf));
        imwrite(frame,['minimum_intensity_projection_' now_str '_' mat2str(set_idx) '.jpg'])
        clear h;
        
    elseif set_idx == num_sets
        % Display the minimum intensity for each pixel along the Z dimension
        h = image(dir_minipmat(((set_idx-1)*set_size*mov.Height)+1:length(contents)*mov.Height,:));
        set(gca,'Units','normalized','Position',[0 0 1 1])
        truesize(gcf,[mov.Height*mod(length(contents),set_size) mov.Width*length(range(:,1))]);

                
        % Annotate output
        for file_index = ((set_idx-1)*set_size)+1:length(contents)
            text(5,(mod(file_index-1,set_size)+1)*mov.Height-10,contents(file_index).name,'Color','w','FontSize',12,'FontWeight','bold','Interpreter','none')
        end
        
        % Save output
        % saveas(h,['minimum_intensity_projection_' now_str '_' mat2str(set_idx) '.png']);
        [frame,map]=frame2im(getframe(gcf));
        imwrite(frame,['minimum_intensity_projection_' now_str '_' mat2str(set_idx) '.jpg'])
        clear h;
        
    end
end