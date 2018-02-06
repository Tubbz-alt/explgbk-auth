# Purpose

This image provides httpd and webauth built into a single image to enable a frontend for a backend http service. It uses mod_proxy to facilitate a https layer for any web app.

This also provides some environment flags that allow quick user switching (FAKE_USER) for development purposes. It can also generate some dummy certs for the same purpose.

# Build

To use this image, you can build it locally using:

    git clone git@github.com:slaclab/explgbk-auth.git
    cd explgbk-auth
    docker build -t slaclab/logbook-auth:latest .


# Use

You probably want to have this as part of a docker swarm or k8s. Useful environments are:

This will pass WEBAUTH_USER and REMOTE_USER set to FAKE_AUTH_USER

    - FAKE_AUTH=1
    - FAKE_AUTH_USER=ytl

This will set the destination host to pass traffic to

    - PROXY_HOST=explgbk


# Certificates

This will create some dummy certs:

    - GENERATE_DUMMY_CERTS=yes

In order to utilise your own certs, you should bind mount the following:

    volumes:
      - ${HOME}/certs/my.crt:/etc/httpd/certs/cert.crt
      - ${HOME}/certs/my.key:/etc/httpd/certs/cert.key
      - ${HOME}/certs/keytab_webauth:/etc/httpd/certs/keytab_webauth

