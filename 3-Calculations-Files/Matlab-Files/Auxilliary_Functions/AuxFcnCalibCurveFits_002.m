function [p1,p2,p3] = AuxFcnCalibCurveFits_002(Directories,ResultName,AuxFcn_GS,Testnum,TauAvg,sdTauAvg,SRFT_LabV_Avg,SRFT_LabV_Std,Execute)
% AuxFcnCalibCurveFits_002
% Fit polynomial calibration curve and return coefficients for one test.
%
% Inputs:
%   Directories       project directory registry
%   ResultName        base name for saving results
%   AuxFcn_GS         graphical settings struct
%   Testnum           test identifier/label
%   TauAvg            averaged tau values
%   sdTauAvg          tau standard deviations
%   SRFT_LabV_Avg     averaged temperature/signal reference values
%   SRFT_LabV_Std     standard deviation of reference values
%   Execute           execution flag ('Execute' to run)
%
% Outputs:
%   p1, p2, p3        fitted polynomial coefficients
switch Execute
    case 'Execute'
        ResultsDataDir = Directories{6,1};
        %% Initialization.
        %% Fit Curve
        [xData, yData] = prepareCurveData( TauAvg, SRFT_LabV_Avg );
        % Set up fittype and options.
        ft = fittype( {'tau^2', 'tau', '1'}, 'independent', 'tau', 'dependent', 'T', 'coefficients', {'p1', 'p2', 'p3'} );
        % Fit model to data.
        [fitresult, gof] = fit( xData, yData, ft );
        opts = fitoptions( 'Method', 'LinearLeastSquares' );
        coeffvals = coeffvalues(fitresult);
        % ci = confint(fitresult,0.95);
        % u_tau_Fit = (coeffvals(1,2)-ci(1,2) )/2;%standard uncertainty due to curve fit
        % R_2 = gof.rsquare;
        p1 = coeffvals(1,1) ;
        p2 = coeffvals(1,2) ;
        p3 = coeffvals(1,3) ;
        
        %% Plot fit with data.
        figure( 'Name',  append('Calibration Curve Fit Test ',Testnum) );
        h = plot( fitresult, xData, yData, 'predobs');
        yneg = SRFT_LabV_Std + yData*0.01;
        ypos = SRFT_LabV_Std + yData*0.01;
        xneg = sdTauAvg;
        xpos = sdTauAvg;
        hold on
        e = errorbar(xData,yData,yneg,ypos,xneg,xpos,'s');
        e.Color = AuxFcn_GS.darkblue;
        e.CapSize = 15;
        e.MarkerSize = 10;
        e.MarkerEdgeColor = AuxFcn_GS.darkred_x;
        e.MarkerFaceColor = AuxFcn_GS.darkblue;
        legend(h, 'Calibration Data', append('Calibration Curve Fit Test ',Testnum), 'Prediction Lower Bounds', 'Prediction Upper Bounds', 'Location', 'NorthEast', 'Interpreter', 'Latex' );
        % Label axes
        xlabel( 'Tau Average', 'Interpreter', 'Latex' );
        ylabel( 'Temperature Average', 'Interpreter', 'Latex' );
        grid on
        %% Variables Names
        str1 ='CalibCoeff_Test_';
        CalibCoeff = [p1;p2;p3];
        TestIndex=append(str1,Testnum);
        %% Save Temperature Average Calculated and SD
        AuxFcn_cdtemp(ResultsDataDir)
        AvgResultsData2RW = append(ResultName,TestIndex);
        save(append(AvgResultsData2RW,'.mat'),'CalibCoeff')
        clear CalibCoeff
    case 'Not Execute'
end

end




