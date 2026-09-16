# ts_hostage 1.1.5 installeren

Deze ZIP bevat alleen nieuwe/gewijzigde bestanden voor de werkende versie 1.1.3 of 1.1.4.
Kopieer de inhoud van ts_hostage over je bestaande resource. Behoud de overige
bestanden, inclusief config.lua, server_config.lua en police_alert.lua.
Herstart met `restart ts_hostage`. De controle begint na ongeveer 3 seconden.
Er worden geen updates automatisch geïnstalleerd.

## Eenmalig op GitHub

1. Controleer dat https://github.com/troyenrobin-source/ts_hostage openbaar bereikbaar is.
2. Plaats version.json in de hoofdmap van de repository op de standaardbranch,
   dus direct zichtbaar wanneer je de repository opent (niet in een submap).
3. Upload ook de gewijzigde scriptbestanden op hun bestaande plek.
4. Herstart ts_hostage en controleer de serverconsole.

Er is geen token nodig. Een privé-repository of ontbrekend version.json geeft 404.
De checker werkt ook als de standaardbranch master heet in plaats van main.

## Volgende update publiceren

Verhoog de versie in fxmanifest.lua en version.json tegelijk, bijvoorbeeld naar
1.1.6. Werk CHANGELOG.md bij en publiceer de bijbehorende bestanden samen.
De downloadlink in version.json mag ook naar een release van deze repository wijzen.
Gebruik voor version.json alleen stabiele X.Y.Z-versies; geen beta-suffix.
Bestaande installaties met deze checker melden de update bij de volgende start.
De versiechecker zelf hoeft bij volgende updates niet te worden aangepast.

## Controle

De checker is lokaal getest met gesimuleerde HTTP-antwoorden. De repository is
nu openbaar bereikbaar en gebruikt main. Op GitHub stond tijdens controle nog
1.1.3; version.json gaf 404. Upload daarom alle bestanden uit dit pakket.
Het pakket past server.lua en fxmanifest.lua aan op basis van de opgehaalde
GitHub-bestanden. Live updatecontrole is pas mogelijk na upload van version.json.

Technische documentatie:
- https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/PerformHttpRequest/
- https://docs.github.com/en/rest/repos/contents#get-repository-content
