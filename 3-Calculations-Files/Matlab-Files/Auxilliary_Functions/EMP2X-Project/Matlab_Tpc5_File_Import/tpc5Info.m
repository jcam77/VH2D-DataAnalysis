% Matlab Example, read number of traces from tpc5 file
% Copyright: 2018 Elsys AG
% Author: 2018-03-12, Thomas Berger
% Description:
% Return the number of traces in a tpc5 file


function [nrofTraces] = tpc5Info(filename)
	nrofTrace=0;

	% Read the file structure, just for get an overview
	n = h5info(filename, '/measurements/00000001/channels/');
	[nrofTraces,tmp] = size( n.Groups);
return


