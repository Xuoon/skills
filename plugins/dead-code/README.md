# dead-code

Ein Befehl statt scan+purge-Paar: `/dead-code [pfad]` durchsucht alles, listet Funde gruppiert mit Confidence, und löscht nach Freigabe — "unsicher" wird grundsätzlich nie gelöscht.

Bewusst als Single-Skill-Plugin gebaut (SKILL.md im Plugin-Root → Befehl heißt wie das Plugin). Sollte später ein zweiter Befehl dazukommen, wandert die SKILL.md in `skills/<name>/` und der Befehl wird zu `/dead-code:<name>`.
