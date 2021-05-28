function WaterMark = Embed(parentImg,childImg)
% Reding Source Iamge
source = imread(parentImg);
figure;imshow(source);
orig = source;

% Reading Watermark, Binarizing and Flattening the Array
watermark = imread(childImg);
binaryWatermark = imbinarize(watermark);
mark = binaryWatermark(:);
origWaterMark = binaryWatermark;

% The position where water mark will be embeded in sorted block
% A 8x8 block will be flattened and sorted later
indexPosition = 3;
thresh = 35;

% Discrete Fractional Fourier Transform(outputs 1D Matrix)
fouSource = frft2d(source,[0.8,0.8]);

% Reshaping Matrix from 1D to 2D
fouSource = reshape(fouSource,512,512);

blockSize = 8;
row = 1;
col = 1;

maxValues = zeros(4096,1);
secMaxValues = zeros(4096,1);
thirdMaxValues = zeros(4096,1);

maxValueIndexes = zeros(4096,1);
secMaxValueIndexes = zeros(4096,1);
thirdMaxValueIndexes = zeros(4096,1);

% Iterating each Block for dertermining 3 Max Values 
for blockNo = 1 : 1 : 4096
    block = fouSource(row:row+blockSize-1,col:col+blockSize-1);
    
    % flattening and Sorting the Block
    newBlock = block(:);
    [sortedBlock,indexes] = sort(newBlock);
    
    % Getting Max value and adding to Max Value Array
    maxValues(blockNo,1) = (sortedBlock(indexPosition));
    maxValueIndexes(blockNo,1) = (indexes(indexPosition));
    
    % Getting second Max Value and Adding to Array
    secMaxValues(blockNo,1) = (sortedBlock(indexPosition-1));
    secMaxValueIndexes(blockNo,1) = (indexes(indexPosition-1));
    
    % Getting third Max Value and Adding to Array
    thirdMaxValues(blockNo,1) = (sortedBlock(indexPosition-2));
    thirdMaxValueIndexes(blockNo,1) = (indexes(indexPosition-2));
    
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


% Iterating each Block and Embedding the watermark
for blockNo = 1 : 1 : 4096
    block = fouSource(row:row+blockSize-1,col:col+blockSize-1);
    
    % flattening Block for value replacement
    block = (block(:));
    
    %debug
%     if blockNo == 410
%         maxValReal(blockNo)
%         secMaxValReal(blockNo)
%         thirdMaxValReal(blockNo)
%     end
    
    % getting water mark bit
    water = mark(blockNo);
    % Embedding Algo(Manipulate the Source array Here)
    if water == 1
        block(maxValueIndexes(blockNo)) = block(maxValueIndexes(blockNo)) + complex(thresh,thresh);
        block(secMaxValueIndexes(blockNo)) = block(maxValueIndexes(blockNo));
         
        block(thirdMaxValueIndexes(blockNo)) = block(thirdMaxValueIndexes(blockNo)) - complex(thresh,thresh);

    else
        %block(thirdMaxValueIndexes(blockNo)) = block(thirdMaxValueIndexes(blockNo)) - complex(thresh,thresh);
        block(secMaxValueIndexes(blockNo)) = block(thirdMaxValueIndexes(blockNo));
         
        %block(maxValueIndexes(blockNo)) = block(maxValueIndexes(blockNo)) + complex(thresh,thresh);
        
    end
 
    % Reshaping block and replacing into main source
    block = reshape(block,8,8);
    fouSource(row:row+blockSize-1,col:col+blockSize-1) = block;
    
    
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

% Inverse Fraction Fourier Transform of source image
inFouSource = frft2d(fouSource,[-0.8,-0.8]);
inFouSource = reshape(inFouSource,512,512);
waterMarkedSource = uint8(abs(inFouSource));

mark = reshape(mark,64,64);

figure;imshow(waterMarkedSource);
figure;imshow((mark));
imwrite((waterMarkedSource),"WaterMarke.tif");


% Saving Sort Orders of Array
fileID = fopen('maxIndexes.txt','w');
fprintf(fileID,'%d\n',maxValueIndexes);
% Saving random Array
fileID = fopen('secMaxIndexes.txt','w');
fprintf(fileID,'%d\n',secMaxValueIndexes);

fileID = fopen('thirdMaxIndexes.txt','w');
fprintf(fileID,'%d\n',thirdMaxValueIndexes);

PSNR(orig,waterMarkedSource)
