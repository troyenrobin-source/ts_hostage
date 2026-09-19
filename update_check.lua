-- Controleert eenmaal bij iedere start. Downloadt of voert geen externe code uit.
local resource = GetCurrentResourceName()
local repository = 'https://github.com/troyscripts/ts_hostage'
-- Zonder ref gebruikt GitHub de standaardbranch (main of master).
local endpoint = 'https://api.github.com/repos/troyscripts/ts_hostage/contents/version.json'
local function log(message)
    print(TSL('update_check_troyscripts') .. message)
end
local function version(value)
    if type(value) ~= 'string' or #value > 40 then return end
    local major, minor, patch = value:match('^v?(%d+)%.(%d+)%.(%d+)$')
    if not major then return end
    return { tonumber(major), tonumber(minor), tonumber(patch) }
end
local function compare(a, b)
    for i = 1, 3 do
        if a[i] > b[i] then return 1 end
        if a[i] < b[i] then return -1 end
    end
    return 0
end
CreateThread(function()
    Wait(3000)
    local installed = GetResourceMetadata(resource, 'version', 0)
    local current = version(installed)
    if not current then
        log(TSL('update_check_updatecontrole_overgeslagen_gebruik_versie_in_fxmanifest_lua'))
        return
    end
    local completed = false
    SetTimeout(15000, function()
        if completed then return end
        completed = true
        log(TSL('update_check_updatecontrole_github_reageert_niet_op_tijd_het'))
    end)
    PerformHttpRequest(endpoint, function(status, body)
        if completed then return end
        completed = true
        if status ~= 200 then
            if status == 404 then
                log(TSL('update_check_updatecontrole_repository_of_version_json_niet_openbaar'))
            elseif status == 403 or status == 429 then
                log(TSL('update_check_updatecontrole_github_weigert_de_aanvraag_of_het') .. status .. ').')
            else
                log(TSL('update_check_updatecontrole_mislukt_http') .. tostring(status) .. TSL('update_check_het_script_blijft_werken'))
            end
            return
        end
        if type(body) ~= 'string' or #body > 16384 then
            log(TSL('update_check_updatecontrole_ongeldig_of_te_groot_antwoord_van'))
            return
        end
        local ok, data = pcall(json.decode, body)
        local latest = ok and type(data) == 'table' and version(data.version)
        if not latest then
            log(TSL('update_check_updatecontrole_version_json_moet_een_geldige_stabiele'))
            return
        end
        local result = compare(latest, current)
        if result > 0 then
            log(TSL('update_check_update_beschikbaar_voor_ts_hostage'))
            log((TSL('update_check_geinstalleerd_nieuwste')):format(installed, data.version))
            -- Alleen HTTPS-links naar deze repository in de console tonen.
            local link = data.download
            if type(link) ~= 'string' or #link > 500 or link:find('[%c%s%^]')
                or (link ~= repository and link:sub(1, #repository + 1) ~= repository .. '/') then
                link = repository
            end
            log(TSL('update_check_download') .. link)
        elseif result == 0 then
            log(TSL('update_check_ts_hostage') .. installed .. TSL('update_check_is_up_to_date'))
        else
            log(TSL('update_check_lokale_versie') .. installed .. TSL('update_check_is_nieuwer_dan_de_gepubliceerde_versie') .. data.version .. '.')
        end
    end, 'GET', '', {
        ['Accept'] = 'application/vnd.github.raw+json',
        ['User-Agent'] = 'TroyScripts-ts_hostage',
        ['X-GitHub-Api-Version'] = '2022-11-28'
    })
end)
