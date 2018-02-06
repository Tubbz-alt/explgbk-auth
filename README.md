docker build -t slaclab/logbook-fakeauth:latest .

You will need some certs and the keytab for webauth in order to use this image

docker run \
  --mount type=bind,source=conf/httpd/certs/cryoem-logbook.crt,target=/etc/httpd/certs/cryoem-logbook.crt \
  --mount type=bind,source=conf/httpd/certs/cryoem-logbook.key,target=/etc/httpd/certs/cryoem-logbook.key \
  --mount type=bind,source=conf/httpd/certs/keytab_webauth.cryoem-logbook,target=/etc/httpd/certs/keytab_webauth.cryoem-logbook \
  -e FAKE_USER=ytl \
  slaclab/logbook-fakeauth:latest