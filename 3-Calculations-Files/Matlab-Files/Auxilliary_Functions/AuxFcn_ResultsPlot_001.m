function AuxFcn_ResultsPlot_001(Directories,AuxFcn_GS,Test,Time_LabV,TempResultsData2R,Execute,varargin)
% AuxFcn_ResultsPlot_001
% Build result plots for specified test cases with interval patches.
%
% Inputs:
%   Directories      project directory registry
%   AuxFcn_GS        graphical settings struct
%   Test             test selector string (e.g., 'Test-001')
%   Time_LabV        time data file reference
%   TempResultsData2R result data file reference(s)
%   Execute          execution flag ('Execute' to run)
%   varargin         test-specific interval/index arguments
%
% Outputs:
%   (none)           generates and formats figures
switch Execute
    case 'Execute'
        ResultsDataDir = Directories{6,1};
        AuxFcn_cdtemp(ResultsDataDir)
        switch Test
            
            case 'Test-001'
                load(Time_LabV)
                load(TempResultsData2R)
                x = RealTime2Plot-RealTime2Plot(varargin{1});
                y = SRFT;
                xstart = knnsearch(x,varargin{3});
                xend = knnsearch(x,varargin{4});
                figName = Test;
                figure('Name',figName)
                
                %% Patch Test Intervals
                [Patch_1,Patch_2,Patch_3] = AuxFcn_Patch_Settings(x,y,AuxFcn_GS,'Execute','NoExtaPatch',varargin{1},varargin{2});
                hold on
                %% Graphical Representation
                Interv_1 = plot(x(xstart:varargin{1}),y(xstart:varargin{1}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.grey_x,'MarkerFaceColor',AuxFcn_GS.grey);
                hold on
                Interv_2 = plot(x(varargin{1}:varargin{2}),y(varargin{1}:varargin{2}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.darkred_x,'MarkerFaceColor',AuxFcn_GS.darkred);
                hold on
                Interv_3 = plot(x(varargin{2}:xend),y(varargin{2}:xend),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.skyblue_x,'MarkerFaceColor',AuxFcn_GS.skyblue);
                
                %% Info & Settings
                Test_Intervals = legend([Patch_1 Patch_2 Patch_3],'Initial Interval','Heating Interval','Natural Cooling Interval','Location','SouthEast');
                xlim([x(xstart)-0.5 x(xend)+0.5])
                ylim([min(y)-5 max(y)+5])
                AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{append('Study of a Pump ',Test),'"Pump seal exposed to similar conditions where the pump runs without a cooling system."'},AuxFcn_GS.Font_Size-4)
                AuxFcn_Grid_Style(0.5,0.75)
                
                %% Fit Curve
                xstart = knnsearch(x,0);
                yend = knnsearch(y,120);
                Time = x(xstart:yend);
                Temperature = y(xstart:yend);
                [xData, yData] = prepareCurveData( Time, Temperature );
                
                % Set up fittype and options.
                ft = fittype( 'exp2' );
                opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
                opts.Display = 'Off';
                opts.StartPoint = [77.6440807183456 0.0041967814530218 -49.7879071962126 -0.0302890797575812];
                
                % Fit model to data.
                [fitresult, gof] = fit( xData, yData, ft, opts );
                
                % Plot fit with data.
                figure( 'Name', 'Surface Temperature vs Time' );
                h1 = plot( fitresult,xData,yData, 'predobs');
                set(h1,'Color',AuxFcn_GS.darkblue)
                hold on
                h2 = plot(xData,yData,'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.darkred_x,'MarkerFaceColor',AuxFcn_GS.darkred);
                hold on
                % Label axes
                xlabel( 'Time', 'Interpreter', 'latex' );
                ylabel( 'Temperature', 'Interpreter', 'latex' );
                grid on
                legend([h1(2) h1(3) h1(4) h2],'Curve Fit', 'Lower bounds Curve Fit', 'Upper bounds Curve Fit','Surface Temperature', 'Location', 'NorthEast', 'Interpreter', 'none' );
                hold on
                TargetTemp = knnsearch(yData,varargin{5});
                TimeTarget = xData(TargetTemp);
                AuxFcn_hline(yData(TargetTemp),'r',append('Temperature Target:  ', num2str(yData(TargetTemp),'%4.1f') ,'$[^{\circ}C] \pm 7.2$'))
                AuxFcn_vline(TimeTarget,'r',append('Estimated Time: ',num2str(TimeTarget,'%4.1f'), '$[s] \pm 6.0$'))
                %% Info & Settings
                AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{append('Study of a Pump ',Test),'"Curve Fitting for Time Estimation to reach Target Temperature"'},AuxFcn_GS.Font_Size-4)
                AuxFcn_Grid_Style(0.5,0.75)
                
            case 'Test-002'
                load(Time_LabV)
                load(TempResultsData2R)
                x = RealTime2Plot-RealTime2Plot(varargin{1});
                y = SRFT;
                xstart = knnsearch(x,varargin{4});
                xend = knnsearch(x,varargin{5});
                figName = Test;
                figure('Name',figName)
                
                %% Patch Test Intervals
                [Patch_1,Patch_2,Patch_3,Patch_4] = AuxFcn_Patch_Settings(x,y,AuxFcn_GS,'Execute','ExtaPatch',varargin{1},varargin{2},varargin{3});
                hold on
                %% Graphical Representation
                Interv_1 = plot(x(xstart:varargin{1}),y(xstart:varargin{1}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.grey_x,'MarkerFaceColor',AuxFcn_GS.grey);
                hold on
                Interv_2 = plot(x(varargin{1}:varargin{2}),y(varargin{1}:varargin{2}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.darkred_x,'MarkerFaceColor',AuxFcn_GS.darkred);
                hold on
                Interv_3 = plot(x(varargin{2}:xend),y(varargin{2}:xend),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.skyblue_x,'MarkerFaceColor',AuxFcn_GS.skyblue);
                hold on
                Interv_4 = plot(x(varargin{3}:xend),y(varargin{3}:xend),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.lightblue_x,'MarkerFaceColor',AuxFcn_GS.lightblue);
                %% Info & Settings
                Test_Intervals = legend([Patch_1 Patch_2 Patch_3 Patch_4],'Initial Interval','Heating Interval','Intermittent Water-Spray Cooling Interval','Continuous Water-Spray Cooling Interval','Location','SouthEast');
                xlim([x(xstart)-0.5 x(xend)+0.5])
                ylim([min(y)-5 max(y)+5])
                AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{append('Study of a Pump ',Test),'"Pump seal exposed to similar conditions where the pump runs without a cooling system."'},AuxFcn_GS.Font_Size-4)
                AuxFcn_Grid_Style(0.5,0.75)
                
            case 'Test-003'
                load(Time_LabV)
                load(TempResultsData2R)
                x = RealTime2Plot(1:varargin{3})-RealTime2Plot(varargin{1});
                y = SRFT(1:varargin{3});
                figName = Test;
                figure('Name',figName)
                
                %% Patch Test Intervals
                [Patch_1,Patch_2,Patch_3] = AuxFcn_Patch_Settings(x,y,AuxFcn_GS,'Execute','NoExtaPatch',varargin{1},varargin{2});
                hold on
                %% Graphical Representation
                Interv_1 = plot(x(1:varargin{1}),y(1:varargin{1}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.grey_x,'MarkerFaceColor',AuxFcn_GS.grey);
                hold on
                Interv_2 = plot(x(varargin{1}:varargin{2}),y(varargin{1}:varargin{2}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.darkred_x,'MarkerFaceColor',AuxFcn_GS.darkred);
                hold on
                Interv_3 = plot(x(varargin{2}:end),y(varargin{2}:end),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.skyblue_x,'MarkerFaceColor',AuxFcn_GS.skyblue);
                
                %% Info & Settings
                Test_Intervals = legend([Patch_1 Patch_2 Patch_3],'Initial Interval','Heating Interval','Natural Cooling Interval','Location','SouthEast');
                xlim([x(1)-0.5 x(end)+0.5])
                ylim([min(y)-5 max(y)+5])
                AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{append('Study of a Pump ',Test),'"Pump seal exposed to similar conditions where the pump runs without a cooling system."'},AuxFcn_GS.Font_Size-4)
                AuxFcn_Grid_Style(0.5,0.75)
                
            case 'Test-004'
                load(Time_LabV)
                load(TempResultsData2R)
                x = RealTime2Plot-RealTime2Plot(varargin{1});
                y = SRFT;
                xstart = knnsearch(x,varargin{4});
                xend = knnsearch(x,varargin{5});
                figName = Test;
                figure('Name',figName)
                
                %% Patch Test Intervals
                [Patch_1,Patch_2,Patch_3,Patch_4] = AuxFcn_Patch_Settings(x,y,AuxFcn_GS,'Execute','ExtaPatch',varargin{1},varargin{2},varargin{3});
                hold on
                %% Graphical Representation
                Interv_1 = plot(x(xstart:varargin{1}),y(xstart:varargin{1}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.grey_x,'MarkerFaceColor',AuxFcn_GS.grey);
                hold on
                Interv_2 = plot(x(varargin{1}:varargin{2}),y(varargin{1}:varargin{2}),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.darkred_x,'MarkerFaceColor',AuxFcn_GS.darkred);
                hold on
                Interv_3 = plot(x(varargin{2}:xend),y(varargin{2}:xend),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.skyblue_x,'MarkerFaceColor',AuxFcn_GS.skyblue);
                hold on
                Interv_4 = plot(x(varargin{3}:xend),y(varargin{3}:xend),'o','MarkerSize',4,'MarkerEdgeColor',AuxFcn_GS.lightblue_x,'MarkerFaceColor',AuxFcn_GS.lightblue);
                %% Info & Settings
                Test_Intervals = legend([Patch_1 Patch_2 Patch_3 Patch_4],'Initial Interval','Heating Interval','Natural Cooling Interval','Surface Temperature measured is swapped to carbon seal.','Location','SouthEast');
                xlim([x(xstart)-0.5 x(xend)+0.5])
                ylim([min(y)-5 max(y)+5])
                AuxFcn_Figure_Settings('Time [s]','Surface Temperature $[^{\circ}C]$','',{append('Study of a Pump ',Test),'"Pump seal exposed to similar conditions where the pump runs without a cooling system."'},AuxFcn_GS.Font_Size-4)
                AuxFcn_Grid_Style(0.5,0.75)
        end
    case 'Not Execute'
end
end
