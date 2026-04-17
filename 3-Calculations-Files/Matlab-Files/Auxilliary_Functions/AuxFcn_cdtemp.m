%% Temporary change directory
%
%   cdtemp(DIR)
%       change current directory to DIR, but automatically return to
%       original directory when the calling function or subfunction
%       finishes or gets an error.
%
%       Basically this function is equivalent with adding next code to your 
%       function:
%           old_dir = cd(DIR);
%           C = onCleanup(@()cd(old_dir));
%
%       When CDTEMP is used multiple times in the same function or
%       subfunction, then on exit current directory will be set to the
%       first orginal directory.
%
%       The CLEAR command will also change current directory to the first
%       original directory.
%
% Example:
%   Change to new directory and return when the function that uses this 
%   command finishes.
%       cdtemp('S:\data');
%
%   Change to new directory, do your things and return to original 
%   directory.
%       cdtemp('S:\data');
%       ...
%       clear
%
% see als cd, onCleanup, clear

%% Last modified
%   $Date: 2013-02-02 18:41:41 +0100 (Sat, 02 Feb 2013) $
%   $Author: biggelar $
%   $Rev: 12966 $

%% History
%   2013-02-02  biggelar    submitted to Matlab Central
%   2012-11-09  biggelar    simplify
%   2012-10-26  biggelar    Created

%% Copyright (c) 2013, Peter van den Biggelaar
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.


% ------------------------------------------------------------------------
function AuxFcn_cdtemp(DIR)

%% command to switch to original directory when a function exits
command = ['if ~exist(''cdtemp_old_dir_'', ''var''),', ...
           '    cdtemp_old_dir_ = cd(''' DIR ''');', ...
           '    cdtemp_onCleanup_ = onCleanup(@()cd(cdtemp_old_dir_));', ...
           'else', ...
           '    cd(''' DIR ''');' ...
           'end'];

%% evaluate command in callers workspace:
evalin('caller', command);
