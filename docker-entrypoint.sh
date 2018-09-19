#!/bin/bash

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

ln -sf /etc/httpd/certs/cert.crt /etc/pki/tls/certs/localhost.crt
ln -sf /etc/httpd/certs/cert.key /etc/pki/tls/private/localhost.key

# server names and admin
export SERVER_NAME="${SERVER_NAME:-localhost}"
sed -i "s/ServerName localhost/ServerName ${SERVER_NAME}/g" /etc/httpd/conf/httpd.conf
sed -i "s/# ServerName localhost/ServerName ${SERVER_NAME}/g" /etc/httpd/conf.d/explgbk.conf
export SERVER_ADMIN="${SERVER_ADMIN:-admin@localhost.com}"
sed -i "s/ServerAdmin admin@localhost.com/ServerAdmin ${SERVER_ADMIN}/g" /etc/httpd/conf/httpd.conf
sed -i "s/# ServerAdmin admin@localhost.com/ServerAdmin ${SERVER_ADMIN}/g" /etc/httpd/conf.d/explgbk.conf

# proxy settings
export PROXY_HOST="${PROXY_HOST:-localhost}"
export PROXY_PORT="${PROXY_PORT:-8000}"
export PROXY_WS_PORT="${PROXY_WS_PORT:-5000}"
sed -i "s#http://explgbk:8000/#http://${PROXY_HOST}:${PROXY_PORT}/#g" /etc/httpd/conf.d/explgbk.conf
sed -i "s#ws://explgbk:5000/#ws://${PROXY_HOST}:${PROXY_WS_PORT}/#g" /etc/httpd/conf.d/explgbk.conf

# redirect
export HTTPS_REDIRECT="${HTTPS_REDIRECT:-https://localhost/}"
sed -i "s#Redirect permanent / https://localhost/#Redirect permanent / ${HTTPS_REDIRECT}/#g" /etc/httpd/conf.d/explgbk.conf


# webauth
export WEBAUTH_LOGIN_URL="${WEBAUTH_LOGIN_URL:-https://webauth1.slac.stanford.edu/login/}"
sed -i "s#WebAuthLoginURL \"WEBAUTH_LOGIN_URL\"#WebAuthLoginURL \"${WEBAUTH_LOGIN_URL}\"#g" /etc/httpd/conf.d/webauth.conf
export WEBAUTH_WEBKDC_URL="${WEBAUTH_WEBKDC_URL:-https://webauth1.slac.stanford.edu/webkdc-service/}"
sed -i "s#WebAuthWebKdcURL \"WEBAUTH_WEBKDC_URL\"#WebAuthWebKdcURL \"${WEBAUTH_WEBKDC_URL}\"#g" /etc/httpd/conf.d/webauth.conf

if [[ ! -z "${REQUIRE_VALID_USER}" ]]; then
  sed -i "s/# require valid-user/ require valid-user/g" /etc/httpd/conf.d/explgbk.conf
fi

if [[ ! -z "${USE_WEBAUTH}" ]]; then
  sed -i "s/# WebAuthExtraRedirect on/WebAuthExtraRedirect on/g" /etc/httpd/conf.d/explgbk.conf
  sed -i "s/# AuthType WebAuth/AuthType WebAuth/g" /etc/httpd/conf.d/explgbk.conf
fi

if [[ ! -z "${GENERATE_DUMMY_CERTS}" ]]; then
  
  echo "******** GENERATING DUMMY SSL CERTS ********"
  if [[ ! -s /etc/httpd/certs/cert.crt && ! -s /etc/httpd/certs/cert.key  ]]; then
    openssl req -x509 -nodes -days 2 -newkey rsa:2048 -subj '/CN=localhost' -keyout /etc/httpd/certs/cert.key -out /etc/httpd/certs/cert.crt
  else
    echo "ERROR: certificates are not zero length; not overwriting - are you sure you want to generate dummy certificates?"
    exit 1
  fi
  
fi


# fakeauth stuff
if [[ ! -z "${FAKE_AUTH}" ]]; then
  export FAKE_AUTH_USER="${FAKE_AUTH_USER:-someone}"
  echo "******** SETTING UP FAKE AUTHENTICATION AS ${FAKE_AUTH_USER} ********"

  sed -i "s/\#SetEnv REMOTE_USER someone/SetEnv REMOTE_USER ${FAKE_AUTH_USER}/g" /etc/httpd/conf.d/explgbk.conf
  sed -i "s/\#SetEnv WEBAUTH_USER someone/SetEnv WEBAUTH_USER ${FAKE_AUTH_USER}/g" /etc/httpd/conf.d/explgbk.conf
  sed -i "s/\#SetEnv AUTH_TYPE WebAuth/SetEnv AUTH_TYPE WebAuth/g" /etc/httpd/conf.d/explgbk.conf  
  export FAKE_AUTH_START=`date +%s`
  export FAKE_AUTH_END=`expr $PROXY_EPOCH + 500000000`
  sed -i "s/\#SetEnv WEBAUTH_TOKEN_CREATION 1000000000/SetEnv WEBAUTH_TOKEN_CREATION ${FAKE_AUTH_START}/g" /etc/httpd/conf.d/explgbk.conf
  sed -i "s/\#SetEnv WEBAUTH_TOKEN_EXPIRATION 2000000000/SetEnv WEBAUTH_TOKEN_EXPIRATION ${FAKE_AUTH_END}/g" /etc/httpd/conf.d/explgbk.conf
  sed -i "s/\#SetEnv WEBAUTH_FACTORS_INITIAL p/SetEnv WEBAUTH_FACTORS_INITIAL p/g" /etc/httpd/conf.d/explgbk.conf  
  sed -i "s/\#SetEnv WEBAUTH_FACTORS_SESSION p/SetEnv WEBAUTH_FACTORS_SESSION p/g" /etc/httpd/conf.d/explgbk.conf  
fi

/usr/sbin/apachectl -V

exec /usr/sbin/apachectl -DFOREGROUND
