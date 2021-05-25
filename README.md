# Mail-Spoofer
One of the biggest mistakes the cybersecurity industry has made is believing SPF, DKIM, and ARC prevent email contents spoofing.

Mail Spoofer is a Proof-of-Concept email spoofing tool built on Docker. We created it to target domains with missing or misconfigured DMARC records.

The tool massively reduces the effort of setting up PTR, SPF, DKIM and ARC infrastructure. Our guiding principle is to reduce the complexity of spoofing attacks, educate the cybersecurity industry and force organizations into universally applying DMARC records.

Mail Spoofer uses these technologies — Caddy, GoPhish, Postfix, and Rspamd —including Cloudflare API integration to configure DNS records automatically.

For more detailed help, how-to guides and materials check out the [Mail Spoofer Wiki](https://github.com/6point6/mail-spoofer/wiki).

* For guidance on checking and fixing your domain, please read this article. **UPDATE**
* For an overview of email, SMTP and security technologies, please read this article. **UPDATE**
* Acess our [Mail Spoofer](https://github.com/6point6/mail-spoofer) tool and how-to guides on the [Mail Spoofer Wiki](https://github.com/6point6/mail-spoofer/wiki).
* For help identifying vulnerable domains, check out our tool [DMARC Checker](https://github.com/6point6/dmarc_checker) and its [Wiki](https://github.com/6point6/dmarc_checker/wiki).

## How-to Run with Docker

### 1. Download files
Get the latest repository by `git clone https://github.com/6point6/mail-spoofer.git`. 

### 2. Change the `settings.env` file
You must change the following options to match your domain name and/or relay host.

For the Return-Path address, leave the username as "no-reply" and only change the domain name. Otherwise, the mail server may start to issue thousands of bounce messages and fill up your log files.

* You MUST change the root domain name: DOMAIN=example.com
* You MUST change the tracking subdomain for GoPhish: TRACK_DOMAIN=click.example.com
* You MUST change the Return-Path address: RETURN_PATH_ADDRESS=no-reply@example.com
* You MUST change the Cloudflare API for editing DNS: CLOUDFLARE_API_TOKEN={Cloudflare_API_Key}

If you are using a third-party (SendGrid) then change.
* Add your SendGrid API Key to: SENDGRID_API_KEY={Sendgrid_API_Key}

### 3. Run Docker-compose
To start all the containers, go to the repository folder and type: `docker-compose up`. 

To stop all containers, type `docker-compose down`.

### 4. Open Gophish web management 
The Gophish web management portal will be accessible on `https://example.com:3333`. You need to log in using the default Gophish credentials. 

With versions `0.9.0` and below the default username and password is `admin` and `gophish`. On newer versions of Gophish, the password is automatically generated and can be retrieved by `docker logs {gophish-container-name}`.

## Building containers
If you plan to build your containers to modify code or make further improvements to the tool, you need to update the `docker-compose.yml`. You need to replace the `image` argument with the `build` context, and also be sure to include the required directory. 

For example:
```yml
postfix:
    build:  
        context: ./postfix
```
You will need to do this for all services you have modified.

#### Build and start containers
To build and start all the containers, type `docker-compose up -d --build`. The `-d' option will daemonize all containers.

#### Stop all containers
To stop all containers type `docker-compose down -v`
