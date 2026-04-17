function AuxFcn_CalibCurveAverage_002(Directories,ConvertedData2R,CleanData2RW,ResultName,Ntau,Execute)
% AuxFcn_CalibCurveAverage_002
% Compute grouped averages/std for calibration temperature and tau data.
%
% Inputs:
%   Directories       project directory registry
%   ConvertedData2R   converted data references per test/file
%   CleanData2RW      clean data base name/prefix
%   ResultName        output base name
%   Ntau              grouping size for averaging
%   Execute           execution flag ('Execute' to run)
%
% Outputs:
%   (none)            saves/exports processed calibration summaries
switch Execute
    case 'Execute'
        ResultsDataDir = Directories{6,1};
        N_Test=numel(ConvertedData2R);
        for i = 1:N_Test
            N_Files=numel(ConvertedData2R{i,1});
            %% Load Data Names
            str1 ='Test_';
            TestIndex=append(str1,num2str(i));
            CleanData2Load = append(CleanData2RW,TestIndex);
            [OutputData1] = MainFcn_LoadData_001(Directories,'Clean Data',CleanData2Load);
            Results2Load = append(ResultName,'TauResults',TestIndex);
            [OutputData2] = MainFcn_LoadData_001(Directories,'Results Data',Results2Load);
            for j = 1:N_Files
                %% Variables Names
                str1 ='Test_';
                TestIndex=append(str1,num2str(i),'_',num2str(j));
                SRFT_LabV = eval(append('OutputData1.SRFT_LabV',TestIndex));
                Tau = eval('OutputData2.Tau');
                %% Temperature Average Calculations
                s1 = size(SRFT_LabV, 1);      % Find the next smaller multiple of n
                m  = s1 - mod(s1, Ntau);
                y  = reshape(SRFT_LabV(1:m), Ntau, []);     % Reshape x to a [n, m/n] matrix
                SRFT_LabV_Avg = transpose(sum(y, 1) / Ntau);  % Calculate the mean over the 1st dim
                SRFT_LabV_Std = transpose(std(y));
                %% Tau Average Calculations
                s1 = size(Tau, 1);      % Find the next smaller multiple of n
                m  = s1 - mod(s1, Ntau);
                y  = reshape(Tau(1:m), Ntau, []);     % Reshape x to a [n, m/n] matrix
                TauAvg = transpose(sum(y, 1) / Ntau);  % Calculate the mean over the 1st dim
                sdTauAvg = transpose(std(y));           
                
                %% Save Temperature Average Calculated and SD
                AuxFcn_cdtemp(ResultsDataDir)
                AvgResultsData2RW = append(ResultName,'AvgResults');
                save(append(AvgResultsData2RW,str1,num2str(i),'.mat'),'SRFT_LabV_Avg','SRFT_LabV_Std','TauAvg','sdTauAvg','-nocompression')
                clear TauAvg sdTauAvg SRFT_LabV_Avg SRFT_LabV_Std
            end
        end
        
    case 'Not Execute'
end

end
