function WaterMark = Extract(parentImg)

% Reading the Watermarked Image
wmSource = imread(parentImg);


% Discrete Fractional Fourier Transform(outputs 1D Matrix)
wmSourceFou = frft2d(wmSource,[0.8,0.8]);

% Reshaping Matrix from 1D to 2D
wmSourceFou = reshape(wmSourceFou,512,512);

blockSize = 8;
row = 1;
col = 1;

emaxValues = zeros(4096,1);
esecMaxValues = zeros(4096,1);
ethirdMaxValues = zeros(4096,1);

fileID = fopen('maxIndexes.txt','r');
formatSpec = '%d';
maxValueIndexes = fscanf(fileID,formatSpec);

fileID = fopen('secMaxIndexes.txt','r');
formatSpec = '%d';
secMaxValueIndexes = fscanf(fileID,formatSpec);

fileID = fopen('thirdMaxIndexes.txt','r');
formatSpec = '%d';
thirdMaxValueIndexes = fscanf(fileID,formatSpec);

% Iterating each Block for dertermining Average difference of 2 Max Values 
for blockNo = 1 : 1 : 4096
    block = wmSourceFou(row:row+blockSize-1,col:col+blockSize-1);

    % flattening and Sorting the Block
    newBlock = block(:);
    
    % Getting Max value and adding to Max Value Array
    emaxValues(blockNo,1) = newBlock(maxValueIndexes(blockNo));
    
    % Getting second Max Value and Adding to Array
    esecMaxValues(blockNo,1) = newBlock(secMaxValueIndexes(blockNo));
    
    % Getting second Max Value and Adding to Array
    ethirdMaxValues(blockNo,1) = newBlock(thirdMaxValueIndexes(blockNo));
    
    % Iteration 
    col = col + blockSize;
    if(col >= size(wmSource,2))
        col = 1;
        row = row + blockSize;
        if(row >= size(wmSource,1))
            row = 1;
        end
    end
end

% initializing watermark Array
waterMark = zeros(4096,1);

% Iterating each Block and Extractig the watermark
for blockNo = 1 : 1 : 4096

    diffOne = abs(emaxValues(blockNo) - esecMaxValues(blockNo));
    diffTwo = abs(esecMaxValues(blockNo) - ethirdMaxValues(blockNo));
    
    if diffTwo > 64
        waterMark(blockNo) = 1;
    else
        waterMark(blockNo) = 0;
    end
    
end

retrievedWaterMark = reshape(waterMark,64,64);
figure;imshow(retrievedWaterMark);


origWaterMark = imbinarize(imread("left_index.jpeg"));

%PSNR(origWaterMark,retrievedWaterMark)
corr2(origWaterMark,retrievedWaterMark)
imwrite((retrievedWaterMark),"ExWaterMark.tif");