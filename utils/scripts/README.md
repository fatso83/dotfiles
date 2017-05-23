# Utility scripts

## Git scripts

```bash
$ git delete-merged 

git-delete-merged [--doit] <remote> [<branches to skip>]

Example: git-delete-merged --doit origin deploy-branch,demo

By default, "master" and "develop" are skipped
Specifying core.protected-branches in your git config, or
listing them on the command line with commas will override this
```

```bash
$  git branch-overview
 (origin/demo, demo) Fixed infinite loop and warnings after merge. (8 months ago) <oddbjornkvalsund>
 (HEAD -> develop, origin/develop, origin/HEAD) Merge branch 'test-in-meteor' into develop (21 hours ago) <Carl-Erik Kopseng>
 (origin/sunnaas, sunnaas) right name for nurse Gianina, changed from Tone Møller (3 months ago) <Soheil>
```

```bash
$ git find-by-name-in-log README
e807f94231ac08d81b661a992bf034c3ded1ff81:100644 blob 783313a55ecec0227cf4cdf6076eab9ed6315b02	README.md
e807f94231ac08d81b661a992bf034c3ded1ff81:100644 blob ac034405fd2ab26c7e5367734b481d1e3fb2b570	per-host-config/README.md
e807f94231ac08d81b661a992bf034c3ded1ff81:100644 blob 222a36dbb420f252627cb5141bfddedbc45aee28	per-host-config/win-dev-machine/README.md
e807f94231ac08d81b661a992bf034c3ded1ff81:100755 blob 189faa86ff98454e07856f95978ee9ac44082ac8	per-host-config/win-dev-machine/conemu-terminals/README.md
```

```bash
git rm-deleted # deletes from index files that are missing (manually removed) 
```

## Other 

```bash
$ gzipped-size *
cross-platform-utils.bashlib     : 364 bytes (versus 558 bytes)
generate_account_number          : 604 bytes (versus 1121 bytes)
git-branch-overview              : 147 bytes (versus 113 bytes)
git-delete-merged                : 907 bytes (versus 2047 bytes)
git-find-by-name-in-log          : 274 bytes (versus 371 bytes)
git-rm-deleted                   : 271 bytes (versus 385 bytes)
git-setup-local-repo-aliases.sh  : 558 bytes (versus 840 bytes)
gzipped-size                     : 285 bytes (versus 341 bytes)
README.md                        : 260 bytes (versus 357 bytes)
``` 
