Grafana docker image for Raspberry Pi
---
### RUN

```bash
docker run -d --name=grafana -p 3000:3000 -v $PWD/grafana:/var/lib/grafana yowidin/grafana-rpi
```

