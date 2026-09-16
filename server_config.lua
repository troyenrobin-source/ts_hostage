-- ALLEEN server-side geladen. Zet webhook-URL's nooit in config.lua/clientbestanden.
WebhookConfig = {
    Enabled = true,
    Start = '',   -- Discord-webhook: gijzeling gestart
    Actions = '', -- andere Discord-webhook: loslaten / omleggen / afgebroken
    Username = 'TroyScripts | Gijzelingen',
    AvatarUrl = '', -- optioneel: openbare https-link naar je logo
    Screenshots = true, -- vereist screenshot-basic; anders wordt alleen tekst verstuurd
    ScreenshotTimeoutMs = 8000,
    MaxImageBytes = 4 * 1024 * 1024,
    MaxQueue = 32,
    LogAutomaticRelease = true,
    -- Platformnaam + server-ID worden standaard gelogd.
    -- Voor een RP-naam: vul hier je eigen server-side frameworkkoppeling in.
    PlayerName = function(playerId)
        return GetPlayerName(playerId) or ('Speler ' .. tostring(playerId))
    end
}

-- Politie ontvangt één ox_lib-melding per daadwerkelijk gestarte gijzeling.
-- Jobcontrole gebeurt op de server via ESX; geen dienststatusfilter.
PoliceAlertConfig = {
    Enabled = true,
    Jobs = { police = true },
    Title = 'Politiemelding',
    Description = 'Er is een gijzeling gaande! Een persoon wordt gegijzeld.',
    Duration = 10000,
    WaypointSeconds = 60, -- tijd om met G een route naar de laatste melding te zetten
    Position = 'top-right'
}
