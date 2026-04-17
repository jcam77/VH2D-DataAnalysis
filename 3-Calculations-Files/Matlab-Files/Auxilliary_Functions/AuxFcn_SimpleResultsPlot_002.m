function AuxFcn_SimpleResultsPlot_002(AuxFcn_GS,figName,PlotTitle,Time_LabV,TempResultsData2R,lgd1,lgd2,lgd3,lgd4,lgdAll,Execute)
% AuxFcn_SimpleResultsPlot_002
% Alternative simple multi-dataset plot for calibration/result data.
%
% Inputs:
%   AuxFcn_GS          graphical settings struct
%   figName            figure name
%   PlotTitle          plot title text
%   Time_LabV          time data file reference
%   TempResultsData2R  cell array of result file references
%   lgd1..lgd4, lgdAll legend labels
%   Execute            execution flag ('Execute' to run)
%
% Outputs:
%   (none)             generates combined results plot
switch Execute
    case 'Execute'
        load(Time_LabV)
        figure('Name',figName)
        
        %% Graphical Representation
        load(TempResultsData2R{1,1})
        x = RealTime2Plot;
        y = SRFT;
        CalibCurve_1 = plot(x,y,'o','MarkerSize',6,'MarkerEdgeColor',AuxFcn_GS.darkred_x,'MarkerFaceColor',AuxFcn_GS.darkred);
        hold on
        load(TempResultsData2R{2,1})
        x = RealTime2Plot;
        y = SRFT;
        CalibCurve_2 = plot(x,y,'v','MarkerSize',3,'MarkerEdgeColor',AuxFcn_GS.darkorange,'MarkerFaceColor',AuxFcn_GS.yellow);
        hold on
        load(TempResultsData2R{3,1})
        x = RealTime2Plot;
        y = SRFT;
        CalibCurve_3 = plot(x,y,'o','MarkerSize',6,'MarkerEdgeColor',AuxFcn_GS.lightblue_x,'MarkerFaceColor',AuxFcn_GS.lightblue);
        hold on
        load(TempResultsData2R{4,1})
        x = RealTime2Plot;
        y = SRFT;
        CalibCurve_4 = plot(x,y,'v','MarkerSize',3,'MarkerEdgeColor',AuxFcn_GS.grey_x,'MarkerFaceColor',AuxFcn_GS.grey);
        hold on
        load(TempResultsData2R{5,1})
        x = RealTime2Plot;
        y = SRFT;
        CalibCurve_All = plot(x,y,'o','MarkerSize',6,'MarkerEdgeColor',AuxFcn_GS.darkorange,'MarkerFaceColor',AuxFcn_GS.green);
        
        %% Info & Settings
        lgd = legend([CalibCurve_1 CalibCurve_2 CalibCurve_3 CalibCurve_4 CalibCurve_All],{lgd1,lgd2,lgd3,lgd4,lgdAll},...
            'Location','southeast', 'Interpreter', 'latex');
        lgd.FontSize = 8;
        xlim([x(1)-0.5 x(end)+0.5])
        ylim([min(y)-10 max(y)+10])
%         AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{'Calibration Curves Analysis','"Using Data from Test-001"'},AuxFcn_GS.Font_Size-2)
        AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{PlotTitle{1,1},PlotTitle{1,2}},AuxFcn_GS.Font_Size-2)
        AuxFcn_Grid_Style(0.5,0.75)
        
    case 'Not Execute'
end
end
