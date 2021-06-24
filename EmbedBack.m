function WaterMark = EmbedBack(parentImg,childImg,signImage)
% Reading Source Iamge and Flattening the Array
source = imread(parentImg);

[w,h,c] = size(source);
if c > 1
    source = rgb2gray(source);
end

flattenSource = source(:);
orig = source;

% Reading Watermark, Binarizing and Flattening the Array
watermark = imread(childImg);
binaryWatermark = imbinarize(watermark);
mark = binaryWatermark(:);
origWaterMark = watermark;

% Sorting The Source Image
[sortedSource,sortIndexes] = sort(flattenSource);
% Reshaping the sorted Image
sortedSourceReshaped = reshape(sortedSource,512,512);

blockSize = 8;
row = 1;
col = 1;

% Random Array for embedding Purpose
formatSpec = '%d';
fileID = fopen('randomInts.txt','r');
k = fscanf(fileID,formatSpec);

% k = randi([-1 1],8,1);
% fileID = fopen('randomInts.txt','w');
% fprintf(fileID,'%d\n',k);

% this defines the imperceptability of watermark( higher vaue distorts the
% image more)
scale = 11;

backDiagonal  = zeros(8,1);

% Embedding a watermark binary pixel to a 8x8 block of host image
for blockNo = 1 : 1 : 4096
    % 8x8 host image block
    block = sortedSourceReshaped(row:row+blockSize-1,col:col+blockSize-1);
    
    % Transform the block with Fractional Fourier Transform
    block = reshape(frft2d(block,[0.5,0.5]),8,8);
    
    % Seperating real and imaginary parts
    realBlock = real(block);
    imaginaryBlock = imag(block);
    
    % Seperating the Back Daagonal from The Array 
    j = 1;% represents column number
    for i = 8: -1 : 1 % represents row Number    
        backDiagonal(j,1) = realBlock(i,j);
        j = j + 1;
    end
    
     if(blockNo == 2048)
         %backDiagonal
%         figure;imshow(uint8(abs(block)));
     end
    
    % if watermark pixel is 1 adding random array to back diagonal otherwise
    % subtracting
    if mark(blockNo) == 1
        result = backDiagonal + (scale*k);
    else
        result = backDiagonal - (scale*k);
    end
    
    
    
    % Replacing The Value into the backDiagonal of Block
    j = 1;% represents column number
    for i = 8: -1 : 1 % represents row Number    
         realBlock(i,j) = result(j,1);
        j = j + 1;
    end
    
    % recomposing The block with real and complex values
    block = complex(realBlock,imaginaryBlock);
    
     if(blockNo == 2048)
         %result
%         figure;imshow(uint8(abs(block)));
     end
    
    % Transform the block with Inverse Fractional Fourier Transform
    block = reshape(frft2d(block,[-0.5,-0.5]),8,8);
    
    % Converting Complex numbers to Real numbers
    block = uint8(abs(block));
    
    % Replacing the Block into original Source
    sortedSourceReshaped(row:row+blockSize-1,col:col+blockSize-1) = block;
    
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

% flattening the Array
flattenSortedSource = sortedSourceReshaped(:);
% Getting the real image From the Sorted Image
flattenSourceOriginal(sortIndexes) = flattenSortedSource;
% Reshaping the Image to original Size
flattenSourceOriginalReshaped = reshape(flattenSourceOriginal,512,512);

%_______________________Tamper Detection________________________
blockSize = 4;
row = 1;
col = 1;

 for blockNo = 1 : 1 : 16384

    % % calculate mean value of upper 4x2 block
    block = flattenSourceOriginalReshaped(row:row+blockSize-1,col:col+blockSize-1);
    
    upperHalf = block(1:2,1:4);
    lowerHalf = block(3:4,1:4);
    
    meanVal = uint8(mean(upperHalf,"all"));
    % convert mean value to binary
    binaryMean = de2bi(meanVal,8);

    % embed in lower half
    itr = 1;
    for i = 1 : 1 : 2
        for j = 1 : 1 : 4
            lowerHalf(i,j) = bitset(lowerHalf(i,j),1,binaryMean(itr)); % Embedding in LSB
            itr = itr + 1;
        end
    end

    % Replacing The Block in Watermarked Imaeg
    block(3:4,1:4) = lowerHalf;
    flattenSourceOriginalReshaped(row:row+blockSize-1,col:col+blockSize-1) = block;

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

% Saving the Watermarked Image
imwrite((flattenSourceOriginalReshaped),"WaterMarkedBack.tif");
% Saving Sort Orders of Array
fileID = fopen('sortIndexes.txt','w');
fprintf(fileID,'%d\n',sortIndexes);
% Saving random Array
fileID = fopen('randomInts.txt','w');
fprintf(fileID,'%d\n',k);

%determining PSNR
psnr = PSNR(orig,flattenSourceOriginalReshaped)
ber = Biter(orig,flattenSourceOriginalReshaped)

figure;imshow(flattenSourceOriginalReshaped);
%hash = reshape(dec2bin(hash, 8).'-'0',1,[]);
%hash = char(bin2dec(reshape(char(hash+'0'), 8,[]).'))
%hash = convertCharsToStrings(hash);