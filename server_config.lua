-- ALLEEN server-side geladen. Zet webhook-URL's nooit in config.lua/clientbestanden.
WebhookConfig = {
    Enabled = true,
    Start = '',   -- Discord-webhook: gijzeling gestart
    Actions = '', -- andere Discord-webhook: loslaten / omleggen / afgebroken
    Username = 'TroyScripts | Gijzelingen',
    AvatarUrl = '', -- optioneel: openbare https-link naar je logo
    Screenshots = true, -- vereist screenshot-basic; anders wordt alleen tekst verstuurd
    -- Timeout, afbeeldingslimiet en wachtrij staan nu in ts_bridge/server_config.lua.
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
