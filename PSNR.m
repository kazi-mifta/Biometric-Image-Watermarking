function psnr = PSNR(A,B) 

   im1 = double(A);
   im2 = double(B);
   %Find the mean squared error
   mse = sum((im1(:)-im2(:)).^2) / prod(size(im1));
   % now find the psnr, as peak=255
   psnr = 10*log10(255*255/mse);