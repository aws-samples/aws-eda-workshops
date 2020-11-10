#!/bin/bash

echo "dn: uid=<username>,ou=People,dc=soca,dc=local
changetype: modify
replace: loginShell
loginShell: /bin/tcsh " > /root/modify_user_shell.ldif

echo "Modify the username in /root/modify_user_shell.ldif"
echo "Then run this command: ldapmodify -x -D cn=admin,dc=soca,dc=local -y /root/OpenLdapAdminPassword.txt -f /root/modify_user_shell.ldif"
