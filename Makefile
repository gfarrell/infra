deploy:
	rsync --recursive --delete ./ $(SERVER_ADDRESS):~/infra/
	ssh $(SERVER_ADDRESS) "cd infra && docker-compose down && docker-compose up --build -d"
