function AuxFcn_SimpleResultsPlotHistogram_001(AuxFcn_GS,figName,PlotTitle,TempResultsData2R,lgd1,lgd2,lgd3,lgd4,lgdAll,Execute)
% AuxFcn_SimpleResultsPlotHistogram_001
% Plot histogram comparison across multiple result datasets.
%
% Inputs:
%   AuxFcn_GS          graphical settings struct
%   figName            figure name
%   PlotTitle          plot title text
%   TempResultsData2R  cell array of result file references
%   lgd1..lgd4, lgdAll legend labels
%   Execute            execution flag ('Execute' to run)
%
% Outputs:
%   (none)             generates histogram figure
switch Execute
    case 'Execute'
        figure('Name',figName)
        
        %% Graphical Representation
        load(TempResultsData2R{1,1})
        y1 = SRFT;
        Hist_1 = histogram(gca,y1,'FaceColor',AuxFcn_GS.darkred);

        hold on
        load(TempResultsData2R{2,1})
        y2 = SRFT;
        Hist_2 = histogram(gca,y2,'FaceColor',AuxFcn_GS.yellow);

        hold on
        load(TempResultsData2R{3,1})
        y3 = SRFT;
        Hist_3 = histogram(gca,y3,'FaceColor',AuxFcn_GS.lightblue);

        hold on
        load(TempResultsData2R{4,1})
        y4 = SRFT;
        Hist_4 = histogram(gca,y4,'FaceColor',AuxFcn_GS.grey);

        hold on
        load(TempResultsData2R{4,1})
        y5 = SRFT;
        Hist_All = histogram(gca,y5,'FaceColor',AuxFcn_GS.green);

        %% Info & Settings

        lgd = legend([Hist_1 Hist_2 Hist_3 Hist_4 Hist_All],{lgd1,lgd2,lgd3,lgd4,lgdAll},'Location','SouthEast', 'Interpreter', 'latex');
       
        lgd.FontSize = 10;
%         xlim([x(1)-0.5 x(end)+0.5])
%         ylim([min(y)-10 max(y)+10])
%         AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{'Calibration Curves Analysis','"Using Data from Test-001"'},AuxFcn_GS.Font_Size-2)
        AuxFcn_Figure_Settings('Surface Temperature $[^{\circ}C]$','','',{PlotTitle{1,1},PlotTitle{1,2}},AuxFcn_GS.Font_Size-2)
        AuxFcn_Grid_Style(0.5,0.75)
        %%
        yAll=[y1;y2;y3;y4;y5];
        
    case 'Not Execute'
end
end
