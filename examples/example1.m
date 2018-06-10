addpath('../');
% Simple use case: Load an image (provided) and show it,
% then add zoompan functionality (in this case to the current axes: gca)
% When using GUIDE, provide a handler to your own axes.

Img = imread('myimage.jpg');
imshow(Img);
[h, w, ~] = size(Img);
imgzoompan(gca, 'ImgWidth', w, 'ImgHeight', h);