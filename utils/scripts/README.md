# Utility scripts

This is not a exhaustive list of the scripts. Look in the actual folder to see 
what is there. Also, some options may have been added/removed/changed, so
run `the-command --help` to see actual options.

## Installing a script standalone
Generally, you can download standalone versions of these by following this general recipe:

```
BASE="https://raw.githubusercontent.com/fatso83/dotfiles/master/utils/scripts"
curl -s $BASE/easyoptions.sh -o easyoptions.sh
curl -s $BASE/easyoptions.rb -o easyoptions.rb
curl -s $BASE/gnome-key-bindings -o gnome-key-bindings
chmod +x ./gnome-key-bindings
sudo mv ./gnome-key-bindings easyoptions.* /usr/local/bin/
```

## Git scripts

### `git delete-merged`

Deletes local or remote branches that have been merged, but skips (pre-)configured branches.

```bash
git-delete-merged [--doit] [[--local]|<remote>] [<branches to skip>]

Example: git-delete-merged --doit origin deploy-branch,demo
Example: git-delete-merged --doit --local 

By default, "master" and "develop" are skipped
Specifying core.protected-branches in your git config, or
listing them on the command line with commas will override this
```

### `git branch-overview`

Lists the branch tips of the various branches.

```bash
$  git branch-overview
 (origin/demo, demo) Fixed infinite loop and warnings after merge. (8 months ago) <oddbjornkvalsund>
 (HEAD -> develop, origin/develop, origin/HEAD) Merge branch 'test-in-meteor' into develop (21 hours ago) <Carl-Erik Kopseng>
 (origin/sunnaas, sunnaas) right name for nurse Gianina, changed from Tone Møller (3 months ago) <Soheil>
```

### `git find-by-name-in-log`

Finds files by name in the log.

```bash
$ git find-by-name-in-log README
e807f94231ac08d81b661a992bf034c3ded1ff81:100644 blob 783313a55ecec0227cf4cdf6076eab9ed6315b02	README.md
e807f94231ac08d81b661a992bf034c3ded1ff81:100644 blob ac034405fd2ab26c7e5367734b481d1e3fb2b570	per-host-config/README.md
e807f94231ac08d81b661a992bf034c3ded1ff81:100644 blob 222a36dbb420f252627cb5141bfddedbc45aee28	per-host-config/win-dev-machine/README.md
e807f94231ac08d81b661a992bf034c3ded1ff81:100755 blob 189faa86ff98454e07856f95978ee9ac44082ac8	per-host-config/win-dev-machine/conemu-terminals/README.md
```

### `git rm-deleted`

Darn, you just `rm file1.txt`, instead of `git rm file1.txt`? This will add them to the staged area for deletion.

```bash
git rm-deleted # deletes from index files that are missing (manually removed) 
```

## Other 

### Gzipped size

Get the gzipped size of the files passed as arguments
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

### `get-npm-file`
Checks out the tarball from NPM and extracts the file(s)

```
USAGE

    get-npm-file.sh [--to-stdout] some-pkg[@version] [file]

    Gets a file (or all if none is given) from an NPM package
```

#### Example: show the peerDependencies of a package
```bash
`get-npm-file --to-stdout sinon-test@2.1.1 package.json | pick_json -e 'peerDependencies'`
```

### `inotify-consumers`
Lists all the owners of inotify watchers and their watcher count. This is useful, for instance,
to estimate how much higher to set the max threshold (Ubuntu default 8K - way too little.)

A sensible setting is typically 100'000 or more on a development machine.

#### Example
```
inotify-consumers  |head

   INOTIFY
   WATCHER
    COUNT     PID     CMD
----------------------------------------
    8409    15705  node /home/carlerik/dev/nimble-frontend/node_modules/.bin/webpack --config config/webpack.dev.js
    6875    20089  /snap/webstorm/76/bin/fsnotifier64
      85     2727  /usr/lib/gnome-settings-daemon/gsd-xsettings
      28     2885  /usr/lib/gvfs/gvfsd-trash --spawner :1.22 /org/gtk/gvfs/exec_spaw/0
      17     2392  /lib/systemd/systemd --user
```

### azure-secrets-in-repo
Runs through all the entries in the YAML file called `deploy/values.yaml` and tries to 
look up all the secrets using the default Azure Keyvault. Both values can be overridden.

#### Example
```
✦ ❯ azure-secrets-in-repo
Processing deploy/values.yaml using keyvault "tandn-qa-92a"

"elasticsearch.password" => "ef0e1844-6cdf11ee913b762385b5200a"
"elasticsearch.username" => "my-elastic-user"
"notificationPreferences.auth.clientId" => "0034c46a6ce011eea55f762385b5200a"
"notificationPreferences.auth.clientSecret" => 18e1bbda6ce011eebc9b762385b5200a
...
```
