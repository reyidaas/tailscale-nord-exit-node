COMPOSE := docker compose --env-file .env -f compose.yml

.PHONY: init config up down restart logs ps gluetun-logs tailscale-logs ip shell

init:
	@test -f .env || cp .env.example .env
	@chmod +x scripts/route-fix.sh
	@echo "Created .env if missing. Edit it before running: make up"

config:
	$(COMPOSE) config

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f --tail=200

gluetun-logs:
	$(COMPOSE) logs -f --tail=200 gluetun

tailscale-logs:
	$(COMPOSE) logs -f --tail=200 tailscale route-fix

ps:
	$(COMPOSE) ps

ip:
	$(COMPOSE) exec gluetun sh -lc 'wget -qO- https://ifconfig.me || wget -qO- https://ipinfo.io/ip || true; echo'

shell:
	$(COMPOSE) exec gluetun sh
