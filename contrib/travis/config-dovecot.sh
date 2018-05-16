#!/usr/bin/env bash

apt-get update
apt-get install dovecot-imapd

echo "#### RECONFIGURING DOVECOT for local virtual-user IMAP"
sed -i -e 's/^[!]include auth/#!include auth/' \
       -e 's/^#!include auth-passwdfile/!include auth-passwdfile/' \
       /etc/dovecot/conf.d/10-auth.conf || exit 1

echo "#### CONFIGURING DOVECOT for local user=user password=password uid=$SUDO_UID gid=$SUDO_GID"
echo "user:{plain}password:$SUDO_UID:$SUDO_GID::$PWD::userdb_mail=maildir:~/Maildir allow_nets=0.0.0.0/0" > /etc/dovecot/users
chown -c dovecot:dovecot /etc/dovecot/users || exit 1
chmod -c 0640 /etc/dovecot/users || exit 1

cat > /etc/dovecot/local.conf << EOF
ssl = yes
ssl_cert = <$PWD/ssl/server.crt
ssl_key  = <$PWD/ssl/server.key
EOF

for i in dovecot.conf local.conf conf.d/10-auth.conf; do
    sed -e "s,^,# $i # ," /etc/dovecot/$i
done
sed -e 's/^/# local.conf   # /' /etc/dovecot/local.conf || exit 1

echo "#### RESTARTING dovecot"
service dovecot restart || exit 1

sleep 1
netstat -ntlp | sed -e 's/^/# netstat # /' 
