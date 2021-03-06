#!/bin/bash

set -x

. /etc/mason.conf

REPORT_PATH=/var/mason/report.html
SERVER_PATH=/srv/mason
SERVER_REPORT_PATH="$SERVER_PATH/index.html"

sed_escape() {
    printf "%s\n" "$1" | sed -e 's/\W/\\&/g'
}

create_report() {
cat > $REPORT_PATH <<'EOF'
<html>
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="60">
<style>
html, body {
	margin: 0;
	padding: 0;
}
p.branding {
	background: black;
	color: #fff;
	padding: 0.4em;
	margin: 0;
	font-weight: bold;
}
h1 {
	background: #225588;
	color: white;
	margin: 0;
	padding: 0.6em;
}
table {
	width: 90%;
	margin: 1em auto 6em auto;
	border: 1px solid black;
	border-spacing: 0;
}
table tr.headings {
	background: #555;
	color: white;
}
table tr.pass {
	background: #aaffaa;
}
table tr.pass:hover {
	background: #bbffbb;
}
table tr.fail {
	background: #ffaaaa;
}
table tr.fail:hover {
	background: #ffbbbb;
}
table tr.nonet {
	background: #ffdd99;
}
table tr.nonet:hover {
	background: #ffeeaa;
}
table tr.progress {
	background: #00CCFF;
}
table tr.progress:hover {
	background: #91E9FF;
}
table tr.headings th {
	font-weight: bold;
	text-align: left;
	padding: 3px 2px;
}
table td {
	padding: 2px;
}
td.result {
	font-weight: bold;
	text-transform: uppercase;
}
td.result a {
	text-decoration: none;
}
td.result a:before {
	content: "➫ ";
}
tr.pass td.result a {
	color: #252;
}
tr.pass td.result a:hover {
	color: #373;
}
tr.fail td.result a {
	color: #622;
}
tr.fail td.result a:hover {
	color: #933;
}
tr.nonet td.result a {
	color: #641;
}
tr.nonet td.result a:hover {
	color: #962;
}
tr.progress td.result a {
	color: #000066;
}
tr.progress td.result a:hover {
	color: #0000CC;
}
td.ref {
	font-family: monospace;
}
td.ref a {
	color: #333;
}
td.ref a:hover {
	color: #555;
}
table tr.pass td, table tr.fail td {
	border-top: solid white 1px;
}
p {
	margin: 1.3em;
}
code {
	padding: 0.3em 0.5em;
	background: #eee;
	border: 1px solid #bbb;
	border-radius: 1em;
}
#footer {
	margin: 0;
	background: #aaa;
	color: #222;
	border-top: #888 1px solid;
	font-size: 80%;
	padding: 0;
	position: fixed;
	bottom: 0;
	width: 100%;
	display: table;
}
#footer p {
	padding: 1.3em;
	display: table-cell;
}
#footer p code {
	font-size: 110%;
}
#footer p.about {
	text-align: right;
}
</style>
</head>
<body>
<p class="branding">Mason</p>
<h1>Baserock: Continuous Delivery</h1>
<p>Build log of changes to <code>BRANCH</code> from <code>TROVE</code>.  Most recent first.</p>
<table>
<tr class="headings">
	<th>Started</th>
	<th>Ref</th>
	<th>Duration</th>
	<th>Result</th>
</tr>
<!--INSERTION POINT-->
</table>
<div id="footer">
<p>Last checked for updates at: <code>....-..-.. ..:..:..</code></p>
<p class="about">Generated by Mason | Powered by Baserock</p>
</div>
</body>
</html>
EOF

    sed -i 's/BRANCH/'"$(sed_escape "$1")"'/' $REPORT_PATH
    sed -i 's/TROVE/'"$(sed_escape "$2")"'/' $REPORT_PATH
}

update_report() {
    # Give function params sensible names
    build_start_time="$1"
    build_trove_host="$2"
    build_ref="$3"
    build_sha1="$4"
    build_duration="$5"
    build_result="$6"
    report_path="$7"
    build_log="$8"

    # Generate template if report file is not there
    if [ ! -f $REPORT_PATH ]; then
        create_report $build_ref $build_trove_host
    fi

    # Build table row for insertion into report file
    if [ "$build_result" = nonet ]; then
        msg='<tr class="'"${build_result}"'"><td>'"${build_start_time}"'</td><td class="ref">Failed to contact '"${build_trove_host}"'</a></td><td>'"${build_duration}s"'</td><td class="result"><a href="'"${build_log}"'">'"${build_result}"'</a></td></tr>'
    else
        msg='<tr class="'"${build_result}"'"><td>'"${build_start_time}"'</td><td class="ref"><a href="http://'"${build_trove_host}"'/cgi-bin/cgit.cgi/baserock/baserock/definitions.git/commit/?h='"${build_ref}"'&id='"${build_sha1}"'">'"${build_sha1}"'</a></td><td>'"${build_duration}s"'</td><td class="result"><a href="'"${build_log}"'">'"${build_result}"'</a></td></tr>'
    fi

    # Insert report line, newest at top
    sed -i 's/<!--INSERTION POINT-->/<!--INSERTION POINT-->\n'"$(sed_escape "$msg")"'/' $report_path
}

update_report_time() {
    # Give function params sensible names
    build_start_time="$1"

    # If the report file exists, update the last-checked-for-updates time
    if [ -f $REPORT_PATH ]; then
        sed -i 's/<code>....-..-.. ..:..:..<\/code>/<code>'"$(sed_escape "$build_start_time")"'<\/code>/' $REPORT_PATH
    fi
}

START_TIME=`date +%Y-%m-%d\ %T`

update_report_time "$START_TIME"
cp "$REPORT_PATH" "$SERVER_PATH/index.html"

logfile="$(mktemp)"

#Update current.log symlink to point to the current build log
ln -sf "$logfile" "$SERVER_PATH"/current.log

#Copy current server report, to restore when result is "skip"
cp "$SERVER_REPORT_PATH" "$SERVER_REPORT_PATH".bak

update_report "$START_TIME" \
              "$UPSTREAM_TROVE_ADDRESS" \
              "$DEFINITIONS_REF" \
              "" \
              " - " \
              "progress" \
              "$SERVER_REPORT_PATH" \
              "current.log"


/usr/lib/mason/mason.sh 2>&1 | tee "$logfile"
case "${PIPESTATUS[0]}" in
0)
    RESULT=pass
    ;;
33)
    RESULT=skip
    ;;
42)
    RESULT=nonet
    ;;
*)
    RESULT=fail
    ;;
esac

# TODO: Update page with last executed time
if [ "$RESULT" = skip ]; then
    # Restore copied server report, otherwise the 'progress' row will
    # be still present with a broken link after we remove the $logfile
    mv "$SERVER_REPORT_PATH".bak "$SERVER_REPORT_PATH"

    rm "$logfile"
    exit 0
fi

DURATION=$(( $(date +%s) - $(date --date="$START_TIME" +%s) ))
SHA1="$(cd "/ws/mason-definitions-$DEFINITIONS_REF" && git rev-parse HEAD)"
BUILD_LOG="log/${SHA1}--${START_TIME}.log"

update_report "$START_TIME" \
              "$UPSTREAM_TROVE_ADDRESS" \
              "$DEFINITIONS_REF" \
              "$SHA1" \
              "$DURATION" \
              "$RESULT" \
              "$REPORT_PATH" \
              "$BUILD_LOG"


#
# Copy report into server directory
#

cp "$REPORT_PATH" "$SERVER_REPORT_PATH"
mkdir "$SERVER_PATH/log"
mv "$logfile" "$SERVER_PATH/$BUILD_LOG"

# Cleanup

mkdir -p /srv/distbuild/remove
find /srv/distbuild/ -not \( -name "remove" -o -name "trees.cache.pickle" \) -mindepth 1 -maxdepth 1 -exec  mv '{}' /srv/distbuild/remove \;
find /srv/distbuild/remove -delete
