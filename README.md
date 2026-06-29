# BookGate

Läs-quiz app som tjänar skärmtid. Bygger IPA via GitHub Actions — ingen Mac behövs.

## Bygg IPA via GitHub (gratis)

1. Skapa ett nytt repo på GitHub och pusha upp hela denna mapp.
2. Gå till fliken **Actions** i repot → kör workflowet **"Build IPA"** (knappen "Run workflow").
   - Eller gör en ny push till `main`, det triggar automatiskt.
3. Vänta tills jobbet är klart (grön bock, tar ~2–5 min).
4. Öppna jobbet → under **Artifacts** längst ner: ladda ner `BookGate-ipa`.
5. Packa upp zip-filen → du får `BookGate.ipa`.

## Installera på din iPhone

IPA:n är **osignerad** — det är meningen. Sideload-verktyg signerar den lokalt med ditt eget Apple-ID:

- **SideStore** eller **AltStore**: öppna appen → "+" → välj `BookGate.ipa` → den signeras och installeras automatiskt.
- Lita på profilen: Inställningar → Allmänt → VPN & enhetshantering → lita på din e-post.

## Lokalt i Xcode (om du har en Mac)

```
brew install xcodegen
xcodegen generate
open BookGate.xcodeproj
```

Då slipper du manuell projekt-uppsättning — `xcodegen generate` bygger `.xcodeproj` automatiskt från `project.yml`.

## Hur appen fungerar

1. Första gången: ange din gratis Gemini API-nyckel (https://aistudio.google.com → "Get API key")
2. Sök efter en bok (svenska eller engelska)
3. Ange vilka sidor du har läst
4. AI genererar 5 quiz-frågor
5. Svara — resultatet ger 0–60 minuter skärmtid beroende på antal rätt

## Krav
- iPhone med iOS 17+
- SideStore eller AltStore installerat på telefonen
- Gratis Gemini API-nyckel
