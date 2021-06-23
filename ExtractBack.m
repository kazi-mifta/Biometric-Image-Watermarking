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

figure;imshow(reshapedSortedSource);

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

 
% initializing watermark array for extracting the watermark
EyeHashBinary = zeros(size(1,256));
NoseHashBinary = zeros(size(1,256));
MouthHashBinary = zeros(size(1,256));
 
for colNo = 1 : 1 : 256
    EyeHashBinary(1,colNo) = bitget(source(1,colNo),1);
    NoseHashBinary(1,colNo) = bitget(source(1,256 + colNo),1);
    MouthHashBinary(1,colNo) = bitget(source(512,colNo),1);
end
 
EyeHash = char(bin2dec(reshape(char(EyeHashBinary+'0'), 8,[]).'));
NoseHash = char(bin2dec(reshape(char(NoseHashBinary+'0'), 8,[]).'));
MouthHash = char(bin2dec(reshape(char(MouthHashBinary+'0'), 8,[]).'));
 
EyeHash = convertCharsToStrings(EyeHash);
NoseHash = convertCharsToStrings(NoseHash);
MouthHash = convertCharsToStrings(MouthHash)
 
%To detect Eye,Nose,Mouth
EyeDetector = vision.CascadeObjectDetector('EyePairBig');
NoseDetector = vision.CascadeObjectDetector('Nose','MergeThreshold',4); 
MouthDetector = vision.CascadeObjectDetector('Mouth','MergeThreshold',4); 
%detecting Bounding Box of Eye,Nose,Mouth
EyeBB = step(EyeDetector,source);
NoseBB = step(NoseDetector,source);
MouthBB = step(MouthDetector,source);
size(EyeBB)
size(NoseBB)
size(MouthBB)
% Cropping the Bounding Region from Main Image
Eye = imcrop(source,EyeBB);
Nose = imcrop(source,NoseBB(2,:));
Mouth = imcrop(source,MouthBB(2,:));
 
% Hash Generation
EyeHashSec = generateHashFromImage(Eye);
NoseHashSec = generateHashFromImage(Nose);
MouthHashSec = generateHashFromImage(Mouth)

figure,imshow(source);
if EyeHash ~= EyeHashSec
    rectangle('Position',EyeBB,'LineWidth',4,'LineStyle','-','EdgeColor','r');
end
if NoseHash ~= NoseHashSec
    rectangle('Position',NoseBB(2,:),'LineWidth',4,'LineStyle','-','EdgeColor','r');
end
if MouthHash ~= MouthHashSec
    rectangle('Position',MouthBB(2,:),'LineWidth',4,'LineStyle','-','EdgeColor','r');
end

% Comparison
origWaterMark = imbinarize(imread("left_index.jpeg"));
nc = corr2(origWaterMark,waterMark)
psnr = PSNR(origWaterMark,waterMark)
[val,map] = SSIM(waterMark,origWaterMark);
ber = Biter(origWaterMark,waterMark)