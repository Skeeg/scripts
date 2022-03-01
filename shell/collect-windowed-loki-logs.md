# **General guidance for running these scripts:**
Ensure you have your local variables set and exported.
```bash
export LOKI_ADDR="" #https://{fqdn}:3100
export REPOPATH="" #Local file path
```

Running a 6 hour window collection would use this simplified script:

```bash
. $scripts/shell/collect-windowed-loki-logs.sh
```

# Initial workspace setup stuff

> You will need golang, and jq installed already.  This command may be a good friend to you on MacOS

```bash
brew install golang jq
```

## Downloading the Loki repo

```bash
git clone git@github.com:grafana/loki.git "$REPOPATH/loki"
cd $REPOPATH/loki
# build the binary:
make logcli
```
