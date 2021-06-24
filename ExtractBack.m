function WaterMark = ExtractBack(parentImg)
% Reading Source Iamge and Flattening the Array
source = imread(parentImg);
[w,h,c] = size(source);
if c > 1
    source = rgb2gray(source);
end
figure,imshow(source);
%source = imnoise(source,'salt & pepper',0.01);
flattenSource = source(:);
orig = source;

% Reading The permutation of image in which the embedding was performed 
fileID = fopen('sortIndexes.txt','r');
formatSpec = '%d';
sortIndexes = fscanf(fileID,formatSpec);

% Reading the random Array(used during embedding)
fileID = fopen('randomInts.txt','r');
k = fscanf(fileID,formatSpec);

% Getting the sorted image in which the embedding was performed
sortedSource = flattenSource(sortIndexes);
% Reshaping
reshapedSortedSource = reshape(sortedSource,512,512);

blockSize = 8;
row = 1;
col = 1;
backDiagonal  = zeros(8,1);
% initializing watermark array for extracting the watermark
waterMark = zeros(4096:1);

% iterating 8x8 block for extraction
for blockNo = 1 : 1 : 4096
    block = reshapedSortedSource(row:row+blockSize-1,col:col+blockSize-1);
    
    % Transform the block with Fractional Fourier Transform
    block = reshape(frft2d(block,[0.5,0.5]),8,8);
    
    % Seperating real and imaginary parts
    realBlock = real(block);
    imaginaryBlock = imag(block);
    
    % Seperating the Back DIagonal from The Array 
    j = 1;% represents column number
    for i = 8: -1 : 1 % represents row Number    
        backDiagonal(j,1) = realBlock(i,j);
        j = j + 1;
    end
    
%     if(blockNo == 2)
%         backDiagonal
%     end
    
    % Extraction with the help of Pearson Coefficient Equation
    if PearsonCo(backDiagonal,k) >= PearsonCo(backDiagonal,-k)
        waterMark(blockNo) = 1;
    else
        waterMark(blockNo) = 0;
    end
    
    
    % Iteration 
    col = col + blockSize;
    if(col >= size(source,2))
        col = 1;
        row = row + blockSize;
        if(row >= size(source,1))
            row = 1;
        end
    end
end

% Resizing anad displaying the Watermark
waterMark = reshape(waterMark,64,64);
figure;imshow(waterMark);


% Tamepr Detect And Localize
blockSize = 4;
row = 1;
col = 1;

meanValEx = zeros(1,8);

for blockNo = 1 : 1 : 16384

    % % calculate mean value of upper 4x2 block
    block = source(row:row+blockSize-1,col:col+blockSize-1);

    upperHalf = block(1:2,1:4);
    lowerHalf = block(3:4,1:4);
    
    meanVal = uint8(mean(upperHalf,"all"));

    % Getting Mean Value
    itr = 1;
    for i = 1 : 1 : 2
        for j = 1 : 1 : 4
            meanValEx(1,itr) = bitget(lowerHalf(i,j),1); % Embedding in LSB
            itr = itr + 1;
        end
    end

    % if the value doesn't match then turn that block into White
    if meanVal ~= bi2de(meanValEx)
        block(:,:) =  255;
        source(row:row+blockSize-1,col:col+blockSize-1) = block;
    end

     % Iteration 
    col = col + blockSize;
    if(col >= size(source,2))
        col = 1;
        row = row + blockSize;
        if(row >= size(source,1))
            row = 1;
        end
    end
end

figure,imshow(source);

% Comparison
origWaterMark = imbinarize(imread("left_index.jpeg"));
nc = corr2(origWaterMark,waterMark)
psnr = PSNR(origWaterMark,waterMark)
[val,map] = SSIM(waterMark,origWaterMark);
ber = Biter(origWaterMark,waterMark)