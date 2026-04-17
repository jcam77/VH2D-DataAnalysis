function AuxFcn_Grid_Style(GridAlpha,MinorGridAlpha)
% AuxFcn_Grid_Style
% Apply grid transparency styling to current axes.
%
% Inputs:
%   GridAlpha        major grid transparency
%   MinorGridAlpha   minor grid transparency
%
% Outputs:
%   (none)           updates current axes grid style
ax=gca;
ax.GridAlpha=GridAlpha;
ax.MinorGridAlpha=MinorGridAlpha;
grid on
