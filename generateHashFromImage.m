function hash = genrateHashFromImage(image)
     
	[m, n, c] = size(image);       % Gives rows, columns
	if c == 3
        % Starts by separating the image into RGB channels
        message_R = image(:,:,1);      % Red channel
        message_G = image(:,:,2);      % Green channel
        message_B = image(:,:,3);      % Blue channel
        flat_R = reshape(image(:,:,1)',[1 m*n]); % Reshapes Red channel matrix into a 1 by m*n uint8 array
        flat_G = reshape(image(:,:,2)',[1 m*n]); % 
        flat_B = reshape(image(:,:,3)',[1 m*n]); % 
        flat_RGB = [flat_R, flat_G, flat_B];     % Concatenates all RGB vals, into one long 1 by 3*m*n array
        hash = DataHash(flat_RGB);
        hash = logical(dec2bin(hash))
    else
        flat_Gray = reshape(image(:,:)',[1 m*n]);
        hash = DataHash(flat_Gray);
    end
    