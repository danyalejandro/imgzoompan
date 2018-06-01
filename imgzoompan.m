%% IMAGE ZOOM & PAN
%
% A function that adds instant mouse zoom (mouse wheel) and pan (mouse drag) capabilities to figures,
% designed for displaying 2D images in applications (GUIDE) that require lots of drag & zoom.
% 
% Features:
% *) Minimalistic, tries not to get in your way.
% *) Designed to mimic behavior from common image viewers.
% *) Prevents the user from zooming out when the image is smaller than the Figure.
% *) User cannot zoom or drag the image outside of the Figure.
% *) Lets you add callback functions for the mouse ButtonDown / ButtonUp events (you don't lose control).
% *) Lots of configuration options.

%% SYNTAX:
%
% imgzoompan(hfig, <options>): will add the zoom & pan functionality to the figure
% handler provided, followed by an optional arbitrary number of options in the usual Matlab
% format (pairs of: 'OptionName', OptionValue).

%% OPTIONS
%
% Although everything is optional, its recommended to at least provide the image dimensions
% (ImgWidth, ImgHeight) for full drag & zoom functionality.
%
% Zoom configuration:
%  *) Magnify: General magnitication factor. 1.0 or greater (default: 1.1).
%  *) XMagnify: Magnification factor of X axis (default: 1.0).
%  *) YMagnify: Magnification factor of Y axis (default: 1.0).
%  *) ChangeMagnify: Relative increase of the magnification factor. 1.0 or greater (default: 1.1).
%  *) IncreaseChange: Relative increase in the ChangeMagnify factor. 1.0 or greater (default: 1.1).
%  *) MinValue: Sets the minimum value for Magnify, ChangeMagnify and IncreaseChange (default: 1.1).
%
% Pan configuration:
%  *) ImgWidth: Original image pixel width. A value of 0 disables the functionality that prevents the user
%               from dragging and zooming outside of the image (default: 0).
%  *) ImgHeight: Original image pixel height (default: 0).
%
% Mouse options and callbacks:
%  *) PanMouseButton: Mouse button used for panning: 1: left, 2: right, 3: middle.
%                     A value of 0 disables this functionality (default: 2).
%  *) ResetMouseButton: Mouse button used for resetting zoom & pan: 1: left, 2: right, 3: middle.
%                       A value of 0 disables this functionality (default: 3).
%  *) ButtonDownFcn: Mouse button down function callback. Recieves a function reference to your custom
%                    ButtonDown handler, which will be executed first. Your function must have the arguments
%                    (hObject, event) and will work as described in Matlab's documentation for
%                    'WindowButtonDownFcn'. See example2.mat for example code.
%  *) ButtonUpFcn: Mouse button up function callback. Works the same way as the 'ButtonDownFcn' option.

%% ZOOM BEHAVIOUR:
%
% The magnification along the X axis is given by the formula
%
%             Magnify * XMagnify
%
% and analogously for the Y axis. Whether zooming in (incrementing the
% distance between data points) or zooming out (decrementing the distance
% between data points) depends on the direction of rotation of the mouse wheel.
%
% Notice that this code modifies the WindowScrollWheelFcn callback function in your figure, loosing
% any of its previous functionality.
%
%% USAGE AND EXAMPLES:
%
% Default behavior is to zoom with mouse wheel and drag with right button (can be modified
% using configuration options). A simple use case of loading and showing an image looks as follows:
%
% Img = imread('myimage.jpg');
% imshow(Img);
% [h, w, ~] = size(Img);
% imgzoompan(gca, 'ImgWidth', w, 'ImgHeight', h);
%
% See example1.m and example2.m for more examples.
%
%% ACKNOWLEDGEMENTS:
%
% *) Hugo Eyherabide (Hugo.Eyherabide@cs.helsinki.fi) as this project uses his code
%    (FileExchange: zoom_wheel) as reference for zooming functionality.
% *) E. Meade Spratley for his mouse panning example (FileExchange: MousePanningExample).
% *) Alex Burden for his technical and emotional support.

% Send code updates, bug reports and comments to: Dany Cabrera (dcabrera@uvic.ca)

%% Copyright (c) 2018, Dany Alejandro Cabrera Vargas, University of Victoria, Canada,
% published under BSD license (http://www.opensource.org/licenses/bsd-license.php).

%% MAIN FUNCTION
function imgzoompan(hfig, varargin)
	% Parse configuration options
	if ~ishandle(hfig)
		error('The first input argument should be a figure handle.');
	end

	p = inputParser;
	% Zoom configuration options
	p.addOptional('Magnify', 1.1, @isnumeric);
	p.addOptional('XMagnify', 1.0, @isnumeric);
	p.addOptional('YMagnify', 1.0, @isnumeric);
	p.addOptional('ChangeMagnify', 1.1, @isnumeric);
	p.addOptional('IncreaseChange', 1.1, @isnumeric);
	p.addOptional('MinValue', 1.1, @isnumeric);
	% Pan configuration options
	p.addOptional('ImgWidth', 0, @isnumeric);
	p.addOptional('ImgHeight', 0, @isnumeric);
	% Mouse options and callbacks
	p.addOptional('PanMouseButton', 2, @isnumeric);
	p.addOptional('ResetMouseButton', 3, @isnumeric);
	p.addOptional('ButtonDownFcn', @emptyFcn);
	p.addOptional('ButtonUpFcn', @emptyFcn);
	
	% Parse & Sanitize options
	parse(p, varargin{:});
	opt = p.Results;
	hfig = gcf;
    if opt.Magnify<opt.MinValue, opt.Magnify=opt.MinValue; end
    if opt.ChangeMagnify<opt.MinValue, opt.ChangeMagnify=opt.MinValue; end
    if opt.IncreaseChange<opt.MinValue, opt.IncreaseChange=opt.MinValue; end
    
	% Prepare mouse callbacks
    set(hfig, 'WindowScrollWheelFcn', @zoom_fcn);
	set(hfig, 'WindowButtonDownFcn', @down_fcn);
	set(hfig, 'WindowButtonUpFcn', @up_fcn);
    
    orig.h=[];
    orig.XLim=[];
    orig.YLim=[];
    
	% Applies zoom
    function zoom_fcn(src, cbdata)
        axish = gca;
        
        if (isempty(orig.h) || axish ~= orig.h)
            orig.h=axish;
            orig.XLim=axish.XLim;
            orig.YLim=axish.YLim;
		end
        
		% calculate the new XLim and YLim
		cpaxes = mean(axish.CurrentPoint);
		newXLim = (axish.XLim-cpaxes(1))*(opt.Magnify*opt.XMagnify)^cbdata.VerticalScrollCount+cpaxes(1);
		newYLim = (axish.YLim-cpaxes(2))*(opt.Magnify*opt.YMagnify)^cbdata.VerticalScrollCount+cpaxes(2);

		% only check for image border location if the user provided ImgWidth
		if opt.ImgWidth > 0
			if (newXLim(1) >= 0 && newXLim(2) <= opt.ImgWidth && newYLim(1) >= 0 && newYLim(2) <= opt.ImgHeight)
				axish.XLim = newXLim;
				axish.YLim = newYLim;
			else
				axish.XLim = orig.XLim;
				axish.YLim = orig.YLim;
			end
		else
			axish.XLim = newXLim;
			axish.YLim = newYLim;
		end
	end 

	%% Mouse Button Callbacks
	function down_fcn(hObj, evt)
		opt.ButtonDownFcn(hObj, evt); % First, run callback from options
		
		clickType = evt.Source.SelectionType;

		% Panning action
		panBt = opt.PanMouseButton;
		if (panBt > 0)
			if (panBt == 1 && strcmp(clickType, 'extend')) || (panBt == 2 && strcmp(clickType, 'alt')) || (panBt == 3 && strcmp(clickType, 'extend'))
				guiArea = hittest(hObj);
				parentAxes = ancestor(guiArea,'axes');

				% if the mouse is over the desired axis, trigger the pan fcn
				if ~isempty(parentAxes)
					startPan(parentAxes)
				else
					setptr(evt.Source,'forbidden')
				end
			end
		end
	end

	% Main mouseButtonUp callback
	function up_fcn(hObj, evt)
		opt.ButtonUpFcn(hObj, evt); % First, run callback from options
		
		% Reset action
		clickType = evt.Source.SelectionType;
		resBt = opt.ResetMouseButton;
		if (resBt > 0 && ~isempty(orig.XLim))
			if (resBt == 1 && strcmp(clickType, 'extend')) || (resBt == 2 && strcmp(clickType, 'alt')) || (resBt == 3 && strcmp(clickType, 'extend'))
				guiArea = hittest(hObj);
				parentAxes = ancestor(guiArea,'axes');
				parentAxes.XLim=orig.XLim;
                parentAxes.YLim=orig.YLim;
			end
		end
		
		stopPan();
	end

	% Helper empty function, runs if there's no mouse buttondown/up callback configured by the user
	function emptyFcn(~, ~)
	end

	%% AXIS PANNING FUNCTIONS
	
	% Call this Fcn in your 'WindowButtonDownFcn'
	% Take in desired Axis to pan
	% Get seed points & assign the Panning Fcn to top level Fig
	function startPan(hAx)
		hFig = ancestor(hAx, 'Figure', 'toplevel');   % Parent Fig

		seedPt = get(hAx, 'CurrentPoint');           % Get init mouse position
		seedPt = seedPt(1, :);                       % Keep only 1st point

		hAx.XLimMode = 'manual';                    % Temp stop 'auto resizing'
		hAx.YLimMode = 'manual';

		set(hFig,'WindowButtonMotionFcn',{@panningFcn,hAx,seedPt});
		setptr(hFig, 'hand');                        % Assign 'Panning' cursor
	end


	% Call this Fcn in your 'WindowButtonUpFcn'
	function stopPan
		set(gcbf,'WindowButtonMotionFcn',[]);
		setptr(gcbf,'arrow');
	end


	% Controls the real-time panning on the desired axis
	function panningFcn(~,~,hAx,seedPt)
		% Get current mouse position
		currPt = get(hAx,'CurrentPoint');

		% Current Limits [absolute vals]
		XLim = hAx.XLim;
		YLim = hAx.YLim;

		% Original (seed) and Current mouse positions [relative (%) to axes]
		x_seed = (seedPt(1)-XLim(1))/(XLim(2)-XLim(1));
		y_seed = (seedPt(2)-YLim(1))/(YLim(2)-YLim(1));

		x_curr = (currPt(1,1)-XLim(1))/(XLim(2)-XLim(1));
		y_curr = (currPt(1,2)-YLim(1))/(YLim(2)-YLim(1));

		% Change in mouse position [delta relative (%) to axes]
		deltaX = x_curr-x_seed;
		deltaY = y_curr-y_seed;
		
		% Calculate new Lims based on mouse position change
		newXLims(1) = -deltaX*diff(XLim)+XLim(1);         % XLims
		newXLims(2) = newXLims(1)+diff(XLim);

		newYLims(1) = -deltaY*diff(YLim)+YLim(1);         % YLims
		newYLims(2) = newYLims(1)+diff(YLim);
		
		% Update Axes limits
		if (newXLims(1) > 0.0 && newXLims(2) < opt.ImgWidth)
			set(hAx,'Xlim',newXLims);
		end
		if (newYLims(1) > 0.0 && newYLims(2) < opt.ImgHeight)
			set(hAx,'Ylim',newYLims);
		end
	end
end