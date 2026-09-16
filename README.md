# TroyScripts — ts_hostage

**Versie 1.1.6** (vereist ts_bridge 0.0.1(BETA)) · FiveM · Gijzelingen te voet en in voertuigen

Met `ts_hostage` kunnen spelers een andere speler gijzelen, loslaten of omleggen.
De resource bevat een eigen handen-omhoog-functie, politiemeldingen met locatie
en een optioneel waypoint, plus Discord-logging met optionele screenshots.

De huidige mespositie is behouden. De hand sluit nog niet anatomisch correct
om het handvat; dit is een bekende beperking van deze versie.

## Nieuw: centrale bridge

Meldingen, ESX-jobcontrole, targetregistratie, webhooktransport en screenshots lopen
nu via ts_bridge. Lees **UPDATE-INSTALLATIE.md** voor de migratie en centrale instellingen.
De bestaande GitHub-updatecontrole blijft behouden.

## Vereisten

| Onderdeel | Gebruik |
| --- | --- |
| FiveM met OneSync | Synchronisatie van spelers en gijzelingen. |
| `ts_bridge` 0.0.1(BETA) | Centrale koppelingen; verplicht. |
| `ox_lib` | Meldingen via ts_bridge. |
| `es_extended` (ESX) | Politieagenten herkennen voor de politiemeldingen. |
| `ox_target` | Vereist bij `Config.Interaction = 'target'` of `'both'`. |
| `screenshot-basic` | Optioneel, voor foto's in Discord-logs. |

De basisfuncties zijn beschreven als frameworkonafhankelijk en hebben geen
SQL-installatie nodig. De beschreven politie-integratie gebruikt ESX en ox_lib.
Installeer deze voor de hieronder beschreven opzet; werking zonder deze resources
is bij deze herschrijving niet geverifieerd.

## Installatie

1. Plaats eerst `ts_bridge` zoals beschreven in UPDATE-INSTALLATIE.md. Plaats daarna de map `ts_hostage` in bijvoorbeeld `resources/[troyscripts]`.
2. Stel `config.lua` en `server_config.lua` in.
3. Voeg onderstaande regels toe aan `server.cfg`. Voeg bestaande startregels niet dubbel toe.

```cfg
ensure ox_lib
ensure es_extended

# Alleen nodig wanneer je ox_target gebruikt:
ensure ox_target

# Alleen nodig voor screenshots in Discord-logs:
ensure screenshot-basic

ensure ts_bridge
ensure ts_hostage
```

Controleer na het starten de console. Voor deze versie hoort de opstartmelding
versie **1.1.6** te vermelden.

## Bijwerken naar 1.1.6

1. Maak een backup van de bestaande resource, inclusief je configuratie.
2. Stop de resource met `stop ts_hostage`.
3. Vervang de bestanden door die van de nieuwe versie. Houd de mapnaam `ts_hostage` aan.
4. Neem je eigen instellingen over in de nieuwe configuratiebestanden.
5. Controleer of nieuwe configuratieblokken, waaronder `PoliceAlertConfig`, aanwezig zijn.
6. Start de resource met `ensure ts_hostage` en controleer de versiemelding.

Bewaar je webhook-URL's uit `server_config.lua`. Zet een oud configuratiebestand
niet blind terug als daardoor nieuwe instellingen ontbreken.

Een resource-stop beëindigt lopende gijzelingen. Voor deze versie is geen
databasemigratie beschreven.

## Bediening

| Actie | Standaardbediening |
| --- | --- |
| Handen omhoog of omlaag | **H** of `/handenomhoog` |
| Speler vastpakken | **E** of `ox_target` |
| Gijzelaar omleggen | **E** tijdens een actieve gijzeling, na minimaal 1,5 seconde |
| Gijzelaar loslaten | **X** |
| Waypoint naar de laatste politiemelding | **G**, standaard binnen 60 seconden |

Persoonlijke FiveM-keybindings kunnen afwijken van de standaardtoetsen.

### Te voet

- Het slachtoffer gebruikt de eigen handen-omhoog-functie van `ts_hostage`.
- De gijzelnemer houdt een toegestaan wapen vast.
- De spelers staan standaard maximaal 1,8 meter van elkaar.
- Tijdens de gijzeling kan de gijzelnemer wandelen.
- Het slachtoffer kan praten, maar niet zelfstandig bewegen of vechten.
- Bij het vastpakken wordt de eigen handen-omhoog-status opgeruimd.

### In een voertuig

- De gijzelnemer zit als bijrijder; het slachtoffer zit achter het stuur.
- Het voertuig staat bij het starten vrijwel stil.
- De gijzelnemer gebruikt first person. Terugschakelen beëindigt de gijzeling.
- Het slachtoffer kan blijven rijden, sturen en remmen.
- Handen omhoog zijn in het voertuig niet nodig.

Een slachtoffer van buiten het voertuig vastpakken of met een al vastgepakt
slachtoffer instappen is niet ingebouwd.

## Configuratie

De algemene instellingen staan in `config.lua`.

| Instelling | Betekenis |
| --- | --- |
| `Config.Interaction` | Interactie via `'target'`, `'key'` of `'both'`. |
| `Config.Keys` | Toetsen voor acties en loslaten. |
| `Config.HandsUp` | Eigen handen-omhoog-functie, toets en animatie. |
| `Config.Weapons` | Toegestane wapenspawnnamen en type: `firearm`, `blade` of `blunt`. |
| `Config.RequireAmmo` | Of een vuurwapen munitie moet hebben. |
| `Config.Distance` | Maximale afstand bij het starten. |
| `Config.BreakDistance` | Afstand waarbij de gijzeling wordt afgebroken. |
| `Config.Vehicle` | Voertuigfunctie, first person, startsnelheid en zitplaatsen. |
| `Config.Profiles` | Animaties en onderlinge posities van de spelers. |
| `Config.BladePose` | Visuele mespositie en handcorrectie. |

Voeg custom wapens expliciet toe aan `Config.Weapons`. Wapens die niet in de lijst
staan worden geweigerd. Lange wapens en custom modellen kunnen visueel afwijken.

## Politiemeldingen

Bij de start van een geldige gijzeling ontvangen online ESX-spelers met de
standaardjob `police` een ox_lib-melding. Er is volgens de beschreven werking
geen dienststatusfilter.

- De melding duurt standaard 10 seconden.
- Een geweigerde of afgebroken voorbereiding verstuurt geen melding.
- Loslaten of omleggen verstuurt geen aanvullende politiemelding.
- Er wordt geen kaartblip toegevoegd.

Pas jobs, tekst, duur en positie aan via `PoliceAlertConfig` in
`server_config.lua`. Zet `PoliceAlertConfig.Enabled = false` om de melding
uit te schakelen.

### Locatie en waypoint

De melding noemt de straat, eventuele kruisende straat en het gebied waar de
gijzeling begon. De server levert de coördinaten; de politieclient zet die om
naar kaartnamen. Als namen ontbreken, worden coördinaten getoond.

Druk standaard binnen **60 seconden op G** om een waypoint te plaatsen.
`PoliceAlertConfig.WaypointSeconds` bepaalt hoe lang dit mogelijk is.
Een nieuwe melding vervangt de vorige bestemming.

Het waypoint wijst naar de **startlocatie** en volgt geen bewegende speler.
Er wordt niet automatisch een route ingesteld. De toets kan via de
FiveM-toetsinstellingen worden aangepast; de melding noemt standaard G.

Bij bijwerken naar deze locatiefunctionaliteit moeten ook het bijgewerkte
`fxmanifest.lua` en `police_alert.lua` worden meegenomen.

## Discord-logging

Vul de webhook-URL's uitsluitend in `server_config.lua` in, bij de bestaande
velden `Start` en `Actions`:

```lua
Start = 'https://discord.com/api/webhooks/JOUW_ID/JOUW_TOKEN',
Actions = 'https://discord.com/api/webhooks/ANDER_ID/ANDER_TOKEN',
```

Dit zijn invulvoorbeelden, geen werkende webhooks. Plaats in de Lua-strings alleen
de URL, zonder Markdown-linkopmaak.

| Webhook | Gebeurtenissen |
| --- | --- |
| `Start` | Een gijzeling is actief gestart. |
| `Actions` | Loslaten, omleggen en eventueel automatisch afbreken. |

De embeds bevatten namen, server-ID's, wapen, actie, situatie, UTC-tijd en
sessienummer. Standaard worden FiveM-namen gebruikt. Pas
`WebhookConfig.PlayerName` aan als je RP-namen wilt gebruiken.

Webhook-URL's blijven server-side en mentions staan uit. Publiceer geen ingevulde
webhook-URL's op GitHub; gebruik lege waarden of placeholders in de openbare versie.

### Screenshots

Foto's worden via `screenshot-basic` opgevraagd vanuit het spelbeeld van de
gijzelnemer. De verwerking is asynchroon: de foto hoeft niet exact het
actiemoment te tonen. Zonder beschikbare foto wordt tekstlogging gebruikt.

Zet `Screenshots = false` voor uitsluitend tekstlogging. `AvatarUrl` is optioneel
voor een logo en staat los van de screenshot.

Eerder is `screenshot-basic: Failed to fetch` gemeld. In de beschikbare
documentatie is geen bevestigde oplossing vastgelegd. Controleer de werking
op je eigen server; deze fout bewijst op zichzelf niet dat de webhook-URL fout is.

De logqueue is begrensd en wordt niet blijvend opgeslagen. Bij een storing of
serverstop kunnen nog niet verstuurde logs verloren gaan.

## Dubbele H-toets bij Sky voorkomen

Laat Sky-hands-up uitgeschakeld als je dat al eerder hebt ingesteld.
Anders zet je in `sky_jobs_base/config/config.lua`, binnen `Config.PoliceCuffs`:

```lua
handsUp = {
    enabled = false,
    key = 'H',
    holdSeconds = 3
},
```

Controleer ook eventuele overrides in de Job Configurator. Herstart na deze
wijziging de server en laat spelers opnieuw verbinden om oude actieve
handen-omhoog-statussen te wissen.

Verwijder zo nodig een conflicterende oude Sky-H-keybinding. Onder de
FiveM-toetsinstellingen hoort H bij de handen-omhoog-functie van TroyScripts.

De eerder beschreven integratiepatch `integrations/sky_handsup_uit.patch` wordt
niet automatisch toegepast. Gebruik die alleen wanneer deze in je pakket
staat en overeenkomt met jouw Sky-configuratie.

Sky's overige functies blijven actief. Compatibiliteit van Sky-boeien en
fouilleren met de eigen handen-omhoog-status is niet bevestigd.

## Diagnose en integratie

| Command of uitvoer | Doel |
| --- | --- |
| `/ts_handcheck` | Eigen handen-omhoog-status, animatiewaarde en bezigstatus tonen in F8. |
| `/ts_hostagecheck` | Lokale voorwaarden, wapenhash, camera en dichtstbijzijnde speler controleren. |
| `[ts_mespositie] world-pose` | Diagnose-uitvoer over mesmodel, lengteas en geschat lemmetcontact. |

Beschreven clientexports:

```lua
exports.ts_hostage:IsBusy()
exports.ts_hostage:GetRole()
exports.ts_hostage:IsHandsUp()
exports.ts_hostage:LowerHands()
```

Het lokale clientevent `ts_hostage:busyChanged` geeft `busy` en `role` door.
Andere inventory-, emote- en teleportscripts moeten deze status zelf respecteren
als ze eigen interfaces of commands gebruiken. Controlblokkering kan niet alle
acties van andere resources verhinderen.

Handen omhoog en first person worden client-side gecontroleerd. De server
controleert onder meer afstand, wapen, deelnemers, gezondheid, routing bucket
en zitplaatsen. De gerepliceerde visuele status is geen anticheatbewijs.

## GitHub

Repository: [troyscripts/ts_hostage](https://github.com/troyscripts/ts_hostage).

Plaats de inhoud van de resource in de hoofdmap van de repository, zodat
`fxmanifest.lua` direct bovenaan staat. Hernoem een via GitHub uitgepakte
broncodemap zo nodig naar `ts_hostage` voordat je deze op de server plaatst.

### Updatecontrole

Vanaf versie **1.1.6** is een GitHub-updatecontrole toegevoegd. Bij het starten
controleert de resource of een nieuwere versie beschikbaar is. Wanneer dat zo is,
verschijnt een melding in de serverconsole met een GitHub-link om de update op te halen.

De repository is [troyscripts/ts_hostage](https://github.com/troyscripts/ts_hostage).
Controleer bij de overstap naar dit GitHub-account ook de repositoryverwijzing
in de updatecontrole van je geïnstalleerde script. Alleen een wijziging in deze
README past de controle-URL in de code niet aan.

De controle installeert de update niet automatisch. Maak een backup en volg
[Bijwerken naar 1.1.6](#bijwerken-naar-113) om een nieuwe versie handmatig te installeren.

## Changelog

### 1.1.6 — GitHub-updatecontrole

- GitHub-updatecontrole toegevoegd.
- Melding met GitHub-link wanneer een nieuwere versie beschikbaar is.
- Handleiding bijgewerkt naar versie 1.1.6 en repository `troyscripts/ts_hostage`.
- Bestaande functies en bekende beperkingen blijven beschreven zoals in 1.1.2.

### 1.1.2 — Locatie en waypoint

- Straat, eventuele kruisende straat en gebied toegevoegd aan de politiemelding.
- Coördinaten als terugval wanneer kaartnamen ontbreken.
- Met G een waypoint plaatsen naar de startlocatie van de laatste melding.
- Beschikbare tijd instelbaar via `PoliceAlertConfig.WaypointSeconds`.

### 1.1.1 — Politiemelding

- ox_lib-melding bij de start van een geldige gijzeling.
- ESX-politiejobs en meldingsinstellingen configureerbaar via `PoliceAlertConfig`.

## Bekende beperkingen

- De huidige mesgreep sluit niet anatomisch correct op het handvat aan.
  Er is geen passende custom mes-gijzelanimatie meegeleverd.
- De standaardpose en ped-hitboxes bieden geen gegarandeerde kogelbescherming.
- Omleggen zet de ped dood; schoteffecten en munitieverbruik zijn niet ingebouwd.
- De kill-log bevestigt de toegestane actie, niet de verdere afhandeling door
  een externe ambulance-resource.
- Custom kleding, peds en voertuiginterieurs kunnen clipping veroorzaken.
- De eerder gemelde screenshot-uploadfout en Sky-compatibiliteit vragen nog
  bevestiging op de huidige serverconfiguratie.

## Controle na installatie

Gijzelen te voet en in voertuigen is eerder door de gebruiker als werkend gemeld.
De eerdere documentatie vermeldt Lua-syntaxcontroles en tests met gesimuleerde
FiveM-functies voor versie 1.1.0. Die resultaten zijn geen volledige validatie
van versie 1.1.6, live animaties of daadwerkelijke Discord-bezorging.

Test na installatie of bijwerken:

- H aan/uit en weigering wanneer het slachtoffer de handen niet omhoog heeft.
- Vastpakken via E en, indien ingeschakeld, ox_target.
- Loslaten met X en herstel van bewegen en combat bij beide spelers.
- Omleggen en de afhandeling door je ambulance- of deathsysteem.
- Rijden tijdens een auto-gijzeling en afbreken bij terugschakelen naar third person.
- Beide Discord-webhooks, met en zonder screenshots.
- Politiemelding, locatietekst en G-waypoint met een politieagent online.
- Opruimen na disconnect en na het stoppen of herstarten van de resource.
- De versiemelding en GitHub-updatecontrole bij het starten van de resource.

## Referenties

- [screenshot-basic](https://github.com/citizenfx/screenshot-basic)
- [ox_target API](https://github.com/overextended/ox_target/blob/main/client/api.lua)
- [Discord-webhooks](https://docs.discord.com/developers/resources/webhook)
- [ox_lib-notificaties](https://overextended.dev/docs/ox_lib/Interface/Client/notify)
- [troy's Gamecommunity](https://discord.gg/nTzVy5uMWX)

---

Ontwikkeld door **TroyScripts**.
