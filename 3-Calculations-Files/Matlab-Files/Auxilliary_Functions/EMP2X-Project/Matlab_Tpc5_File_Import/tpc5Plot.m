% Matlab Example, plot multiple traces from tpc5 file
% Copyright: 2018 Elsys AG
% Author: 2018-03-12, Thomas Berger
% Description:
% This example shows how to plot traces

function  tpc5Plot(x, C,opt,n,fig,all)
% define plot area and clear
figure(fig);
clf;

if (all==true)
    % All traces into the same plot
    plot(x,C);
    labeltpcplot(opt,n,1,n);
else
    % Each traces into a single plot
    for z=1:n
        subplot(n,1,z);
        plot(x,C(z,:));
        labeltpcplot(opt,n,z,z);
    end
end
return

% Label both axes, create legend with traces
function labeltpcplot(opt,n,chnfrom,chnto)

% Y-Label definition
y='';
for z=chnfrom:chnto
    y =[y,'[',opt(z).physicalUnit,'] '];
end

% define legend
clear l;
for z=chnfrom:chnto
    tmp= [int2str(z),': "',opt(z).name,'" [',opt(z).physicalUnit,'] '];   
    if (z==chnfrom)
        l= tmp;
    else
        l=char(l,tmp);
    end
end

% Write title on top of the first plot
if (chnfrom==1)
    title([int2str(n),' Trace(s)']);
end;
xlabel('Seconds')
ylabel(y);
legend(l);

return
