## Medicines for LK - Admin API

The medicines LK app is comprised of a [React Frontend](https://github.com/LSFLK/MedicinesforLK), [Ballerina Donor API](https://github.com/LSFLK/MedicinesforLK-DonorAPI) and [Ballerina Admin API](https://github.com/LSFLK/MedicinesforLK-AdminAPI). 

### Development

- [Set up Ballerina](https://ballerina.io/learn/install-ballerina/set-up-ballerina/)
- Run a MySQL server and execute the script `mysql-scripts/creation-ddl.sql` on it to bring up the DDL for the db.
- Modify `config.bal` with the values for the MySQL server you set up.
- `bal run`

### Run using Docker Compose

- `docker-compose up -d`
