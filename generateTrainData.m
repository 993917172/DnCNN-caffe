clear;close all;
%% settings
folder = 'D:\caffe_DnCNN\trainData\Train400-aug';
savepath = 'D:\caffe_DnCNN\trainData\train.h5';
size_input = 40;
size_label = 40;
stride = 20;

% folderTest  = 'C:\Users\sm\Desktop\CNNSR\FSRCNN\Train\VDSR';
% ext         =  {'*.jpg','*.png','*.bmp'};
% filePaths   =  [];
% for i = 1 : length(ext)
%     filePaths = cat(1,filePaths, dir(fullfile(folderTest,ext{i})));
% end
%% initialization
data = zeros(size_input, size_input, 1, 1);
label = zeros(size_label, size_label, 1, 1);
padding = abs(size_input - size_label)/2;
count = 0;
noiseSigma = 8;
%% generate data
filepaths = dir(fullfile(folder,'*.bmp'));

% for scale = 2:4
    for i = 1 : length(filepaths)
%         fprintf('i:%d\n',i);

        image = imread(fullfile(folder,filepaths(i).name));
        image = im2double(image);
        [hei,wid] = size(image);
%         image1 = im2double(image(:, :, 1));

        im_input = image;
%         im_label = modcrop(image, scale);
%         
%         im_input = imresize(imresize(im_label,1/scale,'bicubic'),[hei,wid],'bicubic');

        for x = 1 : stride : hei-size_input+1
            for y = 1 :stride : wid-size_input+1
                subim_input = im_input(x : x+size_input-1, y : y+size_input-1);
                randn('seed',0);
                noise = noiseSigma/255*randn(size(subim_input));
                subim_input = subim_input + noise;
%                 subim_label = im_label(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1);
                subim_label = noise;

                count=count+1;
                data(:, :, 1, count) = subim_input;
                label(:, :, 1, count) = subim_label;
            end
        end
    end
% end

order = randperm(count);
data = data(:, :, 1, order);
label = label(:, :, 1, order);

%% writing to HDF5
chunksz = 128;
created_flag = false;
totalct = 0;

for batchno = 1:floor(count/chunksz)
    last_read=(batchno-1)*chunksz;
    batchdata = data(:,:,1,last_read+1:last_read+chunksz);
    batchlabs = label(:,:,1,last_read+1:last_read+chunksz);

    startloc = struct('dat',[1,1,1,totalct+1], 'lab', [1,1,1,totalct+1]);
    curr_dat_sz = store2hdf5(savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz);
    created_flag = true;
    totalct = curr_dat_sz(end);
end
h5disp(savepath);