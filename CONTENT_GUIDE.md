# Content beheren (content.json)

De app haalt zijn cheats uit `content.json` in deze repo. Jij past het bestand aan, pusht naar `main`, en de app pakt het binnen een paar uur op. Er is geen app-update nodig. Er is geen backend, alleen GitHub.

Bestanden:

| Bestand | Wat |
|---|---|
| `content.json` | De content. Dit bewerk je. Wordt ook in de app gebundeld als laatste fallback. |
| `content.schema.json` | JSON Schema: de regels waaraan `content.json` moet voldoen. |
| `tool/validate_content.py` | Lokale validatie (zelfde check draait in GitHub Actions). |
| `.github/workflows/validate-content.yml` | Valideert bij elke push/PR die content raakt. |

## Eenmalig instellen

1. Zet de repo op GitHub (publiek).
2. Zet in `lib/services/cheat_repository.dart` de constante `contentUrl` op:
   `https://raw.githubusercontent.com/<JOUW-USER>/<JOUW-REPO>/main/content.json`
   Zolang `<USER>`/`<REPO>` erin staan, doet de app geen netwerkverzoeken en gebruikt hij alleen de gebundelde content.
4. Zet in `lib/services/feedback.dart` `feedbackEmail` op je eigen adres: dat is waar "Mis je een cheat? Meld het" naartoe gaat.
3. Lokaal valideren: `pip install jsonschema`

## Een cheat toevoegen

1. Voeg een object toe aan `cheats` in `content.json` (zie de templates hieronder).
2. Kies een **nieuw, uniek `id`**: kleine letters, cijfers en `_`, bijvoorbeeld `vehicle_new_car`.
   **Hergebruik nooit een id**, ook niet van een verwijderde cheat. Favorieten, "unlocked" en "gezien" van gebruikers hangen aan het id.
3. Vul `addedAt` en `updatedAt` met de datum van vandaag (`YYYY-MM-DD`). Zet eventueel `"isNew": true` om hem extra te laten opvallen.
4. Verhoog `contentVersion` met 1 en zet `updatedAt` bovenin op vandaag.

## Een cheat wijzigen

1. Pas de velden aan. Zet `updatedAt` van die cheat op vandaag: gebruikers zien dan het label **BIJGEWERKT**.
2. Verander `id` en `categoryId` niet.
3. Verhoog `contentVersion` met 1.

## Een cheat verwijderen

Haal het object uit `cheats` en verhoog `contentVersion`. Het id blijft voor altijd "bezet". Gebruikers die de cheat als favoriet hadden, houden die markering stilletjes in hun opslag, maar zien hem niet meer.

## Velden

- `status`: `verified` (zelf in de game getest), `unverified` (uit een bron, nog niet getest), `rumor` (gerucht). De app toont het label bij elke cheat.
- `codes`: per platform optioneel: `ps5`, `xbox`, `pc`, `phone`. Een code is een lijst `["UP","DOWN","LEFT","RIGHT"]` of een tekst (bijv. een telefoonnummer). Geen code voor het gekozen platform = "CODE TBA".
- Teksten (`title`, `effect`, `unlockRequirement`, `description`, categorienaam, announcement) zijn objecten per taal: `{ "en": "...", "nl": "..." }`. **`en` is verplicht** en is de fallback. Een extra taal toevoegen = een extra sleutel (`"de": "..."`); de app kiest de taal van het toestel.
- `tags`: vrije zoekwoorden, doorzoekbaar in de app.
- `aliases` (optioneel): extra zoekwoorden en synoniemen in elke taal, bijvoorbeeld `["politie", "cops"]`. Alleen nodig als iemand een cheat anders zou noemen dan de titel. De app kent daarnaast zelf veelgebruikte NL/EN-synoniemen (politie/cops/wanted, geld/money, auto/vehicle, enz.) en vergeeft kleine typfouten.
- `description` is optioneel: een langere uitleg naast de korte `effect`.
- `announcement` (optioneel): een banner bovenaan. Zet `active: true`. Gebruikers kunnen hem wegklikken; wijzig het `id` om hem opnieuw te tonen. Zet `active: false` of verwijder het blok om hem te verbergen.

## contentVersion en schemaVersion

- `contentVersion`: **verhoog bij elke wijziging**. De app downloadt/gebruikt alleen content met een hoger nummer dan wat hij al heeft. Verlaag het nooit: de app negeert lagere versies en de validatie in CI faalt.
- `schemaVersion`: alleen verhogen als je de *structuur* breekt op een manier die oude apps niet snappen (dan is ook een app-update nodig). Oude apps tonen dan een zachte melding "Update de app voor nieuwe functies" en blijven hun laatste geldige content gebruiken. Gewone content-wijzigingen raken dit nooit.

## Welke cheats staan waar in de app

De app toont standaard alleen cheats **met een code** in de hoofdlijst. Cheats zonder code (`codes` ontbreekt of is leeg) staan onderaan in de ingeklapte sectie "Nog geen code bekend". Zodra je een code toevoegt, springt de cheat vanzelf naar de hoofdlijst. Gebruikers kunnen dit uitzetten in Instellingen.

## Lokaal valideren

```bash
python3 tool/validate_content.py                 # schema + eigen checks
python3 tool/validate_content.py --against main  # controleert ook of contentVersion is verhoogd t.o.v. main
```

Het script controleert onder meer: schema, dubbele ids, bestaande `categoryId`, geldige datums, `updatedAt >= addedAt`, en (met `--against`) dat contentVersion omhoog is gegaan en dat een id niet bij een andere categorie is hergebruikt.

## Testen in de app

1. Zet `contentUrl` op je raw-URL, push `content.json` naar `main`.
2. Open de app, ga naar **Instellingen → Nu verversen**. Dit slaat de throttle over.
3. Controleer: de regel "Laatst bijgewerkt" en de contentversie kloppen, de nieuwe cheat heeft het label NIEUW.
4. raw.githubusercontent.com cachet ongeveer **5 minuten**. Zie je een wijziging niet meteen, wacht dan even en ververs opnieuw. De app probeert nooit automatisch opnieuw.
5. Test offline: vliegtuigmodus aan, app herstarten. Je ziet de laatst gecachete content.
6. De app controleert automatisch bij het opstarten en bij terugkeren naar de voorgrond, maximaal eens per 3 uur.
7. Zelf proberen: `flutter test` draait ook de tests op het gebundelde `content.json`.

## Checklist vóór commit

- [ ] Nieuwe ids zijn uniek en nooit eerder gebruikt
- [ ] Bij elke `en`-tekst staat (waar mogelijk) een `nl`-tekst
- [ ] `status` is eerlijk: `verified` alleen als je het zelf in-game hebt getest
- [ ] `addedAt` / `updatedAt` kloppen
- [ ] `contentVersion` is met 1 verhoogd, bovenste `updatedAt` is vandaag
- [ ] `python3 tool/validate_content.py --against main` geeft `OK`
- [ ] Gewijzigd JSON-bestand is geldig (geen losse komma's)

## Templates

Kopieer en pas aan. Ze staan hier alleen als voorbeeld, niet in `content.json`.

**1. Cheat met D-pad-code voor alle consoles (status geverifieerd)**
```json
{
  "id": "player_example_money",
  "title": { "en": "Example Money", "nl": "Voorbeeldgeld" },
  "categoryId": "player",
  "effect": { "en": "Adds $1,000.", "nl": "Geeft $1.000." },
  "unlockRequirement": { "en": "Complete the main story.", "nl": "Speel de verhalende campagne uit." },
  "codes": {
    "ps5": ["UP", "DOWN", "LEFT", "RIGHT"],
    "xbox": ["UP", "DOWN", "LEFT", "RIGHT"]
  },
  "status": "verified",
  "addedAt": "2026-11-20",
  "updatedAt": "2026-11-20",
  "tags": ["money"],
  "isNew": true
}
```

**2. Cheat zonder bekende code (de app toont "CODE TBA")**
```json
{
  "id": "vehicle_example_car",
  "title": { "en": "Example Car" },
  "categoryId": "vehicles",
  "effect": { "en": "Spawns an Example Car.", "nl": "Roept een Example Car op." },
  "unlockRequirement": { "en": "Complete 5 shopping challenges.", "nl": "Voltooi 5 shopping-challenges." },
  "status": "unverified",
  "addedAt": "2026-11-20",
  "updatedAt": "2026-11-20",
  "tags": ["vehicle", "spawn"]
}
```

**3. Gerucht met platform-verschillen, telefooncode en uitleg**
```json
{
  "id": "env_example_rumor",
  "title": { "en": "Example Rumor", "nl": "Voorbeeldgerucht" },
  "categoryId": "environment",
  "description": { "en": "Longer explanation shown in search.", "nl": "Langere uitleg, doorzoekbaar." },
  "effect": { "en": "Turns the sky green.", "nl": "Maakt de lucht groen." },
  "unlockRequirement": { "en": "Unknown.", "nl": "Onbekend." },
  "codes": {
    "ps5": ["LEFT", "LEFT", "UP", "DOWN"],
    "phone": "555-0100"
  },
  "status": "rumor",
  "addedAt": "2026-11-20",
  "updatedAt": "2026-11-20",
  "tags": ["weather"]
}
```

## Een announcement plaatsen

```json
"announcement": {
  "id": "launch_week",
  "title": { "en": "New codes found!", "nl": "Nieuwe codes gevonden!" },
  "message": { "en": "12 codes were added.", "nl": "Er zijn 12 codes toegevoegd." },
  "active": true
}
```
