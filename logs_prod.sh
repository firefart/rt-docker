#!/bin/bash

docker compose -f docker-compose.yml logs -f --tail=100
