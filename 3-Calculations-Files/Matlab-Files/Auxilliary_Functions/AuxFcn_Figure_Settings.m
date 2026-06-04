%% Figure Settings
function AuxFcn_Figure_Settings(xlab,ylab,zlab,titel,S)              % format figure function
% AuxFcn_Figure_Settings
% Apply common axis/figure formatting and labels.
%
% Inputs:
%   xlab, ylab, zlab  axis label strings
%   titel             figure title string
%   S                 font size
%
% Outputs:
%   (none)            applies formatting to current figure/axes
% get plotting started
set(0,'defaulttextinterpreter','latex')
set(0,'defaultAxesTickLabelInterpreter','latex'); 
set(0,'defaultLegendInterpreter','latex');
% blue = [0 0.4470 0.7410];
% grey = .75*[1 1 1];
% mark = 'ooss';
set(gca, 'FontName', "Helvetica") ;
% figure                                       % create figure
hold on                                      % multiple plots
box on                                       % draw a box around plot
set(gcf,'color','w');                        % set background to white
xlabel(xlab)                                 % label x-axis
ylabel(ylab)                                 % label y-axis
zlabel(zlab)                                 % label z-axis
title(titel)                                 % name the title
% subtitle(subtitle)
set(gca,'Fontsize', S);                      % set the fontsize
grid on
end
