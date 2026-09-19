# ts_hostage 1.1.8 bijwerken

1. Maak een backup en stop ts_hostage wanneer niemand in een gijzeling zit.
2. Kopieer de map ts_hostage uit deze ZIP over je bestaande resource met die naam.
   Bewaar je eigen server_config.lua (webhooks/politie-instellingen).
3. Config.lua bijwerken: **JA**, vereiste Config.Version is '1.1.8'. Neem eigen
   instellingen over in de nieuwe config, of voeg Version, RequireAimOnFoot,
   NotificationCooldownMs en Radial toe uit de meegeleverde config.
   Verhoog het configversienummer pas nadat je de velden hebt overgenomen.
4. Neem eigen vertalingen over; behoud de nieuwe sleutels in locales/nl.lua.
5. Start ts_hostage nadat ox_lib en ts_bridge 0.0.3 of nieuwer gestart zijn.
6. Controleer scriptversie 1.1.8 en de configmelding in de serverconsole.

server_config.lua heeft geen nieuwe velden: vervangen is niet nodig.
Deze bijgewerkte aansluiting vereist ts_bridge 0.0.3: werk de bridge ook bij. Deze ZIP bevat alleen
het volledige ts_hostage-script; geen bridge of andere resources.

Live controle met twee spelers:
- E zonder richten: geen melding. Richten + E: geldige poging of één afwijzing.
- Herhaald E: geen stapelende meldingen; standaard 5 seconden tussen meldingen.
- Ox_target te voet blijft zonder richten bruikbaar.
- Radialmenu: Gijzelen, Loslaten en Omleggen testen; omleggen pas na 1,5 seconde.
- Te voet na vastpakken richtknop loslaten: loslaten/omleggen blijven werken.
- Auto: third person + E/radial blijft stil; first person bijrijder kan bestuurder gijzelen.
- Slachtoffer moet te voet nog steeds de eigen handen-omhoog-functie gebruiken.
- Herstart resource: geen dubbel radialitem; stoppen verwijdert alleen het eigen item.

Gebruik je een ander radialmenu dan ox_lib, zet Config.Radial.Enabled uit en koppel
je menu aan de exports uit README.md. Geen databasewijziging nodig.
