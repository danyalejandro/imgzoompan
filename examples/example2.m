addpath('../');
% Continuing from example1.m, this example provides custom function handlers
% for the ButtonDown and ButtonUp mouse events from the root Figure.

Img = imread('myimage.jpg');
imshow(Img);
[h, w, ~] = size(Img);
imgzoompan(gcf, 'ImgWidth', w, 'ImgHeight', h, 'ButtonDownFcn', @myFuncDown, 'ButtonUpFcn', @myFuncUp);

% Custom button down function handler
function myFuncDown(hObject, event)
	clickType = event.Source.SelectionType;
	fprintf('Mouse down button: %s\n', clickType);
end

% Custom button up function handler
function myFuncUp(hObject, event)
	fprintf('Mouse up!\n');
end