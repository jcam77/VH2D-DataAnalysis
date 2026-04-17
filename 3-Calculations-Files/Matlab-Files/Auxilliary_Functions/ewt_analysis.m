function ewt_analysis(dataMatrix, Fs, selectedTests,MaxNumPeaks,HModes)
    % Function to perform Empirical Wavelet Transform (EWT) on multiple test signals
    % dataMatrix: n x m matrix where n = samples, m = number of tests
    % Fs: Sampling frequency in Hz
    % selectedTests: Array of test indices to process (e.g., [1 3 5] for tests 1, 3, and 5)

    numTests = size(dataMatrix, 2); % Total number of tests
    results = struct(); % Store results for each test
    summaryData = []; % Initialize numerical data matrix

    % Validate selected tests
    if any(selectedTests > numTests) || any(selectedTests < 1)
        error('Invalid test indices selected. Choose values between 1 and %d.', numTests);
    end
    
    % Loop over selected test cases
    for i = selectedTests
        fprintf('Processing Test %d...\n', i);
        
        % Perform EWT on the selected test
        [mra_ewt, cfs, wfb, info] = ewt(dataMatrix(:, i), MaxNumPeaks=MaxNumPeaks);
        
        % Convert peak frequencies and passbands to Hz
        PeakFrequencies = Fs * info.PeakFrequencies;
        freqPassbands = info.FilterBank.Passbands * Fs;
        
        % Store results for each test
        results(i).TestNumber = i;
        results(i).MRA = mra_ewt;
        results(i).Coefficients = cfs;
        results(i).WaveletBank = wfb;
        results(i).PeakFrequencies = PeakFrequencies;
        results(i).Passbands = freqPassbands;
        
        % Append numerical data for structured table
        numModes = length(PeakFrequencies);
        for j = 1:numModes
            summaryData = [summaryData; i, j, PeakFrequencies(j), freqPassbands(j,1), freqPassbands(j,2)];
        end

        % Plot results
        figure;
        % x0=10;
        % y0=10;
        % % Fig_width=25;
        % % Fig_height=12.5;
        % set(gcf,'units','centimeters','position',[x0,y0,Fig_width,Fig_height])
        helperMRAPlot_000(dataMatrix(:, i), mra_ewt, (0:length(dataMatrix)-1)/Fs, ...
                      "EWT", sprintf("Empirical Wavelet Transform - Test %d", i),PeakFrequencies,freqPassbands,HModes);
    end

    % Convert numerical array to table format
    summaryTable = array2table(summaryData, 'VariableNames', ...
        {'Test Number', 'Mode Number', 'Peak Frequency (Hz)', 'Passband Start (Hz)', 'Passband End (Hz)'});
    
    % Display table in MATLAB
    disp(summaryTable);

    % Save results in the workspace
    assignin('base', 'EWT_Results', results);
    assignin('base', 'EWT_SummaryTable', summaryTable);
    fprintf('EWT analysis completed for selected tests.\n');
end
