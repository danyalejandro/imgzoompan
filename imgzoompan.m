%% IMAGE ZOOM & PAN
%
% A function that adds instant mouse zoom (mouse wheel) and pan (mouse drag) capabilities to figures,
% designed for displaying 2D images in applications (GUIDE) that require lots of drag & zoom.

%% USAGE INTRUCTIONS:
%
% Please visit https://github.com/danyalejandro/imgzoompan (or check the README.md text file) for
% full instructions and examples on how to use this plugin.

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
		error('The first input argument should be an axis handle.');
	end

	p = inputParser;
	% Zoom configuration options
	p.addOptional('Magnify', 1.1, @isnumeric);
	p.addOptional('XMagnify', 1.0, @isnumeric);
	p.addOptional('YMagnify', 1.0, @isnumeric);
	p.addOptional('ChangeMagnify', 1.1, @isnumeric);
	p.addOptional('IncreaseChange', 1.1, @isnumeric);
	p.addOptional('MinValue', 1.1, @isnumeric);
	p.addOptional('MaxZoomScrollCount', 30, @isnumeric);
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
    
	zoomScrollCount = 0;
    orig.h=[];
    orig.XLim=[];
    orig.YLim=[];
    
	% Applies zoom
    function zoom_fcn(src, cbdata)
        scrollChange = cbdata.VerticalScrollCount; % -1: zoomIn, 1: zoomOut
		
		if ((zoomScrollCount - scrollChange) <= opt.MaxZoomScrollCount)
			axish = gca;

			if (isempty(orig.h) || axish ~= orig.h)
				orig.h = axish;
				orig.XLim = axish.XLim;
				orig.YLim = axish.YLim;
			end
		
			% calculate the new XLim and YLim
			cpaxes = mean(axish.CurrentPoint);
			newXLim = (axish.XLim - cpaxes(1)) * (opt.Magnify * opt.XMagnify)^scrollChange + cpaxes(1);
			newYLim = (axish.YLim - cpaxes(2)) * (opt.Magnify * opt.YMagnify)^scrollChange + cpaxes(2);
			
			newXLim = floor(newXLim);
			newYLim = floor(newYLim);
			% only check for image border location if user provided ImgWidth
			if (opt.ImgWidth > 0)
				if (newXLim(1) >= 0 && newXLim(2) <= opt.ImgWidth && newYLim(1) >= 0 && newYLim(2) <= opt.ImgHeight)
					axish.XLim = newXLim;
					axish.YLim = newYLim;
					zoomScrollCount = zoomScrollCount - scrollChange;
				else
					axish.XLim = orig.XLim;
					axish.YLim = orig.YLim;
					zoomScrollCount = 0;
				end
			else
				axish.XLim = newXLim;
				axish.YLim = newYLim;
				zoomScrollCount = zoomScrollCount - scrollChange;
			end
			%fprintf('XLim: [%.3f, %.3f], YLim: [%.3f, %.3f]\n', axish.XLim(1), axish.XLim(2), axish.YLim(1), axish.YLim(2));
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
		
		% MATLAB lack of anti-aliasing deforms the image if XLims & YLims are not integers
		newXLims = round(newXLims);
		newYLims = round(newYLims);
		
		% Update Axes limits
		if (newXLims(1) > 0.0 && newXLims(2) < opt.ImgWidth)
			set(hAx,'Xlim',newXLims);
		end
		if (newYLims(1) > 0.0 && newYLims(2) < opt.ImgHeight)
			set(hAx,'Ylim',newYLims);
		end
	end
end