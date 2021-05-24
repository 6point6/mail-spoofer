# Mail-Spoofer
A proof of concept email spoofing tool built on Docker. This tool abuses domains which have misconfigured or missing DMARC records to send spoofed messages. It uses these technologies – Caddy, GoPhish, Postfix, and Rspamd – including integration with Cloudflare API to automatically configure DNS records.

## How-to Run with Docker

### 1. Download files
Get the latest repository by `git clone https://github.com/6point6/mail-spoofer.git`. 

### 2. Change the `settings.env` file
You must change the following to match your own domain name and/or relay host. For the Return-Path address leave the username as “no-reply” and only change the domain name. Otherwise, the mail server may start to issuing thousands of bounce messages in your log files.

* You MUST change the root domain name:
    `DOMAIN=example.com`
* You MUST change the track subdomain for gophish:
    `TRACK_DOMAIN=click.example.com`
* You MUST change the RETURN-PATH address:
    `RETURN_PATH_ADDRESS=no-reply@example.com`
* You MUST change the Cloudflare API:
    `CLOUDFLARE_API=XXXXXXXXXXXXXX`
* You can change the DKIM selector or you can leave it as default:
    `DKIM_TAG=default`

### 3. Run Docker-compose
To start all the containers go to the repository folder and type: `docker-compose up`. 

To stop all containers type: `docker-compose down`.

### 4. Open Gophish web management 
The Gophish web management portal will be accessible on `https://example.com:3333`. You will be asked to log-in using the default Gophish credentials. 

With versions `0.9.0` and below the default username and password is `admin` and `gophish`. On newer versions of Gophish the password is automatically generated and can be retrieved by `docker logs {gophish-container-name}`.

## Building containers
If you are planning to build your own container to modify code or make further improvements to the tool you need update the `docker-compose.yml`. You need to replace the `image` argument with the `build` context, and also be sure to include the required directory. 

For example:
```yml
postfix:
    build:  
        context: ./postfix
```
You will need to do this for all services you have modifed.

#### Build and start containers
To build and start all the containers type: `docker-compose up -d --build`. The `-d` option will daemonize all containers.

#### Stop all containers
To stop all containers type: `docker-compose down -v`
