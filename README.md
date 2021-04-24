# RR vs. Symfony on HTTPS problem demo

This project demonstrates a problem when RR cannot detect https connection that was made to the reverse proxy behind which RR runs.

See [RR issue reported](https://github.com/spiral/roadrunner/issues/644) and [RR Symfony Bundle issue reported](https://github.com/Baldinof/roadrunner-bundle/issues/39).

*NOTE* make sure you have ports 80 and 443 available in your system before running this project, otherwise `nginx-proxy` will fail to bind.

## Local HTTPS certificates

In order to be able of use https locally, we need to install an HTTPS certificate
locally. [mkcert][mkcert] is a simple zero-config tool to make locally trusted
development certificates with any names you’d like.

* Use the [official documentation][mkcert-docs] to install `mkcert` on your
platform.

    After having `mkcert` installed we can create our local certificates. We can generate a wildcard one:

    ```bash
    # change to ./certs - the folder where nginx-proxy expects the certificates
    cd ./certs
  
    # generate the certificates
    mkcert -cert-file=home.test.crt -key-file=home.test.key *.home.test
    ```

    Where `home.test` is the domain, where you will place your sites.

* To make your system and browsers trust the newly generated certificates you
should run the following (you can skip this step, but then the connection will not be trusted):

    ```bash
    mkcert -install
    ```

Now you have your local HTTPS certificate.


## Domain resolution

You can use `dnsmasq` or other solutions to have a *.home.test to be resolved dynamically, but in this demo we'll just put the following record to `/etc/hosts`:

```
127.0.0.1 rr-problem.home.test
```

## Running the project

```
docker-compose up --build
```

## Accessing the project

Just follow the link: https://rr-problem.home.test

## Problem description

Although, the page itself loads without issues, all requests to the debug panel (and in general any _absolute_ link generated) will point to the `http` scheme instead of `https`.

In Firefox you'll see this in the console:

> Blocked loading mixed active content “http://rr-problem.home.test/_wdt/1fdd8c”

In Chrome you'll see this in the console:

> (index):116 Mixed Content: The page at 'https://rr-problem.home.test/' was loaded over HTTPS, but requested an insecure XMLHttpRequest endpoint 'http://rr-problem.home.test/_wdt/ec5cae'. This request has been blocked; the content must be served over HTTPS.

If I hack `HttpFoundationWorker::configureServer()` (in vendor/baldinof/roadrunner-bundle/src/RoadRunnerBridge/HttpFoundationWorker.php) by adding these two lines after parsing the url (that we got from RR), it will magically start working:

```php
        $components['scheme'] = 'https';
        $components['port'] = 443;
```

*NOTE*: Don't forget to run `docker-compose restart` to have the change in effect.

The problem exists because in the url that we got from RR we have this: `http://rr-problem.home.test` instead of this: `https://rr-problem.home.test` (i.e. http and not https)

[nginx-proxy-docs]: https://github.com/nginx-proxy/nginx-proxy#usage
[mkcert]: https://github.com/FiloSottile/mkcert
[mkcert-docs]: https://github.com/FiloSottile/mkcert#installation
