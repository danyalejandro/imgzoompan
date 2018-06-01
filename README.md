# MATLAB IMAGE ZOOM & PAN
A MatLab code plugin that provides mouse zoom &amp; pan functionality for 2D images.
The function adds instant mouse zoom (mouse wheel) and pan (mouse drag) capabilities to figures,
designed for displaying 2D images in applications (e.g. GUIDE) that require lots of drag & zoom.

Features:
* Minimalistic, tries not to get in your way.
* Designed to mimic behavior from common image viewers.
* Prevents the user from zooming out when the image is smaller than the Figure.
* User cannot zoom or drag the image outside of the Figure.
* Lets you add callback functions for the mouse ButtonDown / ButtonUp events (you don't lose control).
* Lots of configuration options.

## Usage:

After adding the imgzoompan.m file to your project, you can use the **imgzoompan()** function.

```matlab
**imgzoompan(hfig, <options>)**: will add the zoom & pan functionality to the figure
handler provided, followed by an optional arbitrary number of options in the usual Matlab
format (pairs of: 'OptionName', OptionValue).
```

## Configuration:

Although everything is optional, its recommended to at least provide the image dimensions
(ImgWidth, ImgHeight) for full drag & zoom functionality.

*Zoom configuration:*
 * **Magnify**: General magnitication factor. 1.0 or greater (default: 1.1).
 * **XMagnify**: Magnification factor of X axis (default: 1.0).
 * **YMagnify**: Magnification factor of Y axis (default: 1.0).
 * **ChangeMagnify**: Relative increase of the magnification factor. 1.0 or greater (default: 1.1).
 * **IncreaseChange**: Relative increase in the ChangeMagnify factor. 1.0 or greater (default: 1.1).
 * **MinValue**: Sets the minimum value for Magnify, ChangeMagnify and IncreaseChange (default: 1.1).

*Pan configuration:*
 * **ImgWidth**: Original image pixel width. A value of 0 disables the functionality that prevents the user
              from dragging and zooming outside of the image (default: 0).
 * **ImgHeight**: Original image pixel height (default: 0).

*Mouse options and callbacks:*
 * **PanMouseButton**: Mouse button used for panning: 1: left, 2: right, 3: middle.
                    A value of 0 disables this functionality (default: 2).
 * **ResetMouseButton**: Mouse button used for resetting zoom & pan: 1: left, 2: right, 3: middle.
                      A value of 0 disables this functionality (default: 3).
 * **ButtonDownFcn**: Mouse button down function callback. Recieves a function reference to your custom
                   ButtonDown handler, which will be executed first. Your function must have the arguments
                   (hObject, event) and will work as described in Matlab's documentation for
                   'WindowButtonDownFcn'. See example2.mat for example code.
 * **ButtonUpFcn**: Mouse button up function callback. Works the same way as the 'ButtonDownFcn' option.

## Zoom behaviour:

The magnification along the X axis is given by the formula

            Magnify * XMagnify

and analogously for the Y axis. Whether zooming in (incrementing the
distance between data points) or zooming out (decrementing the distance
between data points) depends on the direction of rotation of the mouse wheel.

Notice that this code **modifies** the **WindowScrollWheelFcn** callback function in your figure, loosing
any of its previous functionality.

## Usage and examples:

Default behavior is to zoom with mouse wheel and drag with right button (can be modified
using configuration options). A simple use case of loading and showing an image looks as follows:

```matlab
Img = imread('myimage.jpg');
imshow(Img);
[h, w, ~] = size(Img);
imgzoompan(gca, 'ImgWidth', w, 'ImgHeight', h);
```
See _example1.m_ and _example2.m_ for code examples. Example 2 shows how to use custom mouse button callbacks.

## Acknowledgements:

* Hugo Eyherabide (Hugo.Eyherabide@cs.helsinki.fi) as this project uses his code
   (FileExchange: zoom_wheel) as reference for zooming functionality.
* E. Meade Spratley for his mouse panning example (FileExchange: MousePanningExample).
* Alex Burden for his technical and emotional support.

Send code updates, bug reports and comments to: Dany Cabrera (dcabrera@uvic.ca)

## License:
Copyright (c) 2018, **Dany Alejandro Cabrera Vargas**, University of Victoria, Canada,
published under BSD license (http://www.opensource.org/licenses/bsd-license.php).
