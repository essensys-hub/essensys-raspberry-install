#!/bin/bash
# Test de setup-light-names.sh (sans root, dans un repertoire temporaire).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
fail() { echo "ECHEC: $1" >&2; exit 1; }

printf 'server:\n  port: 7070' > "$T/config.yaml"   # sans saut de ligne final
"$HERE/setup-light-names.sh" "$T/config.yaml" "$T/names" "$(id -un)" >/dev/null
[ -d "$T/names" ] || fail "repertoire non cree"
[ "$(stat -f %Lp "$T/names" 2>/dev/null || stat -c %a "$T/names")" = "750" ] || fail "mode 0750 attendu"
grep -q "^light_names:$" "$T/config.yaml" || fail "cle light_names absente"
grep -q "path: \"$T/names/light-names.json\"" "$T/config.yaml" || fail "path incorrect"
grep -q "^  port: 7070$" "$T/config.yaml" || fail "contenu existant altere"

cp "$T/config.yaml" "$T/avant.yaml"
"$HERE/setup-light-names.sh" "$T/config.yaml" "$T/names" "$(id -un)" >/dev/null
cmp -s "$T/config.yaml" "$T/avant.yaml" || fail "second passage non idempotent"

# Bloc deja gere par Ansible : rien n'est ajoute.
printf '# BEGIN ANSIBLE MANAGED LIGHT NAMES\nlight_names:\n  path: "/var/lib/essensys/names/light-names.json"\n# END ANSIBLE MANAGED LIGHT NAMES\n' > "$T/ans.yaml"
cp "$T/ans.yaml" "$T/ans.avant"
"$HERE/setup-light-names.sh" "$T/ans.yaml" "$T/n2" "$(id -un)" >/dev/null
cmp -s "$T/ans.yaml" "$T/ans.avant" || fail "bloc Ansible modifie"

# config.yaml absent : pas d'erreur.
"$HERE/setup-light-names.sh" "$T/absent.yaml" "$T/n3" "$(id -un)" >/dev/null 2>&1 || fail "config absente"
echo "OK : setup-light-names.sh"
