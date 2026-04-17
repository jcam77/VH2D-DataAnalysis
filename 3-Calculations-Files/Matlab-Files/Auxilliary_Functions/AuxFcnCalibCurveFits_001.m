function [fitresult,gof] = AuxFcnCalibCurveFits_001(AuxFcn_GS,TAU_1_Avg,TAU_1_Std, TEMP_1_Avg,TEMP_1_Std, TAU_2_Avg, TEMP_2_Avg, TAU_3_Avg, TEMP_3_Avg, TAU_4_Avg, TEMP_4_Avg,TAU_ALL, TEMP_ALL)
% AuxFcnCalibCurveFits_001
% Fit quadratic calibration curves for grouped tau-temperature datasets.
%
% Inputs:
%   AuxFcn_GS     graphical settings struct (colors/styles)
%   TAU_*_Avg     averaged tau values for each dataset
%   TAU_*_Std     tau standard deviations for error bars
%   TEMP_*_Avg    averaged temperature values for each dataset
%   TEMP_*_Std    temperature standard deviations for error bars
%   TAU_ALL       concatenated tau values
%   TEMP_ALL      concatenated temperature values
%
% Outputs:
%   fitresult     cell array with fitted models
%   gof           goodness-of-fit struct array
close all
%% Initialization.

% Initialize arrays to store fits and goodness-of-fit.
fitresult = cell( 4, 1 );
gof = struct( 'sse', cell( 4, 1 ), ...
    'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', [] );

%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( TAU_1_Avg, TEMP_1_Avg );

% Set up fittype and options.
ft = fittype( 'poly2' );

% Fit model to data.
[fitresult{1}, gof(1)] = fit( xData, yData, ft );

% Plot fit with data.
figure( 'Name', 'Calibration Curve fit 1' );
h = plot( fitresult{1}, xData, yData, 'predobs');

yneg = TEMP_1_Std;
ypos = TEMP_1_Std;
xneg = TAU_1_Std;
xpos = TAU_1_Std;
hold on 
e = errorbar(xData,yData,yneg,ypos,xneg,xpos,'s');
e.Color = AuxFcn_GS.darkblue;
e.CapSize = 15;
e.MarkerSize = 10;
e.MarkerEdgeColor = AuxFcn_GS.darkred_x;
e.MarkerFaceColor = AuxFcn_GS.darkblue;

legend( h, 'TEMP_1_Avg vs. TAU_1_Avg', 'Calibration Curve fit 1', 'Lower bounds (Calibration Curve fit 1)', 'Upper bounds (Calibration Curve fit 1)', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'TAU_1_Avg', 'Interpreter', 'none' );
ylabel( 'TEMP_1_Avg', 'Interpreter', 'none' );
grid on

%% Fit: 'untitled fit 2'.
[xData, yData] = prepareCurveData( TAU_2_Avg, TEMP_2_Avg );

% Set up fittype and options.
ft = fittype( 'poly2' );

% Fit model to data.
[fitresult{2}, gof(2)] = fit( xData, yData, ft );

% Plot fit with data.
figure( 'Name', 'Calibration Curve fit 2' );
h = plot( fitresult{2}, xData, yData,'predobs' );
legend( h, 'TEMP_2_Avg vs. TAU_2_Avg', 'Calibration Curve fit 2', 'Lower bounds (Calibration Curve fit 2)', 'Upper bounds (Calibration Curve fit 2)', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'TAU_2_Avg', 'Interpreter', 'none' );
ylabel( 'TEMP_2_Avg', 'Interpreter', 'none' );
grid on

%% Fit: 'untitled fit 3'.
[xData, yData] = prepareCurveData( TAU_3_Avg, TEMP_3_Avg );

% Set up fittype and options.
ft = fittype( 'poly2' );

% Fit model to data.
[fitresult{3}, gof(3)] = fit( xData, yData, ft );

% Plot fit with data.
figure( 'Name', 'Calibration Curve fit 3' );
h = plot( fitresult{3}, xData, yData, 'predobs');
legend( h, 'TEMP_3_Avg vs. TAU_3_Avg', 'Calibration Curve fit 3', 'Lower bounds (Calibration Curve fit 3)', 'Upper bounds (Calibration Curve fit 3)', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'TAU_3_Avg', 'Interpreter', 'none' );
ylabel( 'TEMP_3_Avg', 'Interpreter', 'none' );
grid on

%% Fit: 'untitled fit 4'.
[xData, yData] = prepareCurveData( TAU_4_Avg, TEMP_4_Avg );

% Set up fittype and options.
ft = fittype( 'poly2' );

% Fit model to data.
[fitresult{4}, gof(4)] = fit( xData, yData, ft );

% Plot fit with data.
figure( 'Name', 'Calibration Curve fit 4' );
h = plot( fitresult{4}, xData, yData , 'predobs');
legend( h, 'TEMP_4_Avg vs. TAU_4_Avg', 'Calibration Curve fit 4', 'Lower bounds (Calibration Curve fit 4)', 'Upper bounds (Calibration Curve fit 4)', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'TAU_4_Avg', 'Interpreter', 'none' );
ylabel( 'TEMP_4_Avg', 'Interpreter', 'none' );
grid on
%% Fit: 'untitled fit 5'.
[xData, yData] = prepareCurveData( TAU_ALL, TEMP_ALL );

% Set up fittype and options.
ft = fittype( 'poly2' );

% Fit model to data.
[fitresult{5}, gof(5)] = fit( xData, yData, ft );

% Plot fit with data.
figure( 'Name', 'ALL Materials fit 5' );
h = plot( fitresult{5}, xData, yData, 'predobs' );
legend( h, 'TEMP_ALL vs. TAU_ALL', 'untitled fit 5', 'Lower bounds (untitled fit 5)', 'Upper bounds (untitled fit 5)', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'TAU_ALL', 'Interpreter', 'none' );
ylabel( 'TEMP_ALL', 'Interpreter', 'none' );
grid on


