function WaterMark = ExtractBack(parentImg)
% Reading Source Iamge and Flattening the Array
source = imread(parentImg);
%source = imnoise(source,'salt & pepper',0.005);
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

% Extracting the Fragile Watermark from ROI
recoveredSign = zeros(size(180,120));
for row = 191:370
	for column = 201:320
        recoveredSign(row-190,column-200) = bitget(orig(row,column), 1);
	end
end
figure;imshow(recoveredSign);


origWaterMark = imbinarize(imread("left_index.jpeg"));
nc = corr2(origWaterMark,waterMark)
psnr = PSNR(origWaterMark,waterMark)
[val,map] = SSIM(waterMark,origWaterMark);
ber = Biter(origWaterMark,waterMark)

origSign = imbinarize(rgb2gray(imread("signature.png")));
[val,map]=SSIM(recoveredSign,origSign);
% Tamper Check
if val < 1
   % Tampered Area is Being painted White
    for row = 191:370
        for column = 201:320
            if (map(row-190,column-200) < 1.0)
                orig(row,column) = 255;
            end
        end
    end

    % ROI extraction in case tamper detected
    row = 1;
    col = 1;
    rowZip = 1;
    colZip = 1;
    counter = 1
    zipBinRoi = zeros(size(16199,8));
    for itrRow = 1:512
        for itrCol = 1:512
            if (col < 201 || col > 320) || (row < 191 || row > 370)
                 if counter <= (16199*8)
                    zipBinRoi(rowZip,colZip) = bitget(orig(row,col), 1);
                    counter = counter + 1;
                 end
                 colZip = colZip + 1;
                 if(colZip > 8)
                    colZip = 1;
                    rowZip = rowZip + 1;
                    if(rowZip > 16199)
                        rowZip = 1;
                    end
                 end
            else
            end
        % Iteration 
        col = col + 1;
        if(col > 512)
            col = 1;
            row = row + 1;
            if(row > 512)
                row = 1;
            end
        end
        end
    end

    figure;imshow(orig);
    charZipBin = num2str(zipBinRoi(1:16199,:));
    charZipBin(1000:1003,:)
    zipped = zeros(size(1,16199));

    for loop = 1:16199
        str = charZipBin(loop,:);
        newStr = regexprep(str, '\s+', '');
        zipped(1,loop) = bin2dec(newStr);
    end
    zipped = uint8(zipped);

    unzipped = zmat(zipped,0,'lzma'); % Uncompressing ROI
    ROI = reshape(unzipped,181,121);
    figure;imshow(ROI); 
end