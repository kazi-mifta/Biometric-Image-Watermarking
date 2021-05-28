function WaterMark = EmbedBack(parentImg,childImg,signImage)
% Reading Source Iamge and Flattening the Array
source = imread(parentImg);
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
         backDiagonal
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
         result
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



%_______________________Tamper Recovery________________________
% Embedding ROI in RONI for emergency Recovery
ROI = imcrop(flattenSourceOriginalReshaped,[200 190 120 180]);
figure;imshow(ROI);
ROI = ROI(:); % flattenning ROI
[zipROI,info] = zmat(ROI,1,'lzma');% Compressing ROI
zipBinRoi = dec2bin(zipROI);% converting Decimal to Binary(Char Array)
zipBinRoi = logical(zipBinRoi'-'0');% converting Decimal to Binary(logical Array)
zipBinRoi = transpose(zipBinRoi);


row = 1;
col = 1;
rowZip = 1;
colZip = 1;
counter = 1
for itrRow = 1:512
    for itrCol = 1:512
        if (col < 201 || col > 320) || (row < 191 || row > 370)
             if counter <= (16199*8)
                flattenSourceOriginalReshaped(row,col) = bitset(flattenSourceOriginalReshaped(row,col), 1, zipBinRoi(rowZip,colZip));
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

%_______________________Tamper Detection________________________
% Reading fragile Watermark, Binarizing and Flattening the Array
signature = imread(signImage);
signature = rgb2gray(signature);
binarySignature = imbinarize(signature);
figure;imshow(binarySignature);
% embedding fragile watermark in ROI
for row = 191:370
	for column = 201:320
        flattenSourceOriginalReshaped(row,column) = bitset(flattenSourceOriginalReshaped(row,column), 1, binarySignature(row-190,column-200));
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
writestruct(info,"zipInfo.xml")
%determining PSNR
psnr = PSNR(orig,flattenSourceOriginalReshaped)
ber = Biter(orig,flattenSourceOriginalReshaped)

%hash = reshape(dec2bin(hash, 8).'-'0',1,[]);
        %hash = char(bin2dec(reshape(char(hash+'0'), 8,[]).'))
        %hash = convertCharsToStrings(hash);