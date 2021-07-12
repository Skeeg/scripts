#!/bin/bash
username="administrator"

#Report only on logged in sessions:
sudo salt -G 'os:Windows' cmd.run shell=powershell "\$quserResult = quser; \$quserRegex = \$quserResult | ForEach-Object -Process { \$_ -replace '\s{2,}',',' }; \$quserObject = \$quserRegex | ConvertFrom-Csv; \$userSession = \$quserObject | Where-Object -FilterScript { \$_.USERNAME -eq \"$username\" }; \$userSession;"
# Log them all off
# sudo salt -G 'os:Windows' cmd.run shell=powershell "\$quserResult = quser; \$quserRegex = \$quserResult | ForEach-Object -Process { \$_ -replace '\s{2,}',',' }; \$quserObject = \$quserRegex | ConvertFrom-Csv; \$userSession = \$quserObject | Where-Object -FilterScript { \$_.USERNAME -eq \"$username\" }; \$userSession; foreach (\$a in \$userSession) {logoff \$a.SESSIONNAME /V}"
