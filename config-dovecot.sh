#!/usr/bin/env bash

apt-get install dovecot-imapd

echo "#### RECONFIGURING DOVECOT for local virtual-user IMAP"
sed -i -e 's/^[!]include auth/#!include auth/' \
       -e 's/^#!include auth-passwdfile/!include auth-passwdfile/' \
       /etc/dovecot/conf.d/10-auth.conf

echo "#### CONFIGURING DOVECOT for local user=user password=password uid=$SUDO_UID gid=$SUDO_GID"
echo "user:{plain}password:$SUDO_UID:$SUDO_GID::$PWD::userdb_mail=maildir:~/Maildir allow_nets=0.0.0.0/0" > /etc/dovecot/users
chown -c dovecot:dovecot /etc/dovecot/users
chmod -c 0640 /etc/dovecot/users

cat > /etc/dovecot/local.conf << EOF
ssl = yes
ssl_cert = <$PWD/ssl/server.crt
ssl_key  = <$PWD/ssl/server.key
EOF

sed -e 's/^/# dovecot.conf # /' /etc/dovecot/dovecot.conf
sed -e 's/^/# local.conf   # /' /etc/dovecot/local.conf

netstat -ntlp | grep dovecot | sed -e 's/^/# netstat # /'

echo "#### RESTARTING dovecot"
service dovecot restart
