FRAME_UI = {}

frame = CreateFrame("Frame", "BattlegroundHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
local SORT_DIRECTION = "ASC"  -- Global variable to toggle sorting direction
local CLASS_DIST_FACTION = UnitFactionGroup("player")
local CLASS_COLORS = {
    ["Warrior"] = { r = 0.78, g = 0.61, b = 0.43 }, -- Brown
    ["Paladin"] = { r = 0.96, g = 0.55, b = 0.73 }, -- Pink
    ["Hunter"] = { r = 0.67, g = 0.83, b = 0.45 }, -- Green
    ["Rogue"] = { r = 1.00, g = 0.96, b = 0.41 }, -- Yellow
    ["Priest"] = { r = 1.00, g = 1.00, b = 1.00 }, -- White
    ["Shaman"] = { r = 0.00, g = 0.44, b = 0.87 }, -- Blue
    ["Mage"] = { r = 0.41, g = 0.80, b = 0.94 }, -- Light Blue
    ["Warlock"] = { r = 0.58, g = 0.51, b = 0.79 }, -- Purple
    ["Druid"] = { r = 1.00, g = 0.49, b = 0.04 }, -- Orange
}

local CLASS_LIST = {
    "Warrior",
    "Paladin",
    "Hunter",
    "Rogue",
    "Priest",
    "Shaman",
    "Mage",
    "Warlock",
    "Druid",
}

local function CreateTextString(parent, font, point, relativeTo, relativePoint, xOff, yOff, text)
    local textString = parent:CreateFontString(nil, "OVERLAY", font)
    textString:SetPoint(point, relativeTo, relativePoint, xOff, yOff)
    textString:SetText(text)
    textString:Hide()  -- Initially hide the text
    return textString
end

local function CreateToggleDropdown(parent, name, items, point, relativeTo, relativePoint, xOffset, yOffset, width, displayName)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_SetText(dropdown, displayName)

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.isNotRadio = true
        info.keepShownOnClick = true
        for k, v in ipairs(items) do
            info.text = v
            info.checked = filter[name][v]
            info.func = function(self)
                filter[name][v] = not filter[name][v] -- Toggle the checked state
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    return dropdown
end

local function AddNumericInputFieldWithToggle(parent, name, label, point, relativeTo, xOffset, yOffset)
    -- Corrected: Removed the parent from the first argument
    local labelFrame = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelFrame:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", xOffset, yOffset)
    labelFrame:SetText(label)

    local inputField = CreateFrame("EditBox", parent:GetName() .. name .. "Input", parent, "InputBoxTemplate")
    inputField:SetSize(80, 20)  -- Adjusted size to make room for the toggle button
    inputField:SetPoint("LEFT", labelFrame, "RIGHT", 10, 0)
    inputField:SetAutoFocus(false)
    inputField:SetNumeric(true)
    inputField:SetScript("OnEnterPressed", function()
        inputField:ClearFocus()
        -- Store the numeric value along with its bound type (upper or lower)
        filter[name] = { value = tonumber(inputField:GetText()), boundType = inputField.boundType }
    end)

    -- Initialize the bound type to lower ("<") by default
    inputField.boundType = "<"

    -- Toggle Button
    local toggleButton = CreateFrame("Button", parent:GetName() .. name .. "ToggleButton", parent, "UIPanelButtonTemplate")
    toggleButton:SetSize(20, 20)  -- Small button next to the input field
    toggleButton:SetPoint("LEFT", inputField, "RIGHT", 5, 0)
    toggleButton:SetText("<")
    toggleButton:SetScript("OnClick", function()
        if inputField.boundType == "<" then
            inputField.boundType = ">"
            toggleButton:SetText(">")
        else
            inputField.boundType = "<"
            toggleButton:SetText("<")
        end
    end)
    return inputField, toggleButton
end

local function GenericSort(a, b, key, isNumeric)
    if not a or not b or not a[key] or not b[key] then
        return false
    end

    if isNumeric then
        -- For numeric values, higher numbers can be considered 'greater'
        if SORT_DIRECTION == "ASC" then
            return a[key] > b[key]
        else
            return a[key] < b[key]
        end
    else
        -- For non-numeric values, use standard Lua string comparison
        if SORT_DIRECTION == "ASC" then
            return tostring(a[key]) < tostring(b[key])
        else
            return tostring(a[key]) > tostring(b[key])
        end
    end
end

local function SortByOutCome(a, b)
    if not a or not b then
        return false
    end

    -- Convert outcomes to comparable values
    local outcomeValues = { Victory = 3, Defeat = 1, Abandoned = 2 }

    local aValue = outcomeValues[a.outcome] or 0
    local bValue = outcomeValues[b.outcome] or 0

    if SORT_DIRECTION == "ASC" then
        return aValue < bValue
    else
        return aValue > bValue
    end
end
local function CreateTableHeader(parent, width, height, text, anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
    local header = CreateFrame("Button", nil, parent)
    header:SetSize(width, height)
    header:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)

    header.text = header:CreateFontString(nil, "OVERLAY")
    header.text:SetFontObject("GameFontHighlight")
    header.text:SetPoint("CENTER", header, "CENTER", 0, 0)  -- Center text within the header
    header.text:SetText(text)

    header.arrow = header:CreateTexture(nil, "OVERLAY")
    header.arrow:SetSize(15, 15)
    header.arrow:SetPoint("RIGHT", -5, 0)
    header.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    header.arrow:Hide()

    -- Adjust hover effect to cover the entire header button
    header:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    local highlight = header:GetHighlightTexture()
    highlight:ClearAllPoints()
    highlight:SetSize(width + math.abs(xOffset), height)  -- Set the size of the highlight to match the header
    highlight:SetPoint("TOPLEFT", header, "TOPLEFT", 22 + xOffset, 0)  -- Align top left point

    return header
end
local function FormatTime(totalSeconds)
    local seconds = totalSeconds % 60
    local totalMinutes = math.floor(totalSeconds / 60)
    local minutes = totalMinutes % 60
    local totalHours = math.floor(totalMinutes / 60)
    local hours = totalHours % 24
    local days = math.floor(totalHours / 24)

    if days > 0 then
        return string.format("%dd:%02dh:%02dm:%02ds", days, hours, minutes, seconds)
    else
        return string.format("%02dh:%02dm", hours, minutes)
    end
end
local function OnFactionSelected(self, arg1, arg2, checked)
    CLASS_DIST_FACTION = self.value
    UIDropDownMenu_SetSelectedValue(battlegroundHistoryFrame.dropdown, CLASS_DIST_FACTION)
    FRAME_UI.UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)
    CloseDropDownMenus() -- Close the dropdown menu after selection
end
local function CreateFactionDropdown(baseFrame)
    local dropdown = CreateFrame("Frame", "FactionDropdown", baseFrame, "UIDropDownMenuTemplate")

    -- Adjust the position to the left and vertically centered to the bar chart
    local chartHeight = baseFrame.classBarChart:GetHeight()
    dropdown:SetPoint("TOPLEFT", baseFrame.classBarChart, "TOPLEFT", -125, -chartHeight / 2)

    local function InitializeDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = OnFactionSelected

        info.text = "Horde"
        info.value = "Horde"
        info.checked = (CLASS_DIST_FACTION == "Horde")
        UIDropDownMenu_AddButton(info, level)

        info.text = "Alliance"
        info.value = "Alliance"
        info.checked = (CLASS_DIST_FACTION == "Alliance")
        UIDropDownMenu_AddButton(info, level)
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(dropdown, 70)
    UIDropDownMenu_SetButtonWidth(dropdown, 80)
    UIDropDownMenu_SetSelectedValue(dropdown, CLASS_DIST_FACTION)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    baseFrame.dropdown = dropdown

end

local width = 150
local smallWidth = 70

local dateHeader = CreateTableHeader(frame, 120, 20, "Date", "TOPLEFT", frame, "TOPLEFT", 5, -30)
local nameHeader = CreateTableHeader(frame, 100, 20, "Zone", "LEFT", dateHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local killsHeader = CreateTableHeader(frame, 50, 20, "Kills", "LEFT", nameHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local hkHeader = CreateTableHeader(frame, 50, 20, "HKs", "LEFT", killsHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local deathsHeader = CreateTableHeader(frame, 50, 20, "Deaths", "LEFT", hkHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local damageHeader = CreateTableHeader(frame, 70, 20, "Damage", "LEFT", deathsHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local honorHeader = CreateTableHeader(frame, 60, 20, "Honour", "LEFT", damageHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local durationHeader = CreateTableHeader(frame, 80, 20, "Duration", "LEFT", honorHeader, "RIGHT", 5, 0)  -- Reduced width and spacing
local outcomeHeader = CreateTableHeader(frame, 80, 20, "Outcome", "LEFT", durationHeader, "RIGHT", 5, 0)  -- Reduced width and spacing


local function UpdateSortArrows(header)
    for _, h in pairs({ dateHeader, nameHeader, killsHeader, deathsHeader, damageHeader, hkHeader, honorHeader, durationHeader, outcomeHeader }) do
        h.arrow:Hide()
    end
    header.arrow:Show()
    if SORT_DIRECTION == "ASC" then
        header.arrow:SetTexCoord(0, 0.56, 0, 1)
    else
        header.arrow:SetTexCoord(0, 0.56, 1, 0)
    end
end

local function AddSortingFunctions(baseFrame)
    local function SortData(key, isNumeric)
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, function(a, b)
            return GenericSort(a, b, key, isNumeric)
        end)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end

    hkHeader:SetScript("OnClick", function()
        SortData("honorableKills", true)
        UpdateSortArrows(hkHeader)
    end)

    honorHeader:SetScript("OnClick", function()
        SortData("honorGained", true)
        UpdateSortArrows(honorHeader)
    end)

    dateHeader:SetScript("OnClick", function()
        SortData("date", false)
        UpdateSortArrows(dateHeader)
    end)

    nameHeader:SetScript("OnClick", function()
        SortData("name", false)
        UpdateSortArrows(nameHeader)
    end)

    killsHeader:SetScript("OnClick", function()
        SortData("killingBlows", true)
        UpdateSortArrows(killsHeader)
    end)

    deathsHeader:SetScript("OnClick", function()
        SortData("deaths", true)
        UpdateSortArrows(deathsHeader)
    end)

    damageHeader:SetScript("OnClick", function()
        SortData("damageDone", true)
        UpdateSortArrows(damageHeader)
    end)

    durationHeader:SetScript("OnClick", function()
        SortData("duration", true)
        UpdateSortArrows(durationHeader)
    end)

    outcomeHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByOutCome)
        UpdateSortArrows(outcomeHeader)
    end)
end

local function CalculateBattlegroundStatsAndTotals(baseList)
    local totalKills, totalDeaths, totalWins, totalHonorableKills, totalDuration, totalBattles, totalHonorGained = 0, 0, 0, 0, 0, 0, 0
    local classPercentages = { Horde = {}, Alliance = {} }

    for _, bg in ipairs(baseList) do
        if FILTER.IsAccepted(bg) then
            classPercentages[PVP_TRACKER.PLAYER_FACTION_STRING][bg.playerClass] = (classPercentages[PVP_TRACKER.PLAYER_FACTION_STRING][bg.playerClass] or 0) + 1
            for _, player in pairs(bg.teamComposition.Horde) do
                classPercentages.Horde[player.class] = (classPercentages.Horde[player.class] or 0) + 1
            end
            for _, player in pairs(bg.teamComposition.Alliance) do
                classPercentages.Alliance[player.class] = (classPercentages.Alliance[player.class] or 0) + 1
            end

            totalBattles = totalBattles + 1
            totalHonorGained = totalHonorGained + (bg.honorGained or 0)
            totalKills = totalKills + (bg.killingBlows or 0)
            totalDeaths = totalDeaths + (bg.deaths or 0)
            totalHonorableKills = totalHonorableKills + (bg.honorableKills or 0)
            totalDuration = totalDuration + (bg.duration or 0)

            if bg.outcome == "Victory" then
                totalWins = totalWins + 1
            end
        end
    end

    local totalPlayersPerFaction = totalBattles * 10
    for class, count in pairs(classPercentages.Horde) do
        classPercentages.Horde[class] = (count / totalPlayersPerFaction) * 100
    end

    -- Calculate class percentages for Alliance
    for class, count in pairs(classPercentages.Alliance) do
        classPercentages.Alliance[class] = (count / totalPlayersPerFaction) * 100
    end

    local avgKills = totalBattles > 0 and totalKills / totalBattles or 0
    local avgDeaths = totalBattles > 0 and totalDeaths / totalBattles or 0
    local avgHonorableKills = totalBattles > 0 and totalHonorableKills / totalBattles or 0
    local avgDuration = totalBattles > 0 and totalDuration / totalBattles or 0
    local winRate = totalBattles > 0 and (totalWins / totalBattles) * 100 or 0
    local avgHonor = totalHonorGained > 0 and totalHonorGained / totalBattles or 0

    return avgKills, avgDeaths, avgHonorableKills, avgDuration, winRate, totalKills, totalDeaths, totalHonorableKills, totalDuration, totalBattles, avgHonor, totalHonorGained, classPercentages
end

local function UpdateFactionBarChart(barChart, classPercentages)
    local totalClasses = 8
    local maxBarHeight = barChart:GetHeight() -- Maximum height of a bar
    local chartWidth = barChart:GetWidth() -- Total width of the bar chart
    local spacing = 5 -- Spacing between bars

    -- Calculate the width of each bar dynamically
    local barWidth = (chartWidth - (spacing * (totalClasses - 1))) / totalClasses
    local faction = CLASS_DIST_FACTION -- "Horde" or "Alliance"

    -- Clear existing bars if any
    for _, bar in ipairs(barChart.bars or {}) do
        bar:Hide()
    end
    barChart.bars = {}

    local barCount = 0 -- Counter for the actual number of bars created

    -- Create and position bars
    for _, class in ipairs(CLASS_LIST) do
        if not ((faction == "Alliance" and class == "Shaman") or (faction == "Horde" and class == "Paladin")) then
            local percentage = classPercentages[faction][class] or 0
            local barHeight = percentage * maxBarHeight / 100 -- Calculate height as a percentage

            local bar = barChart:CreateTexture(nil, "BACKGROUND")
            local classColor = CLASS_COLORS[class]
            if classColor then
                bar:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
            else
                bar:SetColorTexture(1, 1, 1, 1) -- Default color if class color is not found
            end

            bar:SetSize(barWidth, barHeight)

            -- Calculate horizontal position based on actual number of bars created
            local posX = (barCount * (barWidth + spacing)) - (chartWidth / 2) + (barWidth / 2)
            bar:SetPoint("BOTTOM", barChart, "BOTTOM", posX, 0)

            table.insert(barChart.bars, bar)

            barCount = barCount + 1 -- Increment barCount only when a bar is created
        end
    end
end

local function AddDiagramPlaceholders(baseFrame)
    -- Line Chart Placeholder
    baseFrame.lineChartPlaceholder = CreateFrame("Frame", nil, baseFrame)
    baseFrame.lineChartPlaceholder:SetSize(250, 150)  -- Adjusted size
    baseFrame.lineChartPlaceholder:SetPoint("TOPRIGHT", baseFrame, "TOPRIGHT", -30, -40)
    baseFrame.lineChartPlaceholder:Hide()  -- Initially hidden


    baseFrame.classBarChart = CreateFrame("Frame", nil, baseFrame)
    baseFrame.classBarChart:SetSize(250, 150)  -- Adjusted size
    baseFrame.classBarChart:SetPoint("TOPRIGHT", baseFrame.lineChartPlaceholder, "BOTTOMRIGHT", 0, -30)
    baseFrame.classBarChart:Hide()  -- Initially hidden

    baseFrame.classBarChartLabel = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame.classBarChart, "TOPLEFT", -25, 17, "Average class distribution:")

    local texture = baseFrame.lineChartPlaceholder:CreateTexture()
    texture:SetAllPoints(true)
    texture:SetColorTexture(0.3, 0.3, 0.3, 0.7)  -- Grey color

    local texture2 = baseFrame.classBarChart:CreateTexture()
    texture2:SetAllPoints(true)
    texture2:SetColorTexture(0.3, 0.3, 0.3, 0.7)  -- Grey color

end

local function AddStatisticsText(baseFrame)
    local indent = 20  -- Indentation for items within a category
    local categorySpacing = 30  -- Vertical space between categories

    -- Averages per Match Category
    baseFrame.categoryHeader = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame, "TOPLEFT", 20, -40, "Averages per Match:")
    baseFrame.averageKillingBlowsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.categoryHeader, "BOTTOMLEFT", indent, -10, "Average Killing Blows: ")
    baseFrame.averageHonorableKillsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageKillingBlowsText, "BOTTOMLEFT", 0, -10, "Average Honourable Kills: ")
    baseFrame.averageDeathsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageHonorableKillsText, "BOTTOMLEFT", 0, -10, "Average Deaths: ")
    baseFrame.averageDurationText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageDeathsText, "BOTTOMLEFT", 0, -10, "Average Duration: ")
    baseFrame.averageHonourText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageDurationText, "BOTTOMLEFT", 0, -10, "Average Honour: ")

    -- Totals Category
    baseFrame.totalsCategoryHeader = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame.averageHonourText, "BOTTOMLEFT", -20, -categorySpacing, "Totals:")
    baseFrame.winRateText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalsCategoryHeader, "BOTTOMLEFT", indent, -10, "Winrate: ")
    baseFrame.totalKillsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.winRateText, "BOTTOMLEFT", 0, -10, "Kills: ")
    baseFrame.totalDeathsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalKillsText, "BOTTOMLEFT", 0, -10, "Deaths: ")
    baseFrame.totalHonorableKillsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalDeathsText, "BOTTOMLEFT", 0, -10, "Honourable Kills: ")
    baseFrame.timeInsideText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalHonorableKillsText, "BOTTOMLEFT", 0, -10, "Time Inside: ")
    baseFrame.totalHonorGained = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.timeInsideText, "BOTTOMLEFT", 0, -10, "Honour: ")

    baseFrame.totalEntries = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame, "TOPLEFT", 250, -35, "Total Entries: ")
end

local function AddSecondTab(baseFrame)
    AddStatisticsText(baseFrame)
    AddDiagramPlaceholders(baseFrame)
    CreateFactionDropdown(baseFrame)
end

local function UpdateTabVisibility(selectedTab, bgFrame)
    local isHistoryTab = selectedTab == 1
    local isStatsTab = selectedTab == 2

    -- Show or hide headers based on the selected tab
    dateHeader:SetShown(isHistoryTab)
    nameHeader:SetShown(isHistoryTab)
    killsHeader:SetShown(isHistoryTab)
    deathsHeader:SetShown(isHistoryTab)
    damageHeader:SetShown(isHistoryTab)
    durationHeader:SetShown(isHistoryTab)
    outcomeHeader:SetShown(isHistoryTab)
    hkHeader:SetShown(isHistoryTab)
    honorHeader:SetShown(isHistoryTab)

    for i, row in ipairs(bgFrame.rows or {}) do
        row:SetShown(isHistoryTab)
    end

    bgFrame.categoryHeader:SetShown(isStatsTab)
    bgFrame.averageKillingBlowsText:SetShown(isStatsTab)
    bgFrame.averageHonorableKillsText:SetShown(isStatsTab)
    bgFrame.averageDeathsText:SetShown(isStatsTab)
    bgFrame.averageDurationText:SetShown(isStatsTab)
    bgFrame.averageHonourText:SetShown(isStatsTab)

    bgFrame.totalsCategoryHeader:SetShown(isStatsTab)
    bgFrame.winRateText:SetShown(isStatsTab)
    bgFrame.totalKillsText:SetShown(isStatsTab)
    bgFrame.totalDeathsText:SetShown(isStatsTab)
    bgFrame.totalHonorableKillsText:SetShown(isStatsTab)
    bgFrame.timeInsideText:SetShown(isStatsTab)
    bgFrame.totalHonorGained:SetShown(isStatsTab)
    bgFrame.totalEntries:SetShown(isStatsTab)

    bgFrame.lineChartPlaceholder:SetShown(isStatsTab)
    bgFrame.classBarChart:SetShown(isStatsTab)
    bgFrame.classBarChartLabel:SetShown(isStatsTab)
    bgFrame.dropdown:SetShown(isStatsTab)
end

local function AddResizeHandler(baseFrame)
    local resizeHandle = CreateFrame("Button", nil, baseFrame)
    resizeHandle:SetPoint("BOTTOMRIGHT", baseFrame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            baseFrame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeHandle:SetScript("OnMouseUp", function(self, button)
        baseFrame:StopMovingOrSizing()
    end)

    resizeHandle:SetScript("OnEnter", function(self)
        SetCursor("Interface\\CURSOR\\openhandglow")
    end)

    resizeHandle:SetScript("OnLeave", function(self)
        ResetCursor()
    end)

end

function FRAME_UI.UpdateBattlegroundHistoryFrame(battleGroundFrame)
    UpdateTabVisibility(battleGroundFrame.selectedTab, battleGroundFrame)
    local isHistoryTab = battleGroundFrame.selectedTab == 1
    local isStatsTab = battleGroundFrame.selectedTab == 2
    local isInfoTab = battleGroundFrame.selectedTab == 3

    if isHistoryTab then
        -- Clear existing rows
        for i, row in ipairs(battleGroundFrame.rows or {}) do
            row:Hide()
        end

        battleGroundFrame.rows = {}

        local rowHeight = 20
        local i = 1
        for _, bg in ipairs(PVP_HISTORY) do
            if FILTER.IsAccepted(bg) then
                local row = CreateFrame("Frame", nil, battleGroundFrame.scrollChild)
                row:SetSize(755, rowHeight)  -- Adjusted width to match the backdrop
                row:SetPoint("TOPLEFT", 10, -(i - 1) * rowHeight)
                battleGroundFrame.rows[i] = row

                -- Create text elements for each column in the row
                row.startTime = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.startTime:SetPoint("LEFT", 0, 0)
                row.startTime:SetSize(120, rowHeight)  -- Match header width

                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.name:SetPoint("LEFT", row.startTime, "RIGHT", 5, 0)
                row.name:SetSize(100, rowHeight)  -- Match header width

                row.kills = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.kills:SetPoint("LEFT", row.name, "RIGHT", 5, 0)
                row.kills:SetSize(50, rowHeight)  -- Match header width

                row.honorableKills = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.honorableKills:SetPoint("LEFT", row.kills, "RIGHT", 5, 0)
                row.honorableKills:SetSize(50, rowHeight)  -- Match header width

                row.deaths = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.deaths:SetPoint("LEFT", row.honorableKills, "RIGHT", 5, 0)
                row.deaths:SetSize(50, rowHeight)  -- Match header width

                row.damageDone = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.damageDone:SetPoint("LEFT", row.deaths, "RIGHT", 5, 0)
                row.damageDone:SetSize(70, rowHeight)  -- Match header width

                row.honorGained = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.honorGained:SetPoint("LEFT", row.damageDone, "RIGHT", 5, 0)
                row.honorGained:SetSize(60, rowHeight)  -- Match header width

                row.duration = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.duration:SetPoint("LEFT", row.honorGained, "RIGHT", 5, 0)
                row.duration:SetSize(80, rowHeight)  -- Match header width

                row.outcome = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.outcome:SetPoint("LEFT", row.duration, "RIGHT", 5, 0)
                row.outcome:SetSize(80, rowHeight)  -- Match header width

                -- Set text for each column
                row.startTime:SetText(bg.date)
                row.name:SetText(bg.name)
                row.kills:SetText(bg.killingBlows)
                row.deaths:SetText(bg.deaths)
                row.duration:SetText(bg.durationText)
                row.outcome:SetText(bg.outcome)
                row.honorableKills:SetText(bg.honorableKills or "")
                row.honorGained:SetText(bg.honorGained or "")
                row.damageDone:SetText(bg.damageDone or 0)

                -- Color coding for outcome
                if bg.outcome == "Victory" then
                    row.outcome:SetTextColor(0, 1, 0)  -- Green for victory
                elseif bg.outcome == "Defeat" then
                    row.outcome:SetTextColor(1, 0, 0)  -- Red for defeat
                else
                    row.outcome:SetTextColor(1, 1, 1)  -- Default color
                end

                row:Show()
                i = i + 1
            end
        end
    elseif isStatsTab then
        local avgKills, avgDeaths, avgHonorableKills, avgDuration, winRate, totalKills, totalDeaths, totalHonorableKills, totalTimeInside, totalEntries, avgHonour, totalHonour, classPercentages = CalculateBattlegroundStatsAndTotals(PVP_HISTORY)

        UpdateFactionBarChart(battleGroundFrame.classBarChart, classPercentages)
        -- Format duration as minutes:seconds
        local avgDurationFormatted = string.format("%d:%02d", math.floor(avgDuration / 60), avgDuration % 60)
        battleGroundFrame.totalEntries:SetText("Total Entries: " .. totalEntries)

        battleGroundFrame.averageKillingBlowsText:SetText("Killing Blows: " .. string.format("%.2f", avgKills))
        battleGroundFrame.averageHonorableKillsText:SetText("Honourable Kills: " .. string.format("%.2f", avgHonorableKills))
        battleGroundFrame.averageDeathsText:SetText("Deaths: " .. string.format("%.2f", avgDeaths))
        battleGroundFrame.averageDurationText:SetText("Duration: " .. avgDurationFormatted)
        battleGroundFrame.averageHonourText:SetText("Honour: " .. avgHonour)

        battleGroundFrame.winRateText:SetText("Winrate: " .. string.format("%.2f%%", winRate))
        battleGroundFrame.totalKillsText:SetText("Kills: " .. totalKills)
        battleGroundFrame.totalDeathsText:SetText("Deaths: " .. totalDeaths)
        battleGroundFrame.totalHonorableKillsText:SetText("Honourable Kills: " .. totalHonorableKills)
        battleGroundFrame.timeInsideText:SetText("Time Inside: " .. FormatTime(totalTimeInside))  -- FormatTime should convert seconds to a readable format
        battleGroundFrame.totalHonorGained:SetText("Honour: " .. totalHonour)  -- FormatTime should convert seconds to a readable format
    end
end

local function AddFilterUIElements(filterFrame)
    -- Player Name Dropdown
    filterFrame.playerDropDown = CreateToggleDropdown(filterFrame, "charNames", playerNameItems, "TOPLEFT", filterFrame, "TOPLEFT", 0, -10, 115, "Characters")

    filterFrame.outcomeDropdown = CreateToggleDropdown(filterFrame, "outcomes", outcomeItems, "LEFT", filterFrame.playerDropDown, "RIGHT", -25, 0, 115, "Outcome")

    filterFrame.zoneNameDropdown = CreateToggleDropdown(filterFrame, "zoneNames", zoneNameItems, "TOPLEFT", filterFrame.playerDropDown, "BOTTOMLEFT", 0, 0, 250, "Battlegrounds")

    local yOffset = -10

    local inputs = { "killingBlows", "deaths", "honorableKills", "honorGained", "currentRank", "duration" }
    local labels = { "Kills:", "Deaths:", "Honorable Kills:", "Honor Gained:", "Current Rank:", "Duration:" }
    local xoffsets = { 70, 58, 15, 23, 26, 49 }

    for i, name in ipairs(inputs) do
        local input, toggle = AddNumericInputFieldWithToggle(filterFrame, name, labels[i], "TOPLEFT", filterFrame.zoneNameDropdown, xoffsets[i], yOffset)
        filterFrame[name .. "Input"], filterFrame[name .. "ToggleButton"] = input, toggle
        yOffset = yOffset - 25
    end
end

local function AddFilterPanel(baseFrame)
    local sidePanel = CreateFrame("Frame", "$parentSidePanel", baseFrame, "BackdropTemplate")
    sidePanel:SetSize(300, 260)
    sidePanel:SetPoint("TOPLEFT", baseFrame, "TOPLEFT", -sidePanel:GetWidth(), 0)
    sidePanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    sidePanel.collapsed = false -- Track whether the panel is collapsed

    local filterButton = CreateFrame("Button", "$parentFilterButton", sidePanel, "UIPanelButtonTemplate")
    filterButton:SetSize(80, 22)
    filterButton:SetPoint("BOTTOM", sidePanel, "BOTTOM", -48, 10)
    filterButton:SetText("Filter")

    filterButton:SetScript("OnClick", function()
        FILTER.SetValue(sidePanel)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    local clearButton = CreateFrame("Button", "$parentFilterButton", sidePanel, "UIPanelButtonTemplate")
    clearButton:SetSize(80, 22)
    clearButton:SetPoint("BOTTOM", filterButton, "BOTTOM", 93, 0)
    clearButton:SetText("Clear")

    clearButton:SetScript("OnClick", function()
        FILTER.Clear(sidePanel)
    end)

    local function ShowButtonTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if sidePanel.collapsed then
            GameTooltip:SetText("Expand filters")
        else
            GameTooltip:SetText("Collapse filters")
        end
        GameTooltip:Show()
    end

    local function HideButtonTooltip(self)
        GameTooltip:Hide()
    end

    local toggleButton = CreateFrame("Button", "$parentToggleButton", baseFrame, "UIPanelButtonTemplate")
    toggleButton:SetSize(25, 25)
    toggleButton:SetPoint("TOPLEFT", baseFrame, "TOPLEFT", -toggleButton:GetWidth(), 0)
    toggleButton:SetText(">")

    toggleButton:SetScript("OnClick", function()
        if sidePanel.collapsed then
            -- Expand the panel
            sidePanel:Show()
            sidePanel:SetPoint("TOPLEFT", baseFrame, "TOPLEFT", -sidePanel:GetWidth(), 0)
            sidePanel.collapsed = false
            toggleButton:SetText(">")
            toggleButton:SetSize(25, 25)
            toggleButton:ClearAllPoints()
            toggleButton:SetPoint("TOPRIGHT", sidePanel, "TOPLEFT", 5, 0)
        else
            -- Collapse the panel
            sidePanel:Hide()
            sidePanel.collapsed = true
            toggleButton:SetText("<")
            toggleButton:SetSize(25, 25)
            toggleButton:ClearAllPoints()
            toggleButton:SetPoint("TOPLEFT", baseFrame, "TOPLEFT", -toggleButton:GetWidth(), 0)
        end
    end)
    toggleButton:SetScript("OnEnter", ShowButtonTooltip)
    toggleButton:SetScript("OnLeave", HideButtonTooltip)

    AddFilterUIElements(sidePanel)

    sidePanel:Hide()
    sidePanel.collapsed = true
    toggleButton:SetText("<")
    toggleButton:SetPoint("TOPLEFT", baseFrame, "TOPLEFT", -toggleButton:GetWidth(), 0)

    baseFrame.filterPanel = sidePanel
end

function FRAME_UI.CreateBattlegroundHistoryFrame(baseFrame)
    playerNameItems = AccumulateUniquePlayerNames()
    filter["charNames"][UnitName("player")] = true
    for _, v in ipairs(outcomeItems) do
        filter["outcomes"][v] = true
    end
    for _, v in ipairs(zoneNameItems) do
        filter["zoneNames"][v] = true
    end

    baseFrame:SetSize(755, 400)  -- Width, Height
    baseFrame:SetPoint("CENTER")  -- Position on the screen
    baseFrame:SetResizable(true)  -- Enable resizing
    baseFrame:SetResizeBounds(755, 400, 755, 800) -- Minimum Resize Bounds

    baseFrame.title = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.title:SetFontObject("GameFontHighlight")
    baseFrame.title:SetPoint("LEFT", baseFrame.TitleBg, "LEFT", 5, 0)
    baseFrame.title:SetText("Battleground History")

    -- Create a resize handle
    AddResizeHandler(baseFrame)

    -- Add sorting functionality to headers here
    AddSortingFunctions(baseFrame)

    baseFrame.scrollFrame = CreateFrame("ScrollFrame", nil, baseFrame, "UIPanelScrollFrameTemplate")
    baseFrame.scrollFrame:SetPoint("TOPLEFT", 10, -60)
    baseFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    baseFrame.scrollChild = CreateFrame("Frame", nil, baseFrame.scrollFrame)
    baseFrame.scrollChild:SetSize(470, 340)  -- Scroll child size
    baseFrame.scrollFrame:SetScrollChild(baseFrame.scrollChild)

    baseFrame:SetMovable(true)
    baseFrame:EnableMouse(true)
    baseFrame:RegisterForDrag("LeftButton")
    baseFrame:SetScript("OnDragStart", baseFrame.StartMoving)
    baseFrame:SetScript("OnDragStop", baseFrame.StopMovingOrSizing)

    AddSecondTab(baseFrame)
    AddFilterPanel(baseFrame)
    -- Create Tabs
    local tab1 = CreateFrame("Button", "$parentTab1", baseFrame, "CharacterFrameTabButtonTemplate")
    tab1:SetPoint("BOTTOMLEFT", baseFrame, "BOTTOMLEFT", 5, -27)
    tab1:SetText("History")
    tab1:SetID(1)

    local tab2 = CreateFrame("Button", "$parentTab2", baseFrame, "CharacterFrameTabButtonTemplate")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -14, 0)
    tab2:SetText("Stats")
    tab2:SetID(2)

    local tab3 = CreateFrame("Button", "$parentTab3", baseFrame, "CharacterFrameTabButtonTemplate")
    tab3:SetPoint("LEFT", tab2, "RIGHT", -14, 0)
    tab3:SetText("Info")
    tab3:SetID(3)

    -- Tab Scripts
    tab1:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 1)
        baseFrame.selectedTab = 1
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)
    tab2:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 2)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
        baseFrame.selectedTab = 2
    end)
    tab3:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 3)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
        baseFrame.selectedTab = 3
    end)
    baseFrame.selectedTab = 1

    -- Initialize Tabs
    PanelTemplates_SetNumTabs(baseFrame, 3)
    PanelTemplates_SetTab(baseFrame, 1)
    UpdateTabVisibility(1, baseFrame)

    tinsert(UISpecialFrames, baseFrame:GetName())
    baseFrame:Hide()  -- Hide the frame initially

    return baseFrame
end
