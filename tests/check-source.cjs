const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const frontend = read('luci/view/torrserver/overview.js');
const translations = read('luci/i18n/ru.po');
const messages = new Set([...frontend.matchAll(/_\('([^']*)'\)/g)].map(match => match[1]));
const translated = new Map([...translations.matchAll(/^msgid (".*")\r?\nmsgstr (".*")$/gm)]
	.map(match => [JSON.parse(match[1]), JSON.parse(match[2])]));
for (const message of messages) {
	assert.ok(translated.get(message), `Missing Russian translation: ${message}`);
}

const serviceVersion = read('packages/torrserver/Makefile').match(/^PKG_VERSION:=(.+)$/m)[1];
const build = read('scripts/build-upstream.sh');
assert.ok(build.includes(`server/version.Version=MatriX.${serviceVersion}`), 'Server version and build disagree');
const upstreamCommit = build.match(/^expected_commit=([a-f0-9]{40})$/m)[1];
assert.ok(read('.github/workflows/build.yml').includes(`ref: ${upstreamCommit}`), 'Workflow checkout and build provenance disagree');
for (const file of ['luci/menu.d/luci-app-torrserver.json', 'luci/acl.d/luci-app-torrserver.json']) {
	JSON.parse(read(file));
}
console.log(`PASS: ${messages.size} Russian translations, upstream version/commit consistency, LuCI JSON`);
