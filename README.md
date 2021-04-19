# Mail-Spoofer
A Phishing set-up built on Docker (Caddy + GoPhish + Postfix + Rspamd)

## How-to Deploy with Docker

### 1. Download files
Get the latest repository by `git clone https://github.com/6point6/mail-spoofer.git`. 

### 2. Change the `settings.env` file
You must change the following to match your own domain name and/or relay host.

* You MUST change the root domain name:
    `DOMAIN=example.com`

* You MUST change the RETURN-PATH address also known as Mail-From address:
    `RETURN_PATH_ADDRESS=no-reply@example.com`

* You MUST change the Cloudflare API:
    `CLOUDFLARE_API=XXXXXXXXXXXXXX`

* You can change the DKIM selector or you can leave it as default:
    `DKIM_TAG=default`

### 3. Run Docker-compose
To start all the containers simply go to the repository and type: `docker-compose up`