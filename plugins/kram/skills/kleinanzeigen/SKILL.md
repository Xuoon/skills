---
name: kleinanzeigen
description: >
  Recherchiert den realistischen Gebrauchtpreis eines Artikels und schreibt die fertige
  Kleinanzeige dazu, also Titel, Preisempfehlung mit Marktspanne und eine
  copy-paste-fähige Beschreibung mit Gewährleistungsausschluss. Triggern bei
  "Kleinanzeige/Verkaufsanzeige für X", "was kann ich für X verlangen",
  "Wiederverkaufswert von X", "Gebrauchtpreis", oder wenn der Nutzer einen Artikel nennt,
  den er privat verkaufen will — auch ohne das Wort "Kleinanzeigen".
---

# Kleinanzeige

Aus einem Produktnamen wird ein recherchierter Preis und ein fertiger Anzeigentext.

**Zustand:** ohne Angabe gilt „gebraucht, guter Zustand, voll funktionsfähig". Nennt der Nutzer etwas anderes (neu, OVP, Gebrauchsspuren, defekt, fehlendes Zubehör), zählt seine Angabe — der Zustand bewegt den Preis am stärksten. Fehlende Angaben nicht erfragen, sondern annehmen. Einzige Ausnahme: das Produkt selbst ist mehrdeutig, also mehrere Varianten mit stark unterschiedlichem Wert.

## 1. Produkt identifizieren

Modell, Variante, Generation, Speichergröße, Bundle oder Einzelgerät. Versionskürzel wie „V2" oder „Mk II" nicht aus dem Gedächtnis deuten, sondern nachschlagen — genau daran hängt der Preis.

## 2. Preis recherchieren

Ziel ist ein Verkaufspreis, kein Wunschpreis. Drei getrennte Suchen statt einer:

1. **Neupreis als Obergrenze:** idealo, geizhals, Amazon, Herstellershop. Gibt es das Produkt überhaupt noch neu?
2. **Tatsächlich gezahlte Preise:** eBay, verkaufte beziehungsweise beendete Artikel. Das ist die wichtigste Quelle, weil sie Abschlüsse zeigt statt Forderungen.
3. **Aktuelle Forderungspreise:** laufende Kleinanzeigen-Inserate desselben Modells.

## 3. Spanne und Empfehlung

- **Verkäufe schlagen Forderungen.** Inserate und laufende eBay-Angebote nach unten korrigieren, real wird 10 bis 30 Prozent darunter verkauft.
- **Zustand, Vollständigkeit, Alter einrechnen.** OVP und komplettes Zubehör heben, fehlende Teile und Gebrauchsspuren senken deutlich.
- **Liquidität:** kleiner Käuferkreis bei Profi- und Nischenhardware, also eher unteres Ende. Gefragtes darf höher.
- **Unter etwa 20 Euro** scharf kalkulieren, sonst frisst das Porto den Preis.
- **Empfehlung** ist ein konkreter Betrag, meist am oder knapp unter dem Median der echten Verkäufe. „(VB)" nur anbieten, wo in der Kategorie üblicherweise gehandelt wird.

Dünne oder stark streuende Datenlage: trotzdem eine Empfehlung nennen und die Unsicherheit in einem Halbsatz. Praktisch wertlose Artikel ehrlich als solche benennen, gegebenenfalls „zu verschenken" oder nur Versandkosten.

## 4. Anzeige schreiben

Freundlich, locker, ehrlich, per du. Kurz halten, lange Anzeigen werden überflogen. Einleitung mit Anrede, danach drei bis sechs Stichpunkte zu Produkt, Zustand und Lieferumfang; bei einfachen Artikeln reicht Fließtext. Modell und Variante natürlich einbauen, damit die Anzeige gefunden wird. Nichts erfinden.

**Das Beschreibungsfeld rendert kein Markdown**, alles erscheint wörtlich. Also kein Fettdruck, keine Rautenüberschriften, keine `*`- oder `•`-Bullets. Stichpunkte immer mit Bindestrich und Leerzeichen. Deshalb steht die Beschreibung in einem Codeblock, damit sie eins zu eins kopiert wird.

Der Preis gehört nicht in den Beschreibungstext, Kleinanzeigen hat ein eigenes Preisfeld. Versand und Abholung nur erwähnen, wenn der Nutzer etwas gesagt hat oder es offensichtlich ist. Keine Portokosten und keine Versandzusagen erfinden.

## Ausgabe

Genau diese Struktur, ohne Recherchebericht davor:

**Titel:** <prägnant, höchstens 65 Zeichen, mit Modell und Variante als Suchbegriff>

**Preisempfehlung:** <Betrag> € · Marktspanne ca. <X>–<Y> € [ggf. „(VB)"]

**Beschreibung (zum Kopieren):**

```text
Hallo zusammen, ich verkaufe hier <…>.

- <Was es ist und kann>
- <Zustand>
- <Lieferumfang>

---

Privatverkauf, keine Garantie, keine Rücknahme, kein Umtausch. Verkauf erfolgt unter Ausschluss jeglicher Gewährleistung.
```

Kein Begründungsblock. Höchstens ein Satz unter der Preiszeile, und nur wenn er trägt, etwa bei großer Streuung oder wenn eine neuere Generation den Preis drückt.

## Beispiel

Eingabe: „Grandstream HT801, ohne OVP, nur Adapter ohne Netzteil"

**Titel:** Grandstream HT801 ATA – analoger Telefonadapter (FXS)

**Preisempfehlung:** 12 € · Marktspanne ca. 8–18 €

**Beschreibung (zum Kopieren):**

```text
Hallo zusammen, ich verkaufe hier meinen Grandstream HT801, einen analogen Telefonadapter (ATA, 1x FXS), mit dem sich ein klassisches Analogtelefon an VoIP/SIP betreiben lässt.

- Voll funktionsfähig, sauber auf Werkseinstellungen zurückgesetzt
- Gebraucht, leichte Gebrauchsspuren
- Lieferumfang: nur das Gerät, kein Netzteil, keine OVP

---

Privatverkauf, keine Garantie, keine Rücknahme, kein Umtausch. Verkauf erfolgt unter Ausschluss jeglicher Gewährleistung.
```

Die Preise sind illustrativ, im echten Lauf wird immer recherchiert.

## Sonderfälle

- **Zu obskur:** sagen, dass es kaum Vergleichsdaten gibt, grobe Schätzung mit klarem Vorbehalt.
- **Brandneu, versiegelt:** näher am Neupreis, aber unter Fachhandel — Privatverkauf ohne Garantie heißt Abschlag.
- **Defekt oder Bastlerware:** klar benennen und deutlich niedriger ansetzen.
