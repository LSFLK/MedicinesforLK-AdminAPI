## Medicines for LK - Admin API

The medicines LK app is comprised of a [React Frontend](https://github.com/LSFLK/MedicinesforLK), [Ballerina Donor API](https://github.com/LSFLK/MedicinesforLK-DonorAPI) and [Ballerina Admin API](https://github.com/LSFLK/MedicinesforLK-AdminAPI). 

### Development

- [Set up Ballerina](https://ballerina.io/learn/install-ballerina/set-up-ballerina/)
- Run a MySQL server and execute the script `mysql-scripts/creation-ddl.sql` on it to bring up the DDL for the db. You need to have a `medicinesforlk` db in your MySQL server to set up the DDL in.
- Modify `config.bal` with the values for the MySQL server you set up. 
- `bal run` (runs the API on port 9090)
- Test the API http://localhost:9090/admin/medicalneeds

### Run using Docker Compose

- `docker-compose up -d`
- Test the API http://localhost:9090/admin/medicalneeds
