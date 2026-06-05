function rawOverviewTable = AuxFcn_BuildVH2DRawOverviewTable_001(campaign, metadata)
% AuxFcn_BuildVH2DRawOverviewTable_001
% Combine loaded raw-data overview tables with campaign metadata tables.

arguments
    campaign (1,1) struct
    metadata (1,1) struct
end

rawOverviewTable = localLoadedOverviewTable(campaign);

if isfield(metadata, "experimentPlanTable") && ~isempty(metadata.experimentPlanTable)
    planVars = {'RunId','Done','IsPreparation','PlannedDate','TargetH2_vol_pct', ...
        'Ignition','Vent','RecircStopToIgnition_s','MFCFlow_slpm','Notes'};
    planTbl = metadata.experimentPlanTable(:, intersect(planVars, ...
        metadata.experimentPlanTable.Properties.VariableNames, 'stable'));
    rawOverviewTable = outerjoin(rawOverviewTable, planTbl, ...
        'Keys', 'RunId', ...
        'MergeKeys', true, ...
        'Type', 'left', ...
        'RightVariables', setdiff(planTbl.Properties.VariableNames, 'RunId', 'stable'));
end

if isfield(metadata, "gasMixingTable") && ~isempty(metadata.gasMixingTable)
    gasVars = {'RunId','TargetH2_vol_pct','H2MassInjected_g', ...
        'H2VolumeStd_L','InjectionTime_s','InjectionTime_min', ...
        'PChamber_Pa','TChamber_K'};
    gasTbl = metadata.gasMixingTable(:, intersect(gasVars, ...
        metadata.gasMixingTable.Properties.VariableNames, 'stable'));
    gasTbl.Properties.VariableNames = localPrefixNonKeyVariables( ...
        gasTbl.Properties.VariableNames, "Gas_");
    rawOverviewTable = outerjoin(rawOverviewTable, gasTbl, ...
        'Keys', 'RunId', ...
        'MergeKeys', true, ...
        'Type', 'left', ...
        'RightVariables', setdiff(gasTbl.Properties.VariableNames, 'RunId', 'stable'));
end

end

function overviewTable = localLoadedOverviewTable(campaign)
groupFields = fieldnames(campaign.groups);
overviewTable = table();

for iGroup = 1:numel(groupFields)
    groupField = string(groupFields{iGroup});
    groupData = campaign.groups.(groupFields{iGroup});
    thisOverview = groupData.overview;
    nRows = height(thisOverview);

    CampaignId = repmat(string(campaign.id), nRows, 1);
    GroupField = repmat(groupField, nRows, 1);
    GroupId = repmat(string(groupData.id), nRows, 1);

    thisOverview = addvars(thisOverview, CampaignId, GroupField, GroupId, ...
        'Before', 1);
    overviewTable = [overviewTable; thisOverview]; %#ok<AGROW>
end
end

function variableNames = localPrefixNonKeyVariables(variableNames, prefix)
variableNames = string(variableNames);
for i = 1:numel(variableNames)
    if variableNames(i) ~= "RunId"
        variableNames(i) = prefix + variableNames(i);
    end
end
variableNames = cellstr(variableNames);
end
