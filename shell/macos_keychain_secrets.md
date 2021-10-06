# Using the MacOS keychain for secrets
prompt for credential and store it in a variable:

```
read -s SECRET
```

Store it into the keychain with a specific entry ID.  (`$LOGNAME` is for the current user account)
```bash
entryid="special-identifier"
security add-generic-password -s $entryid -w `echo $SECRET` -a $LOGNAME
```

Recall the keychain secret into the current shell
```bash
entryid="special-identifier"
SECRET=$(security find-generic-password -w -a $LOGNAME -s $entryid)
```

