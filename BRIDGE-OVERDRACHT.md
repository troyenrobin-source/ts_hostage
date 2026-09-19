# Overgedragen aan ts_bridge 0.0.3

Uitgevoerd in deze bijgewerkte ts_hostage 1.1.8:
- Meldingslimiet via Notify(data, cooldownMs); titel en ID vanuit hostage.
- Configversievergelijking via CheckConfigVersion; defaults blijven in hostage.
- Radialmenu via RegisterRadialMenu; registratie-eigendom en opruiming in bridge.

Richtcontrole, voertuigcamera, requestcontext, gijzelingssessies, animaties en
servervalidatie blijven in hostage. GetStatus-controle vereist nu minimaal 0.0.3
plus de nieuwe exports. Configschema van hostage blijft 1.1.8.
