function concentrationEDA = AuxFcn_ExtractVH2DConcentrationWoI_001(runData, groupId, runId, woiPlan, options)
% AuxFcn_ExtractVH2DConcentrationWoI_001
% Extract concentration windows of interest selected during EDA.
%
% The function does not choose windows automatically. The caller provides
% each WoI explicitly after visual inspection. Results are stored in a
% group/run/stream/WoI structure so later summary tables can be generated
% from this traceable data product.

arguments
    runData (1,1) struct
    groupId (1,1) string
    runId (1,1) string
    woiPlan struct
    options.AppendTo struct = struct()
    options.ExistingConcentrationEDA struct = struct()
    options.SignalFieldName (1,1) string = "signal_vol_pct"
end

localRequireStructFields(woiPlan, ...
    ["Stream", "Path", "WoIName", "TimeWindow_s", "Status"], "woiPlan");

concentrationEDA = options.AppendTo;
if isempty(fieldnames(concentrationEDA))
    concentrationEDA = options.ExistingConcentrationEDA;
end
if isempty(fieldnames(concentrationEDA))
    concentrationEDA = struct();
    concentrationEDA.source = "AuxFcn_ExtractVH2DConcentrationWoI_001";
    concentrationEDA.groups = struct();
end

groupTokens = split(groupId, "-");
groupField = matlab.lang.makeValidName("Group_" + groupTokens(end));
runField = matlab.lang.makeValidName(strrep(runId, "-", "_"));

concentrationEDA.groups.(groupField).id = groupId;
concentrationEDA.groups.(groupField).runs.(runField).id = runId;

for iPlan = 1:numel(woiPlan)
    plan = woiPlan(iPlan);
    streamPath = string(plan.Path);
    streamFieldPath = split(streamPath, ".");
    streamStatus = string(plan.Status);
    woiField = matlab.lang.makeValidName(string(plan.WoIName));

    result = localExtractOneWoI(runData, plan, streamStatus, options.SignalFieldName);
    target = concentrationEDA.groups.(groupField).runs.(runField);
    target = localSetNestedField(target, [streamFieldPath; woiField], result);
    concentrationEDA.groups.(groupField).runs.(runField) = target;
end
end

function result = localExtractOneWoI(runData, plan, streamStatus, signalFieldName)
result = localEmptyResult(plan, streamStatus, signalFieldName);
if streamStatus ~= "use"
    return
end

data = localGetNestedField(runData, string(plan.Path));
if isfield(data, "status")
    dataStatus = string(data.status);
    if dataStatus ~= "" && dataStatus ~= "loaded" && dataStatus ~= "ok"
        result.status = dataStatus;
        return
    end
end

if ~isfield(data, "t_s") || ~isfield(data, "signal") || isempty(data.t_s) || isempty(data.signal)
    result.status = "WARNING_missing_required_channel";
    return
end

t = data.t_s(:);
y = data.signal(:, 1);
timeWindow_s = double(plan.TimeWindow_s);
idx = find(isfinite(t) & isfinite(y) & t >= timeWindow_s(1) & t <= timeWindow_s(2));
if isempty(idx)
    result.status = "WARNING_empty_time_window";
    return
end

tSelected = t(idx);
ySelected = y(idx);

result.t_s = tSelected;
result.(signalFieldName) = ySelected;
result.requestedTimeWindow_s = timeWindow_s;
result.firstIndex = idx(1);
result.lastIndex = idx(end);
result.actualTimeWindow_s = [tSelected(1), tSelected(end)];
result.samples = numel(ySelected);
result.mean_vol_pct = mean(ySelected, "omitnan");
result.std_vol_pct = std(ySelected, "omitnan");
result.min_vol_pct = min(ySelected, [], "omitnan");
result.max_vol_pct = max(ySelected, [], "omitnan");
result.status = "ok";
end

function result = localEmptyResult(plan, statusText, signalFieldName)
result = struct();
result.woiName = string(plan.WoIName);
result.stream = string(plan.Stream);
result.path = string(plan.Path);
result.requestedTimeWindow_s = double(plan.TimeWindow_s);
result.actualTimeWindow_s = [NaN, NaN];
result.firstIndex = NaN;
result.lastIndex = NaN;
result.samples = 0;
result.t_s = [];
result.(signalFieldName) = [];
result.mean_vol_pct = NaN;
result.std_vol_pct = NaN;
result.min_vol_pct = NaN;
result.max_vol_pct = NaN;
result.status = string(statusText);
end

function data = localGetNestedField(rootStruct, pathText)
pathParts = split(pathText, ".");
data = rootStruct;
for iPart = 1:numel(pathParts)
    fieldName = char(pathParts(iPart));
    if ~isfield(data, fieldName)
        data = struct();
        data.status = "WARNING_missing_required_channel";
        return
    end
    data = data.(fieldName);
end
end

function rootStruct = localSetNestedField(rootStruct, pathParts, value)
fieldName = matlab.lang.makeValidName(string(pathParts(1)));
if numel(pathParts) == 1
    rootStruct.(fieldName) = value;
    return
end

if ~isfield(rootStruct, fieldName) || ~isstruct(rootStruct.(fieldName))
    rootStruct.(fieldName) = struct();
end
rootStruct.(fieldName) = localSetNestedField( ...
    rootStruct.(fieldName), pathParts(2:end), value);
end

function localRequireStructFields(structArray, requiredFields, structName)
if isempty(structArray)
    error("AuxFcn_ExtractVH2DConcentrationWoI_001:MissingStructArray", ...
        "%s must not be empty.", structName);
end

availableFields = string(fieldnames(structArray));
missingFields = setdiff(requiredFields, availableFields);
if ~isempty(missingFields)
    error("AuxFcn_ExtractVH2DConcentrationWoI_001:MissingStructFields", ...
        "%s is missing required fields: %s", ...
        structName, strjoin(missingFields, ", "));
end
end
