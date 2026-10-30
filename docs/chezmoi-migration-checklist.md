# Chezmoi-migrering

Ferdig når alle eksisterende konfigurasjonsmål er migrert og testet, eller eksplisitt klassifisert som installasjon/runtime med begrunnelse. Testet i isolerte hjem; faktisk utrulling og ekstern autentisering rapporteres separat.

- [x] Arbeidsavtale i AGENTS.md
- [x] Resterende fellesfiler og runtime-lenker; sikre eksisterende lokale filer
- [x] Git-identitet og hemmeligheter; ingen utilsiktet overskriving eller logging
- [x] Mise-moduler og alle maskinprofiler
- [x] Mac-spesifikt oppsett og tydelig grense mot provisioning
- [x] Integrert gjennomgang og isolerte regresjonstester
- [x] Dokumentasjon med fullstendig målinventar og begrensninger
- [x] Resultater i issue 25

Eksisterende brukerendring i per-host-config/_shared/install-utils.inc skal bevares.

## Sluttkontroll 2026-10-30

Alle 12 tester i `scripts/test-chezmoi.sh` bestått med chezmoi 2.73.0 i isolerte hjem. Samlet mac-work-konfigurasjon kjøres to ganger for å kontrollere gjentakelse. `git diff --check` bestått.

Implementasjonen er ferdig i arbeidskopien, inkludert Mac-konfigurasjonen. Ingen aktiv hjemmekatalog eller andre maskiner er migrert av denne testkjøringen. Reell 1Password-autentisering og OS-provisioning er ikke testet. Implementasjonen publiseres i en egen PR mot master. Hemmeligheter som allerede finnes, beholdes lokalt; valgfri bootstrap krever en faktisk brukeroppgitt referanse.

Dokumentert i https://github.com/fatso83/dotfiles/issues/25#issuecomment-6533803343
