function [SSIM,map] = PSNR(A,B) 
	grayWaterMark = uint8(255 * A);
	grayRef = uint8(255 * B);
	[SSIM,map] = ssim(grayWaterMark,grayRef);
	