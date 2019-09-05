#!/usr/bin/env node
/*
 * Rename kebab-case files into PascalCase files and update references
 *
 * Basic working:
 * 1. Find all kebab case files
 * 2. Rename them
 * 3. Use the `git grep` to get all filenames with indexed hits of the old file name
 * 4. Loop through the hits and update
 */

const argv = require('yargs').argv;
const {isEmpty, flowRight} = require('lodash');
const {promisify} = require('util');
const fs = require('fs');
const cp = require('child_process');
const {basename} = require('path');
const exec = promisify(cp.exec);
const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);
const moveFile = promisify(fs.rename);
const debug = require('debug')('info');
const usage = `
USAGE: rename-kebab --dir src --dir test --dir some-other
  Will rename all kebab-case files to PascalCase and update references in the mentioned directories
`;

let dirs = '';
if (isEmpty(argv.dir)) {
  // eslint-disable-next-line no-console
  console.error(usage);
  process.exit(1);
}
if (!Array.isArray(argv.dir)) {
  dirs = [argv.dir];
} else {
  dirs = argv.dir;
}

async function main() {
  const kebabs = await execAndParseList(`find ${dirs.join(' ')} -name '*-*.js' -type f `);
  const pascalify = flowRight(
    fromKebabToCamel,
    fromCamelToPascal
  );

  for (const fullKebabPath of kebabs) {
    const oldNameWithoutExtension = basename(fullKebabPath, '.js');
    const newName = pascalify(basename(fullKebabPath));
    const newNameWithoutExtension = basename(newName, '.js');
    const filesWithReferences = await execAndParseList(`grep -r -l ${oldNameWithoutExtension} ${dirs.join(' ')}`);

    debug(`${oldNameWithoutExtension} is referenced by:\n${filesWithReferences.join('\n')}`);

    await moveFile(fullKebabPath, fullKebabPath.replace(oldNameWithoutExtension, newNameWithoutExtension));
    for (const file of filesWithReferences) {
      const buffer = await readFile(file);
      const newFileContent = buffer
        .toString()
        .replace(new RegExp(oldNameWithoutExtension, 'm'), newNameWithoutExtension);
      await writeFile(file, newFileContent);
    }
  }
}

function fromCamelToPascal(camel) {
  return camel.replace(/^(.)/, (_, char) => char.toUpperCase());
}

function fromKebabToCamel(kebab) {
  return kebab.replace(/\b-([a-z])/g, (_, char) => char.toUpperCase());
}

async function execAndParseList(cmd) {
  const tmp = await exec(cmd).catch(_ => ({stdout: ''}));
  return tmp.stdout.split('\n').filter(e => e);
}

main();