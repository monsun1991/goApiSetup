My API Project
This project is a simple Go-based REST API that supports user authentication with JWT, user data retrieval, a protected dashboard, and user logout functionality. It includes a database connection to MySQL and follows basic best practices for structuring a Go application.

Features
Login: Secure login with JWT token generation.
Dashboard: Protected route showing personalized dashboard data.
Get User: Fetch user details from the database.
Logout: Logout functionality that invalidates the JWT token.
Database: MySQL database connectivity to store user data.
Prerequisites
Before setting up the project, ensure you have the following installed:

Go (version 1.18+)
MySQL (or MariaDB)
git (optional, for cloning the repository)
Project Setup
This repository includes a shell script (setup_project.sh) that automates the setup of the project structure, database initialization, and Go dependencies.

1. Clone the Repository
Clone the repository to your local machine (if applicable):

bash
git clone https://github.com/your-repo/my-api.git
cd my-api
2. Run the Setup Script
The setup_project.sh script will:

Initialize the Go module.
Install the required Go dependencies.
Set up the folder structure for the API project.
Create the necessary Go files.
Create the my_api_db database and users table in MySQL (using root as the username and complex as the password).
To execute the script, run the following commands:

bash
chmod +x setup_project.sh
./setup_project.sh
This will:

Set up the project.
Install the required Go dependencies (jwt for authentication and mysql for database connectivity).
Initialize the database and insert a sample user (with username admin and password password).
3. Start the Application
Once the setup is complete, run the Go application:

bash
go run cmd/main.go
The API will be available at http://localhost:8080.

API Endpoints
1. Login
Endpoint: POST /login

Request Body:

json
{
  "username": "admin",
  "password": "password"
}
Response:

json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "Login successful"
}
2. Dashboard (Protected)
Endpoint: GET /dashboard

Headers:

Authorization: Bearer <token>
Response:

json
{
  "message": "Welcome to your dashboard!",
  "data": "Here is your personalized dashboard data."
}
3. Get User (Protected)
Endpoint: GET /user

Headers:

Authorization: Bearer <token>
Response:

json
{
  "id": 1,
  "username": "admin",
  "email": "admin@example.com"
}
4. Logout
Endpoint: GET /logout

Response:

json
{
  "message": "Logged out successfully!"
}
Database
This project uses MySQL for data storage. By default, the database name is my_api_db, and the users table contains the following fields:

id: INT (Primary Key)
username: VARCHAR
password: VARCHAR
email: VARCHAR
created_at: TIMESTAMP
A sample user (admin with password password) is inserted during the setup.

Troubleshooting
If you encounter any issues, here are a few things to check:

MySQL Connection: Ensure that your MySQL server is running and accessible with the credentials provided in the script (root as the username and complex as the password).
JWT Token Issues: If the JWT token is invalid or missing, make sure you include the token in the Authorization header for protected routes (e.g., /dashboard or /user).
Go Module Issues: If there are problems with the Go module, run go mod tidy to clean up dependencies.
License
This project is licensed under the MIT License - see the LICENSE file for details.

Let me know if you need further assistance or modifications! 🚀
