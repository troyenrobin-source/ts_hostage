-- Controleert eenmaal bij iedere start. Downloadt of voert geen externe code uit.
local resource = GetCurrentResourceName()
local repository = 'https://github.com/troyenrobin-source/ts_hostage'
-- Zonder ref gebruikt GitHub de standaardbranch (main of master).
local endpoint = 'https://api.github.com/repos/troyenrobin-source/ts_hostage/contents/version.json'
local function log(message)
    print('^5[TroyScripts]^7 ' .. message)
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
        log('Updatecontrole overgeslagen: gebruik versie X.Y.Z in fxmanifest.lua.')
        return
    end
    local completed = false
    SetTimeout(15000, function()
        if completed then return end
        completed = true
        log('Updatecontrole: GitHub reageert niet op tijd. Het script blijft werken.')
    end)
    PerformHttpRequest(endpoint, function(status, body)
        if completed then return end
        completed = true
        if status ~= 200 then
            if status == 404 then
                log('Updatecontrole: repository of version.json niet openbaar gevonden (404).')
            elseif status == 403 or status == 429 then
                log('Updatecontrole: GitHub weigert de aanvraag of het aanvraaglimiet is bereikt (HTTP ' .. status .. ').')
            else
                log('Updatecontrole mislukt (HTTP ' .. tostring(status) .. '). Het script blijft werken.')
            end
            return
        end
        if type(body) ~= 'string' or #body > 16384 then
            log('Updatecontrole: ongeldig of te groot antwoord van GitHub.')
            return
        end
        local ok, data = pcall(json.decode, body)
        local latest = ok and type(data) == 'table' and version(data.version)
        if not latest then
            log('Updatecontrole: version.json moet een geldige stabiele versie X.Y.Z bevatten.')
            return
        end
        local result = compare(latest, current)
        if result > 0 then
            log('Update beschikbaar voor ts_hostage!')
            log(('Geinstalleerd: %s | Nieuwste: %s'):format(installed, data.version))
            -- Alleen HTTPS-links naar deze repository in de console tonen.
            local link = data.download
            if type(link) ~= 'string' or #link > 500 or link:find('[%c%s%^]')
                or (link ~= repository and link:sub(1, #repository + 1) ~= repository .. '/') then
                link = repository
            end
            log('Download: ' .. link)
        elseif result == 0 then
            log('ts_hostage ' .. installed .. ' is up-to-date.')
        else
            log('Lokale versie ' .. installed .. ' is nieuwer dan de gepubliceerde versie ' .. data.version .. '.')
        end
    end, 'GET', '', {
        ['Accept'] = 'application/vnd.github.raw+json',
        ['User-Agent'] = 'TroyScripts-ts_hostage',
        ['X-GitHub-Api-Version'] = '2022-11-28'
    })
end)
