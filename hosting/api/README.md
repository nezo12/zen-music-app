# Zen Music API

Upload the whole `api` folder to:

```text
public_html/zen-music/api
```

Then the endpoints will be:

```text
https://shit.com.pl/zen-music/api/register.php
https://shit.com.pl/zen-music/api/login.php
https://shit.com.pl/zen-music/api/me.php
https://shit.com.pl/zen-music/api/logout.php
https://shit.com.pl/zen-music/api/setup_check.php
```

Setup:

1. Create a MySQL database in your hosting panel.
2. Import `database.sql` into that database.
3. Edit `config.php` and set `DB_NAME`, `DB_USER`, `DB_PASS`.
4. Register from the app.

Open `setup_check.php` in the browser after uploading. It should return `"ok": true`.

The register endpoint allows max 2 accounts per IP address.
