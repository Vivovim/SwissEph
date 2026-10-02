# Moonrise / moonset JSON CGI

`MoonRise-Table.pl` is now the CGI. The previous command-line program is preserved
as `MoonRise-Table-cli.pl`. `index.php` now calls this CGI through its authenticated
server-side PHP helper; see [README.md](README.md) for the PHP deployment layout.

## Deploy

1. Edit the small `%CONFIG` block near the top of `MoonRise-Table.pl` with the
   MySQL settings for your `Zones` table. Use a database account with only SELECT
   access to `Zones`.
2. Run `openssl rand -hex 32` and put the resulting 64 lowercase hexadecimal
   characters into `shared_key`. Keep the same key in private, server-side PHP
   configuration at `/home/misfitx/astro/moonrise-config.php`. Never put it into JavaScript,
   browser storage, an HTML form, or a URL.
3. Copy only the CGI into your website's `cgi-bin`, enable CGI execution for it,
   and set its permissions to `755`. Keep the script and its parent directories
   writable only by the deployment owner. Do not publish the CLI copy or tests.
4. The shebang is `#!/usr/bin/perl -T`. Set the interpreter to the absolute path
   of the server's Perl if necessary, retaining `-T`. That same Perl installation
   needs `DBI`, `DBD::mysql`, and `SwissEph`. Other modules used here are core Perl
   modules. Check with `perl -T -c MoonRise-Table.pl` using that interpreter.
5. Serve the CGI over HTTPS. The default origin is `https://astro.ctopher.me`.
   If TLS terminates at a reverse proxy, configure your trusted web server to
   provide the CGI `HTTPS=on` value. The script does not trust a client-supplied
   forwarded-protocol header. Keep `require_https` enabled for public access.

Perl connects to MySQL through DBI and DBD::mysql; `mysqli` is a PHP extension.
The PHP files continue to use `mysqli`.

## Request and response

Send a POST to `https://astro.ctopher.me/cgi-bin/MoonRise-Table.pl` with:

```text
Content-Type: application/json
X-Moonrise-Key: <the server-only shared key>
```

```json
{"id": 123}
```

The ID may also be a string of positive decimal digits. Nothing else is accepted
in the JSON object. The maximum ID is 4294967295, matching the table's unsigned
integer key. The city, coordinates, and timezone come entirely from MySQL.
The CGI does not accept dates, coordinates, paths, or timezones from a client.

Example response shape (the ID below is illustrative):

```json
{
  "id": 123,
  "city": "Phoenix",
  "latitude": 33.4484,
  "longitude": -112.074,
  "timezone": "America/Phoenix",
  "date": "2026-10-01",
  "moonrise": "2026-10-01T21:42:52-07:00",
  "moonset": "2026-10-01T11:59:13-07:00"
}
```

Calculations cover **today in the selected city's timezone**, from one local
midnight to the next, including days with daylight-saving changes. Times are
ISO 8601 strings with the local UTC offset. A moonset can occur before the
moonrise on the same date. If an event does not occur on that local date, its
field is JSON `null`; this is a successful calculation, not a server error.

The calculation uses Swiss Ephemeris, sea-level elevation, estimated atmospheric
pressure, 15 degrees C, the upper limb, and a level horizon. The empty
`ephemeris_path` selects Moshier as in the original script. To use ephemeris data
files, configure their absolute directory on the server. Terrain and actual
weather/elevation can affect observed times.

Errors return JSON such as `{"error":"City ID was not found."}` with an HTTP
status: 400 for invalid input, 403 for access denied, 404 for an unknown city,
405 for the wrong method, 411 for missing Content-Length, 413 for an oversized
body, 415 for the wrong content type, or 500 for a server/configuration failure.
Detailed failures go to the server error log and are not returned to callers.

## Restrict calls to your site

**The integration is browser → your PHP server → CGI.** The PHP relay
adds `X-Moonrise-Key` privately. A direct JavaScript call to this CGI is
deliberately insufficient because a browser must never receive that secret.

The CGI always requires the key. If an Origin header is present it must exactly
match `https://astro.ctopher.me`; cross-site Fetch Metadata requests are also
rejected. No CORS access is enabled. Origin/Referer checks and CORS alone cannot
authenticate command-line callers, bots, or other servers, which can supply
their own headers. The shared key provides authentication for the PHP relay.

If PHP and CGI are on the same server, restricting the CGI to loopback requests
at Apache provides an additional barrier. For Apache 2.4, the relevant virtual
host configuration, or a permitted `.htaccess` inside `cgi-bin`, can include:

```apache
<Files "MoonRise-Table.pl">
    Require local
    LimitRequestBody 1024
</Files>
```

Only use that rule when the PHP relay connects locally; a request via your public
IP may be denied. With separate servers, allow only the PHP server's fixed IP
at the web server/firewall instead. Keep the shared key required either way.
Apply rate limits and connection/read timeouts at the web server as well; the
CGI's 1024-byte body limit and 15-second alarm do not impose a global request
rate limit. The public PHP page should also have web-server rate limits; a public
PHP page remains usable by bots even when the CGI itself is private.

References: [Perl taint mode](https://perldoc.perl.org/perlsec),
[OWASP API security](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html),
[Apache local access rules](https://httpd.apache.org/docs/2.4/mod/mod_authz_host.html),
and [Swiss Ephemeris rise/set behavior](https://www.astro.com/swisseph/swephprg.htm).

## Checks

If PHP logs `HTTP 200; type text/x-perl` with a response approximately the size
of `MoonRise-Table.pl`, Apache is serving the source instead of executing it.
Remove the credential-bearing script from public access immediately and treat
the database password and shared key as exposed. Rotate the database password
wherever that account is configured, and replace the shared key in both the CGI
and private PHP configuration.

Use the credential-free `cgi-probe.pl` to verify execution before redeploying the
CGI with new credentials. Upload it to `cgi-bin`, set permissions to `755`, and
request `/cgi-bin/cgi-probe.pl`. The response must be `application/json` containing
`{"cgi_executed":true}`, rather than the Perl source. Remove the probe after use.

If your host allows directory-level CGI configuration, merge the directives in
`apache-cgi.htaccess.example` into `/home/misfitx/astro/public_html/cgi-bin/.htaccess`.
Do not overwrite other existing rules. The web server must have `mod_cgid` or
`mod_cgi` enabled and permit these directives. Otherwise ask the hosting provider
to enable CGI execution for the `astro.ctopher.me` virtual host. Naming a directory
`cgi-bin`, changing file permissions, or assigning a Perl MIME type alone does
not enable execution. See [Apache's CGI tutorial](https://httpd.apache.org/docs/2.4/howto/cgi.html).

```sh
/usr/bin/perl -T -c MoonRise-Table.pl
/usr/bin/perl -T tests/moonrise_cgi.t
```

The tests use fixture database records rather than connecting to your MySQL
server. Astronomy tests use the actual SwissEph module when installed, and are
explicitly skipped otherwise.
