# TroyScripts — ts_hostage 1.1.3

FiveM-resource voor gijzelen te voet en als bijrijder in een auto. Versie 1.1.3
behoudt de huidige functies en mesweergave. De mesgreep is nog niet anatomisch
correct; dit is een bekende beperking die voor deze release is geaccepteerd.

## Vereisten

- FiveM-server met OneSync.
- ox_lib voor de politiemeldingen.
- es_extended (ESX) voor het bepalen van de politiejob.
- ox_target bij Config.Interaction = 'target' of 'both'.
- screenshot-basic voor foto's in Discord-logs; zonder deze resource werkt tekstlogging.
- Geen ESX/QBCore- of SQL-afhankelijkheid voor de basisfuncties.

## Installeren

1. Plaats de volledige map `ts_hostage` in bijvoorbeeld `resources/[troyscripts]`.
2. Stel `config.lua` en `server_config.lua` in.
3. Voeg aan server.cfg toe, na eventuele dependencies:

```cfg
ensure ox_lib
ensure es_extended
# Alleen als je target gebruikt:
ensure ox_target
# Alleen als je foto's wilt en screenshot-basic geïnstalleerd is:
ensure screenshot-basic
ensure ts_hostage
```

De opstartconsole meldt `TroyScripts ts_hostage 1.1.3 gestart`.

## Updaten vanaf de werkversie

1. Bewaar je ingevulde `server_config.lua` en eventuele eigen wijzigingen in `config.lua`.
2. Voer `stop ts_hostage` uit in de serverconsole.
3. Vervang de map door de map uit `ts_hostage-1.1.3.zip`.
4. Zet je `server_config.lua` terug. Neem eigen wapens/toetsen/afstanden over in de nieuwe config.
5. Voer `ensure ts_hostage` uit en controleer de versiemelding.

Een resource-stop beëindigt lopende gijzelingen. Er is geen databasemigratie nodig.
Deze ZIP wordt lokaal geïnstalleerd; er is vanuit dit gesprek niets op je server gedeployed.

## Bediening

| Actie | Standaard |
| --- | --- |
| Eigen handen omhoog/omlaag | H of `/handenomhoog` |
| Vastpakken | E of ox_target |
| Gijzelaar omleggen | E tijdens actieve gijzeling, na minimaal 1,5 seconde |
| Gijzelaar loslaten | X |

Te voet moet het slachtoffer de eigen handen-omhoog-functie gebruiken. De dader
moet een toegestaan wapen vasthouden en binnen standaard 1,8 meter staan. Tijdens
de gijzeling kan de dader wandelen. Het slachtoffer kan praten, maar niet bewegen
of vechten. Bij vastpakken wordt de eigen hands-up-status opgeruimd.

In een auto zit de gijzelnemer als bijrijder en het slachtoffer als bestuurder.
De auto moet bij het starten vrijwel stilstaan. De gijzelnemer moet in first
person zitten; terugschakelen breekt de gijzeling af. Het slachtoffer kan blijven
rijden, remmen en sturen. Handen omhoog zijn in de auto niet nodig. Instappen met
een al vastgepakt slachtoffer en vastpakken van buiten de auto zijn niet ingebouwd.

## Dubbele H-toets voorkomen bij Sky

Als je Sky-hands-up eerder al hebt uitgeschakeld, laat dat zo staan.
Anders: zet in `sky_jobs_base/config/config.lua` bij `Config.PoliceCuffs`:

```lua
handsUp = {
    enabled = false,
    key = "H",
    holdSeconds = 3
},
```

Een diff van de eerder aangeleverde Sky-config staat in
`integrations/sky_handsup_uit.patch`; die wordt niet automatisch toegepast.
Controleer een eventuele override in je Job Configurator. Herstart na deze
Sky-wijziging de server en laat spelers opnieuw verbinden om oude actieve
hands-up-statussen te wissen. Verwijder een oude Sky-H-keybinding als deze nog
conflicteert. Onder FiveM-toetsinstellingen hoort H bij TroyScripts te staan.

Sky's overige functies blijven actief. Boeien/fouilleren kan afhankelijk zijn
van Sky's interne status; compatibiliteit daarvan met onze eigen hands-up is niet bevestigd.

## Configuratie

| Instelling | Betekenis |
| --- | --- |
| Config.Interaction | 'target', 'key' of 'both' |
| Config.Keys | Actie- en loslaattoets |
| Config.HandsUp | Eigen hands-up inschakelen, toets en animatie |
| Config.Weapons | Toegestane spawnnamen met type firearm, blade of blunt |
| Config.RequireAmmo | Vuurwapen moet munitie hebben |
| Config.Distance / BreakDistance | Startafstand en afbreekafstand |
| Config.Vehicle | Voertuigfunctie, first person, startsnelheid en zitplaatsen |
| Config.Profiles | Animaties en onderlinge ped-posities |
| Config.BladePose | Huidige visuele mespositie en handcorrectie |

Bestaande persoonlijke FiveM-keybindings kunnen standaardtoetsen overschrijven.
Custom wapens moeten expliciet in Config.Weapons staan. Een slug/spawnnaam die
niet in die lijst staat, wordt afgewezen. Lange wapens kunnen visueel afwijken.

## Discord-logs

Vul de twee webhook-URL's uitsluitend in `server_config.lua` in:

```lua
Start = 'https://discord.com/api/webhooks/JOUW_ID/JOUW_TOKEN',
Actions = 'https://discord.com/api/webhooks/ANDER_ID/ANDER_TOKEN',
```

Start logt een actieve gijzeling. Actions logt loslaten, omleggen en desgewenst
automatisch afbreken. De embed bevat namen, server-ID's, wapen, actie, situatie,
UTC-tijd en sessienummer. Standaard worden FiveM-namen gebruikt; voor RP-namen kan
WebhookConfig.PlayerName worden aangepast. URL's blijven server-side; mentions staan uit.

Foto's worden via screenshot-basic opgevraagd vanuit het spelbeeld van de dader.
Een foto is asynchroon en hoeft niet exact het actiemoment te tonen. Zonder foto
wordt tekst verstuurd. Zet `Screenshots = false` om alleen tekst te gebruiken.
`AvatarUrl` is optioneel voor een logo, onafhankelijk van de screenshot.

Bekend open punt: op de gebruikersserver verscheen `screenshot-basic: Failed to fetch`.
Die fout is nog niet opgelost. Dit bewijst niet dat de webhook-URL fout is.
De logqueue is begrensd en niet persistent; bij serverstop/storing kunnen logs verloren gaan.

## Diagnose en integratie

- `/ts_handcheck`: eigen hands-up-status, ruwe animatiewaarde en bezigstatus in F8.
- `/ts_hostagecheck`: lokale voorwaarden, wapenhash, camera en dichtstbijzijnde speler.
- `[ts_mespositie] world-pose`: mesmodel, lengteas en geschat lemmetcontact.
- `exports.ts_hostage:IsBusy()` en `GetRole()`: toestand voor inventory/emote/teleportscripts.
- `exports.ts_hostage:IsHandsUp()` en `LowerHands()`: eigen hands-up-status en beëindiging.
- `ts_hostage:busyChanged`: lokaal clientevent met busy en role.

Andere resources moeten de bezigstatus respecteren als ze eigen NUI of commands
gebruiken; framegebonden controlblokkering kan niet alle externe commands stoppen.
De gerepliceerde visuele status is geen anticheatbewijs. Handen-omhoog en first-person
worden client-side gecontroleerd; de server controleert onder meer afstand,
wapen, deelnemers, gezondheid, bucket en zitplaatsen.

## Bekende beperkingen

- De huidige mespositie blijft behouden. Hand/vingers sluiten niet correct op
  het handvat aan; er is geen passende custom mes-gijzelanimatie meegeleverd.
- De standaard hostagepose en ped-hitboxes geven geen gegarandeerde kogelbescherming.
- Executie zet de ped dood; schoteffecten en munitieverbruik zijn niet ingebouwd.
  De kill-log bevestigt de toegestane actie, niet de afhandeling door een externe ambulance-resource.
- Custom kleding, peds en voertuiginterieurs kunnen clipping veroorzaken.
- De screenshot-basic uploadfout en Sky-interactiecompatibiliteit staan nog open.

## Controle voor uitrol

De gebruiker heeft gijzelen te voet en in de auto als werkend gemeld. Lua-syntax
 en geautomatiseerde tests met gesimuleerde natives zijn voor 1.1.0 gecontroleerd.
Die tests bewijzen geen live animatiekwaliteit of daadwerkelijke Discord-bezorging.

Controleer op je server: H aan/uit; handen omlaag weigeren; E/target vastpakken;
X loslaten en combat; E-executie/death-flow; rijden tijdens auto-gijzeling;
third-person afbreken; beide webhooks; cleanup na disconnect of resource-stop.

## Referenties

- [screenshot-basic](https://github.com/citizenfx/screenshot-basic)
- [ox_target API](https://github.com/overextended/ox_target/blob/main/client/api.lua)
- [Discord webhooks](https://docs.discord.com/developers/resources/webhook)

## Politiemelding (1.1.1)

Alle online ESX-spelers met job `police` krijgen bij de start van een geldige
gijzeling één ox_lib-waarschuwing van 10 seconden. Er is geen dienststatusfilter.
Een geweigerde of afgebroken voorbereiding geeft geen melding. Loslaten of
omleggen geeft geen extra politiemelding. Er wordt geen kaartblip toegevoegd.

Pas `PoliceAlertConfig` in `server_config.lua` aan voor de jobs, tekst, duur en
positie. Zet `Enabled = false` om de politiemelding uit te schakelen.
Neem dit nieuwe configuratieblok over als je jouw oude server_config.lua bewaart.
Bestaande webhookinstellingen kun je behouden.

De melding gebruikt direct lib.notify met @ox_lib/init.lua:
https://overextended.dev/docs/ox_lib/Interface/Client/notify

Deze wijziging is lokaal gecontroleerd; test de melding ook op je FiveM-server
met een politieagent en twee spelers die een gijzeling starten.

## Locatie in politiemelding (1.1.2)
De melding vermeldt de straat, eventuele kruisende straat en het gebied waar de
gijzeling begon. De server bepaalt de coördinaten; de politieclient vertaalt die
naar kaartnamen. Bij ontbrekende namen worden coördinaten getoond. Druk binnen 60 seconden op **G** om een waypoint te plaatsen. Een nieuwe melding
vervangt de vorige bestemming. De route wijst naar de startlocatie, niet naar een
bewegende speler. `PoliceAlertConfig.WaypointSeconds` bepaalt de beschikbare tijd.
De toets is via FiveM-toetsinstellingen aanpasbaar (melding noemt standaard G).
Er is geen automatische route. Vervang ook fxmanifest.lua en neem het nieuwe
bestand police_alert.lua mee.

## Politiemelding controleren (1.1.3)
Start ox_lib en es_extended vóór ts_hostage. Herstart ts_hostage na vervangen.
Bij een oude server_config.lua zonder PoliceAlertConfig worden standaardmeldingen
voor job police gebruikt. Een expliciete Enabled = false blijft gerespecteerd.

Test in de **serverconsole**: `ts_hostage_policecheck 12` (vervang 12 door een online
speler-ID). Dit stuurt een test via hetzelfde meldingspad naar alle ingestelde
politiejobs, met de locatie van die speler. Hiervoor is geen gijzeling nodig.
De serverconsole toont het aantal ontvangers; bij nul ook de gevonden jobnamen.
Bij ontvangst toont de politieclient in F8 `Politiemelding ontvangen; locatie: ...`.
Druk op G om het waypoint te controleren. Test daarna een echte gijzeling.

Lokaal getest met gesimuleerde FiveM/ESX-functies; live ontvangst en de ox_lib-UI
moeten op de server worden gecontroleerd.
