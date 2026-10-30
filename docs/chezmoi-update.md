# Oppdatere uten å miste lokale endringer

Konfigurasjonen er i dette repoet. Oppsettet bruker målrettede chezmoi-kall med egen konfigurasjon og tilstand. Vanlig `chezmoi update` er derfor ikke inngangen for denne migreringen.

1. Avslutt redigering av konfigurasjon mens oppdateringen pågår. Se `git status --short` og `git submodule foreach --recursive 'git status --short'`. Bevar lokale endringer før du fortsetter.
2. Hent hovedrepoet med `git pull --ff-only`. Dette unngår automatisk stash og rebase. Stopp ved feil.
3. Kjør `git submodule sync --recursive` og `git submodule update --init --recursive`. Stopp ved feil, også autentiseringsfeil eller avbrutt overføring.
4. Kontroller `git status --short`, `git ls-files -u`, `git submodule status --recursive` og status inne i submodulene igjen. Submodulstatus skal ikke begynne med `-`, `+` eller `U`. Ingen uløste konflikter eller lokale endringer skal gjenstå.
5. Kjør `scripts/apply-chezmoi.sh` fra repoet (eventuelt med maskinprofil som argument). De stopper ved avvikende lokale filer. Hele `setup.sh` installerer også programmer og er ikke en ren konfigurasjonsoppdatering.

Et mislykket submodulkall kan ha oppdatert deler av Git-utsjekkingen. Ikke kjør apply etter feilen. Rett tilgang/nettverk og gjenta submoduloppdatering og kontroll. Ikke bruk reset/clean eller slett lokale filer for å tvinge gjennom oppdateringen.

Repo-lenker peker på levende innhold: når Git endrer en lenket kildefil, ser programmet endringen umiddelbart, selv før apply. Disse lenkene bevarer eksisterende plugin- og runtimeoppsett, men gir ikke en atomisk utrulling. Bruk en separat utsjekking dersom alle kildeendringer må være isolert fra aktive programmer før godkjenning.

Kontrollene er heller ikke en lås mot samtidige redigeringer. Ikke kjør flere oppsettsprosesser samtidig. Ikke del diff av filer med hemmeligheter; hemmelighetstester bruker kun falske verdier.
