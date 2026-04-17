function helperMRAPlot(data,mra,time,type,titlestr,varargin)
% This function may change or be removed in a future release.

% Copyright 2019 The MathWorks, Inc.
if ~strcmpi(type,'wavelet')
    mra = mra.';
end

Ncomp = size(mra,1)+1;
plotheight = 1/(Ncomp+2);

colorAx = [];

if ~isempty(varargin)
   colorAx = varargin{1}; 
end

f = figure;
f.Color = [1 1 1];
f.Position(4) = 500;
f.Position(2) = 200;
Numplots = size(mra,1)+1;

for kk = 1:Numplots
    
    ax(kk) = subplot(Numplots,1,kk,'parent',f); %#ok<*AGROW>
    
    if kk == 1
        ax(kk).Title.String = titlestr;
    end
    if kk < Numplots
        plot(ax(kk),time,mra(kk,:));
        ax(kk).XLim = [min(time) max(time)];
        minval = min(mra(kk,:));
        maxval = max(mra(kk,:));
        ax(kk).YLim = [minval maxval];
        ax(kk).XLim = [time(1) time(end)];
        ax(kk).YTickLabel = {};
        if ~isempty(colorAx) && ismember(kk,colorAx)
            ax(kk).Color = [0.8275 0.8275 0.8275];
        end
    else
        plot(ax(kk),time,data);
        ax(kk).XLim = [min(time) max(time)];
        minval = min(data);
        maxval = max(data);
        ax(kk).YLim = [minval maxval];
        ax(kk).XLim = [time(1) time(end)];
        ax(kk).YTickLabel = {};
        if ~isempty(colorAx) && ismember(kk,colorAx)
            ax(kk).Color = [0.8275 0.2875 0.8275 ];
        end
    end
    if kk <= Numplots-2
        if strcmpi(type,'wavelet')
            ylabel(ax(kk), ['$\tilde{D}$' num2str(kk)], ...
                'interpreter','latex','fontsize',14);
        else
            ylabel(ax(kk),['IMF ' num2str(kk)]);
        end
    elseif kk == Numplots - 1
        if strcmpi(type,'wavelet')            
            ylabel(ax(kk),['$S$' num2str(kk-1)],'interpreter','latex',...
                'fontsize',14);
        else
            ylabel(ax(kk),['IMF ' num2str(kk)]);
        end
    elseif kk == Numplots
        ylabel(ax(kk),'Data');
    end
    ax(kk).YLabel.Rotation = 0;
    ax(kk).YLabel.HorizontalAlignment = 'right';
    ax(kk).YLabel.VerticalAlignment = 'middle';
    
    if kk < Numplots
        ax(kk).XTickMode = 'manual';
        ax(kk).XTickLabel = {};
    else
        ax(kk).XLabel.String = 'time';
    end
    
end




allax = ax;
linkaxes(allax,'x');

% Resize each subplot to almost touch the one above.
posn = cell2mat(get(allax,'Position'));
if Ncomp >= 10
    Height = 0.08;
else
    Height = plotheight;
end

% Fix the height
posn(:,4) = Height;
Bottom = posn(:,2);
Bottom(1) = 0.82;


plt = 1;
while plt < Numplots
    plt = plt+1;
    Bottom(plt) = Bottom(plt-1)- Height;
end
posn(:,2) = Bottom;
set(ax,{'Position'},num2cell(posn,2));

drawnow nocallbacks;


[~,minax] = min(posn(:,2));
xlabel(allax(minax),'Time');


nrows = 6;
ncols = 1;
row = (nrows-1) -floor((Numplots-1)/ncols);

% Set up the scroll bar if p exceeds 6
% From here on out set up scrollbar if needed
scroll_hndl = findall(f,'Type','uicontrol','Tag','scroll');

if ~isempty(scroll_hndl)
    delete(scroll_hndl);
end

ax_indx = findall(f,'Type','axes');

if length(ax_indx)==1
    maxrownr = -Inf;
    minrownr = Inf;
else
    maxrownr = Numplots-6;
    minrownr = 6-(Numplots+1);
end

% Set up slider
scroll_hndl = uicontrol('Parent',f,'Units','normalized',...
    'Style','Slider',...
    'Position',[.98,0,.02,1],...
    'Min',0,...
    'Max',1,...
    'Value',1,...
    'Visible','off',...
    'Tag','scroll',...
    'Callback',@(scr,event) scroll(f,1));
z = zoom(f);
if strcmp(z.Enable,'off')
    f.WindowScrollWheelFcn = @(varargin)wheelScroll(varargin{:});
elseif strcmp(z.Enable,'on')
    z.Enable = 'off';
    f.WindowScrollWheelFcn = @(varargin)wheelScroll(varargin{:});
    z.Enable = 'on';
end


% Making it visible when needed. We do this when any bottom coordinates are
% less than 0
if any(posn(:,2) < 0.05)
    set(scroll_hndl,'visible','on')
end


maxrownr = max(maxrownr(:),max(-row(:)));
minrownr = min(minrownr(:),min(-row(:)));

% Adjust the slider step-sizes to account for the number of rows of
% subplots. Major step should be essentially the entire extent.
set(scroll_hndl,...
    'sliderstep',[1/nrows 1]/(1/((nrows)/max(1,1+maxrownr(:)-minrownr(:)-nrows))));
allax(1).Title.String = titlestr;





%-------------------------------------------------------------------------
function scroll(fig,old_val)


fig = handle(fig);

% Get the handle of the scroll-slider handle and all the handle
% to all the subplot axes
clbk_ui_hndl = findall(fig,'Type','uicontrol','Tag','scroll');
ax_hndl = findall(fig,'-isa', 'matlab.graphics.axis.Axes');
a_pos = cell2mat(get(ax_hndl,'Position'));

pos_y_range = [min(.07,min(a_pos(:,2))) max(a_pos(:,2) + a_pos(:,4) )+.07-.9];

val = get(clbk_ui_hndl,'value');
step = ( old_val - val) * diff(pos_y_range);


for ii = 1:length(ax_hndl)
    set(ax_hndl(ii),'position',get(ax_hndl(ii),'position') + [0 step 0 0]);
    
end

set(clbk_ui_hndl,'callback',@(scr,event) scroll(fig,val));

% end scroll
%--------------------------------------------------------------------------
function wheelScroll(src,evnt)

C = findobj(src,'type','uicontrol');
MaxVal = get(C,'Max'); %1
minval = get(C,'Min'); %0
sliderstep = get(C,'SliderStep');
oldval = get(C,'value');

amtAdj = evnt.VerticalScrollCount *  sliderstep(1)/3;
newSet = oldval-amtAdj;

newSet = max(minval,newSet);
newSet = min(MaxVal,newSet);
set(C,'value',newSet);
scroll(src,oldval)


