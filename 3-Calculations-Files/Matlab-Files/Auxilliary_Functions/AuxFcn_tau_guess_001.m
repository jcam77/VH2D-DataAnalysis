function [tau_guess] = AuxFcn_tau_guess_001(T)
% AuxFcn_tau_guess_001
% Estimate tau from temperature using an empirical polynomial model.
%
% Inputs:
%   T            temperature input value
%
% Outputs:
%   tau_guess    estimated tau value
%Normilized t (where x is the t normalized by mean 369.9 and std 206.4)
x=(T-369.9)/206.4;
p1=0.1031;
p2=0.03623;
p3=-0.6706;
p4=-0.2852;
p5=1.488;
p6=0.7601;
p7=-1.004;
p8=-1.749;
p9=1.312;
tau_guess =  p1*x^8+p2*x^7+p3*x^6+p4*x^5+p5*x^4+p6*x^3+p7*x^2+p8*x+p9;
end
