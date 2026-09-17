# Changelog — ts_hostage

## 1.1.7 — Bridgecontrole en aanpasbare locales
- Verplicht ts_bridge 0.0.2(BETA) / API 1; controle op client en server.
- Ontbrekende functies of oudere bridge blokkeren gameplay met een duidelijke melding.
- Bij bridge-stop: lokale opruiming en stoppen van de afhankelijke resource.
- Eigen locales-map, Nederlands standaard en fallback.
- Manifest, config-opmerkingen, installatiehandleiding en versiegegevens bijgewerkt.

## 1.1.6 — ts_bridge-integratie

- Verplichte dependency op ts_bridge 0.0.1(BETA).
- Meldingen, doodstatus, ESX-jobcontrole, targetkoppeling en waypoint naar de bridge.
- Discord-transport, screenshotafhandeling en limieten centraal in ts_bridge.
- Bestaande server-side webhook-URL's en PoliceAlertConfig blijven bruikbaar.
- Gijzelingslogica, animaties, H/E/X en bestaande updatecontrole behouden.
- Handleiding, manifest en version.json bijgewerkt; integratietests aangepast.
- Niet live getest op een FiveM-server.

## 1.1.5 — Versie-update en openbare GitHub-repository
- Versie in fxmanifest.lua en version.json verhoogd naar 1.1.5.
- Repository is openbaar bereikbaar; standaardbranch main bevestigd.
- Updatepakket bevat de updatecontrole uit 1.1.4, zodat installeren over 1.1.3 mogelijk is.
- version.json moet bij publicatie in de hoofdmap op GitHub worden geplaatst.

## 1.1.4 — GitHub-updatecontrole
- Controleert bij iedere resourcestart de publieke version.json op GitHub.
- Vergelijkt versienummers numeriek en toont status of downloadlink in de console.
- Netwerkfouten, ontbrekende bestanden en ongeldige versies stoppen het script niet.
- Opstartbericht leest de versie uit fxmanifest.lua.

## 1.1.3 — Politiemelding herstellen
- ox_lib expliciet geïnitialiseerd; client gebruikt direct lib.notify.
- Oud configuratiebestand zonder politieblok krijgt veilige police-standaardwaarden.
- ESX-job via getJob of job; fout bij één speler blokkeert andere agenten niet.
- Serverlog met aantal ontvangers en jobdiagnose bij nul ontvangers.
- Consolecommando ts_hostage_policecheck <speler-ID>; ontvangstlog in F8.
- Locatietekst en G-waypoint blijven aanwezig.

# Changelog — TroyScripts ts_hostage

## 1.1.2
- Druk op G voor een waypoint naar de laatste gemelde locatie (standaard 60 seconden beschikbaar).
- Locatie bij start toegevoegd aan de politiemelding: straat, kruising en gebied.
- Coördinaten komen van de server; fallback naar coördinaten bij ontbrekende kaartnamen.

## 1.1.1
- Ox_lib-politiemelding bij een daadwerkelijk gestarte gijzeling.
- Ontvangers worden server-side gecontroleerd op ESX-job (standaard police).
- Tekst, duur, positie en jobs instelbaar in server_config.lua.
- Ox_lib als dependency toegevoegd; ESX vereist voor de politiemelding.

## 1.1.0

Release van de huidige werkversie op verzoek van de eigenaar. Geen wijziging
van de gameplay of de huidige meshouding in deze versieverhoging.

### Beschikbaar in deze release

- Gijzelen via ox_target, toetsbediening of beide.
- Eigen H-handen-omhoog-toggle en /handenomhoog met cleanup bij vastpakken.
- Lopen met gijzelaar, E omleggen en X loslaten.
- Auto-gijzeling vanuit bijrijdersstoel in first person; slachtoffer kan rijden.
- Wapen-allowlist en afzonderlijke profielen voor vuur-, steek- en slagwapens.
- Twee Discord-webhooks met optionele screenshots en tekstfallback.
- Servervalidaties, sessietime-outs en opruiming bij afbreken/disconnect.
- Gerichte diagnosecommands en normalisatie van wapenhashes en native true/1-uitkomsten.

### Releaseonderhoud

- Manifest en opstartmelding gewijzigd naar 1.1.0.
- README herschreven tot één actuele installatie-, update- en gebruikshandleiding.
- Verouderde instructies uit de losse mesafstellingen vervangen door actuele configuratieuitleg.
- Releasebestand heet ts_hostage-1.1.0.zip.

### Open punten

- Meshouding behouden op verzoek; hand/handvat-uitlijning is niet correct opgelost.
- screenshot-basic 'Failed to fetch' nog niet onderzocht/opgelost.
- Sky boeien/fouilleren met eigen hands-up niet bevestigd.
- Geen schoteffect of munitieverbruik bij executie.

### Validatie

Lua-syntax en meegeleverde tests met gesimuleerde natives uitgevoerd. Gebruik van
gijzelen te voet en in een auto is eerder door de gebruiker bevestigd. Voor deze
release is geen nieuwe live FiveM- of Discord-test uitgevoerd.
