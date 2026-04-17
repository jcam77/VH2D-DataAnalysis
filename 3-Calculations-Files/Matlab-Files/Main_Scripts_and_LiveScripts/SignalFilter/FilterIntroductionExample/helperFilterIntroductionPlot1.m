function helperFilterIntroductionPlot1(F1,Y1,F2,Y2,lgnd)
%helperFilterIntroductionPlot1 Helper function for FilterIntroduction.m example

% Copyright 2012 The MathWorks, Inc.

[F1,E1,U1] = engunits(F1);
[F2,~,~] = engunits(F2);

figure
semilogx(F1,10*log10(Y1))
hold on
if length(F2) == 2
  semilogx(F2*E1,Y2,'vr')
else
  semilogx(F2,10*log10(Y2))
end
xlabel(['Frequency in ' U1 'Hz'])
ylabel('Power Spectrum (dB)')
if nargin == 5
  legend(lgnd{:},'location','southwest')
end
grid on
axis tight
ax= axis;
axis([F1(2) ax(2:4)])
