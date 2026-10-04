#!/usr/bin/env bash
# Set a launcher shared pref while the app is stopped. Usage: pref.sh bool|float NAME VALUE
# e.g. pref.sh bool dual_screen_enabled false; pref.sh float "inst:Project Zomboid:render_scale" 0.5
set -e
source "$(dirname "$0")/env.sh"
type="$1"; name="$2"; value="$3"
FILE=shared_prefs/com.zomdroid.PREFS.xml
"$ADB" shell am force-stop "$PKG"
line="<$type name=\"$name\" value=\"$value\" />"
"$ADB" exec-out run-as "$PKG" cat "$FILE" > "$OUT_DIR/logs/prefs.xml"
python - "$(cygpath -w "$OUT_DIR/logs/prefs.xml")" "$type" "$name" "$line" <<'PY'
import re, sys
path, typ, name, line = sys.argv[1:]
s = open(path, encoding='utf-8').read()
pat = re.compile(r'<%s name="%s" value="[^"]*" />' % (typ, re.escape(name)))
s = pat.sub(line, s) if pat.search(s) else s.replace('</map>', '    ' + line + '\n</map>')
open(path, 'w', encoding='utf-8', newline='\n').write(s)
PY
"$ADB" push "$(cygpath -w "$OUT_DIR/logs/prefs.xml")" /data/local/tmp/ds-prefs.xml >/dev/null
"$ADB" shell "run-as $PKG cp /data/local/tmp/ds-prefs.xml $FILE" && "$ADB" shell rm /data/local/tmp/ds-prefs.xml
"$ADB" exec-out run-as "$PKG" cat "$FILE" | grep -F "name=\"$name\""
