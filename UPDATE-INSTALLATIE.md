# Installatie — ts_bridge 0.0.2(BETA), ts_hostage 1.1.7, ts_keycard 1.1.4

**Beide scripts vereisen de nieuwe ts_bridge 0.0.2(BETA).** Plaats alle resources onder
hun vaste mapnamen. De bridgecontrole kijkt naar versie, API 1 en de benodigde functies;
een oude 0.0.1-build is niet voldoende.

1. Bewaar backups van de drie resources en hun configuratie.
2. Stop eerst ts_hostage en ts_keycard; stop daarna ts_bridge.
3. Vervang bestanden met de meegeleverde drie zipbestanden.
4. Neem je instellingen over in de NIEUWE configuratiebestanden; behoud de nieuwe locale- en bridgebestanden.
5. Start dependencies, bridge en scripts in onderstaande volgorde. Geen dubbele ensure-regels toevoegen.

```cfg
ensure ox_lib
ensure es_extended
ensure esx_addonaccount
ensure ox_inventory
ensure ox_target
# Bij Apex-bankbetalingen:
ensure apex_banking
# Alleen voor facturen via de bridge-API:
ensure apex_billing
# Alleen voor hostage-screenshots:
ensure screenshot-basic
ensure ts_bridge
ensure ts_hostage
ensure ts_keycard
```

Start oxmysql en eventuele dependencies van jouw providers zoals voorheen. ox_target
is voor keycard nodig; hostage kan ook alleen via toetsen. screenshot-basic en Apex Billing
zijn geen vereiste voor gewone keycard-uitgifte. Bankproviderkeuze staat in de bridge;
keycard betaalt standaard contant, tenzij Config.PaymentAccount = 'bank'.

## Controle

- Controleer geslaagde bridgecontrole op client en server. Bij een ontbrekende/onbruikbare
  bridge wordt gameplay niet geactiveerd en stopt de server de betreffende resource.
- De guard wacht maximaal 5 seconden op de API. Keycard controleert ook ESX, inventory,
  society en zo nodig bank; clientcontrole vereist de targetprovider.
- Console: ts_bridge_check; voor politiemeldingen ts_hostage_policecheck <online speler-ID>.
- Stop de bridge tijdens een test: hostage ruimt zijn gijzeling op, keycard sluit zijn
  venster en verwijdert de NPC. Herstart na herstel eerst ts_bridge en daarna beide scripts.

## Instellingen en taal

- Meldingen, menu's en foutteksten: iedere resource heeft locales/nl.lua.
- Nederlands staat standaard aan en is fallback voor ontbrekende talen/sleutels.
- Selectie: Config.Locale in de scripts; TSBridgeConfig.Locale in de bridge.
- Nieuwe talen: zie locales/LEESMIJ.md. Behoud opmaakvariabelen en Lua-syntax.
- Hostage-webhooks en politie-instellingen blijven in ts_hostage/server_config.lua;
  centrale webhookroutes en screenshotlimieten staan in ts_bridge/server_config.lua.
- Keycard-prijs/rangen/locatie blijven in ts_keycard/config.lua. SocietyAccount verwijst
  naar de bridge-alias police (standaard society_police, oude spelling als fallback).
- Society-geld gaat uitsluitend via esx_addonaccount. Er wordt niets dubbel naar een
  Apex- of okok-businessrekening geboekt.

## Betalingen en beperkingen

Keycard biedt directe cash/bankbetaling en bevestigde societybijschrijving, met herstel
bij bekende fouten. Onzekere resultaten melden een referentie voor handmatige controle;
niet opnieuw klikken of blind terugbetalen. Een serverstop kan geen lopende betaling
atomair maken: stop scripts wanneer er geen uitgifte in behandeling is.

Er is geen factuurbetaling gekoppeld aan kaartuitgifte. De Apex-betaalbeperking en de nog
ontbrekende okokBilling-adapter blijven gelden; zie KEYCARD-BANKING-BILLING.md en OKOK.md.

De scriptupdate heeft geen eigen SQL-migratie nodig. Keycard-KVPs blijven behouden onder
dezelfde resourcenaam. Maak geen dubbele itemdefinitie aan. VLR-deurtoegang en de resources
Apex/okok zelf zijn niet aangepast. Publiceren op GitHub is niet uitgevoerd.

## Teststatus

Lua-syntax, mocks voor bridgecontrole, locales, betalingen, rechten en bestaande hostage-
functies zijn gecontroleerd. Live testen met jouw FiveM/providers blijft nodig. Zie de
README/LEESMIJ van ieder script en de meegeleverde tests. Bewaar de drie mappen naast
elkaar om de integratietests vanuit hun eigen resourcemap met Lua 5.4 uit te voeren.
