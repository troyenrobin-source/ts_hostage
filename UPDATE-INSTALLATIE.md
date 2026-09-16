# Installatie — ts_bridge 0.0.1(BETA) + ts_hostage 1.1.6

Deze eerste beta sluit ts_hostage aan op de nieuwe centrale ts_bridge.
Er is geen SQL-wijziging nodig. ts_keycard en andere resources worden nog niet aangepast.

1. Maak een backup van je huidige ts_hostage, vooral config.lua en server_config.lua.
2. Stop ts_hostage voordat je bestanden vervangt.
3. Pak ts_bridge-0.0.1-BETA.zip uit: plaats de map ts_bridge in resources/[troyscripts].
4. Vervang de bestanden in je bestaande map ts_hostage door de map uit ts_hostage-1.1.6.zip.
   Neem eigen instellingen over. Beide resourcenamen moeten exact behouden blijven.
5. Gebruik onderstaande volgorde in server.cfg. Voeg bestaande ensure-regels niet dubbel toe.

```cfg
ensure ox_lib
ensure es_extended
ensure ox_target
ensure screenshot-basic
ensure ts_bridge
ensure ts_hostage
```

ox_target is optioneel bij Config.Interaction = 'key'. screenshot-basic is alleen nodig
voor screenshots. De ESX-koppeling is nodig voor jobgebonden politiemeldingen.
Bij bewust standalone gebruik: TSBridgeServer.Framework = 'standalone'; politiemeldingen
hebben dan geen jobontvangers. ox_lib en ts_bridge zijn verplicht voor deze hostageversie.

## Instellingen

- Gijzelingsgedrag, H/E/X en targetkeuze: ts_hostage/config.lua.
- Politiejobs, meldingstekst en duur: ts_hostage/server_config.lua (PoliceAlertConfig).
- Start/Actions-webhooks mogen in ts_hostage/server_config.lua blijven staan.
- Centraal beheren kan via TSBridgeServer.Webhooks.ts_hostage.start/actions in
  ts_bridge/server_config.lua. Een ingevulde centrale route krijgt voorrang;
  een lege centrale route gebruikt de URL uit ts_hostage.
- WebhookConfig.Enabled en WebhookConfig.Screenshots in ts_hostage blijven werken.
- Timeout, maximale afbeeldingsgrootte en totale wachtrij configureer je voortaan
  uitsluitend in ts_bridge/server_config.lua. Oude gelijknamige hostagevelden worden niet gebruikt.
- Zet webhook-URL's alleen in server_config.lua; nooit in client/shared-bestanden of op GitHub.
- ts_bridge/config.lua bevat meldingsdefaults, de standaard waypointtoets en targetresource.
- Een resource hernoemen configureert geen ander product: de target- en screenshotresource
  moeten dezelfde API ondersteunen als respectievelijk ox_target en screenshot-basic.

## Controle op je server

Voer in de serverconsole uit:

```text
ts_bridge_check
ts_hostage_policecheck 1
```

Vervang 1 door een online speler-ID. De tweede opdracht stuurt politie de locatie van
 die speler. Controleer dat alleen de ingestelde jobs de melding krijgen en G een waypoint zet.
De nieuwe keymapping heet 'Troy Scripts: waypoint naar laatste melding'. Eerder aangepaste
hostage-waypointtoetsen worden niet automatisch overgenomen; stel die zo nodig opnieuw in
onder GTA-instellingen > Toetsenbindingen > FiveM.

Test daarna met twee spelers: handen omhoog, gijzelen met E en target, loslaten met X,
omleggen, gijzeling in een auto en stoppen van ts_hostage tijdens een actieve gijzeling.
Controleer beide webhookkanalen en de screenshotbijlage. De bridge vraagt screenshots
op via screenshot-basic en uploadt ze naar Discord; er wordt geen lokaal fotoarchief gemaakt.
Een bridge installeren verhelpt niet automatisch een bestaande screenshotprovider- of netwerkfout.
Ontbrekende provider, time-out, ongeldige afbeelding en HTTP-fouten krijgen afzonderlijke
consolemeldingen, zonder webhooktoken of afbeeldingsinhoud te printen.

## Bijwerken / herstarten / terugzetten

Stop eerst aangesloten scripts, vervolgens de bridge. Start in omgekeerde volgorde:

```text
stop ts_hostage
stop ts_bridge
ensure ts_bridge
ensure ts_hostage
```

Lopende gijzelingen eindigen bij het stoppen van ts_hostage. In behandeling zijnde logs
kunnen bij het stoppen van ts_bridge verloren gaan; de wachtrij is niet persistent.
Voor terugzetten: stop ts_hostage, herstel je complete oude hostagebackup en start die.
Stop/verwijder ts_bridge alleen wanneer geen ander script hem gebruikt.

## Versies en controle

- ts_bridge: 0.0.1(BETA), eerste beta.
- ts_hostage: 1.1.6, gebaseerd op je aangeleverde 1.1.5.
- De bestaande GitHub-updatecontrole van ts_hostage blijft in die resource staan.
  Er is niets op GitHub gepubliceerd. ts_bridge heeft nog geen online updatebron.
- Lua 5.4 syntax en acht testscripts met gesimuleerde FiveM-API's gecontroleerd.
  Geen live FiveM-, ESX-, ox_target- of Discordtest uitgevoerd.

Bronnen voor de gebruikte interfaces:
- https://docs.fivem.net/docs/scripting-reference/resource-manifest/
- https://github.com/citizenfx/screenshot-basic
