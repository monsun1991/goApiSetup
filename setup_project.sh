#!/bin/bash

# Set project name
PROJECT_NAME="my-api"

echo "Setting up Go project: $PROJECT_NAME"

# Create project folder structure
mkdir -p $PROJECT_NAME/internal/{controllers,models,routes,database,middlewares}
mkdir -p $PROJECT_NAME/cmd

# Initialize Go module
cd $PROJECT_NAME
go mod init $PROJECT_NAME

# Install dependencies
echo "Installing dependencies..."
go get -u github.com/golang-jwt/jwt/v5
go get -u github.com/go-sql-driver/mysql

# Create database connection file
cat <<EOL > internal/database/connection.go
package database

import (
	"database/sql"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func InitDB() {
	var err error
	DB, err = sql.Open("mysql", "root:complex@tcp(localhost:3306)/my_api_db")
	if err != nil {
		log.Fatalf("Error connecting to database: %v", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatalf("Database is unreachable: %v", err)
	}

	log.Println("Database connection established successfully.")
}
EOL

# Create controllers
cat <<EOL > internal/controllers/auth_controller.go
package controllers

import (
	"encoding/json"
	"net/http"
	"$PROJECT_NAME/internal/models"
	"github.com/golang-jwt/jwt/v5"
	"time"
)

var secretKey = []byte("your_secret_key")

type LoginPayload struct {
	Username string \`json:"username"\`
	Password string \`json:"password"\`
}

type TokenResponse struct {
	Token   string \`json:"token"\`
	Message string \`json:"message"\`
}

func Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var payload LoginPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	if payload.Username != "admin" || payload.Password != "password" {
		http.Error(w, "Invalid username or password", http.StatusUnauthorized)
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": payload.Username,
		"exp":      time.Now().Add(time.Hour * 1).Unix(),
	})
	tokenString, err := token.SignedString(secretKey)
	if err != nil {
		http.Error(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(TokenResponse{
		Token:   tokenString,
		Message: "Login successful",
	})
}
EOL

cat <<EOL > internal/controllers/dashboard_controller.go
package controllers

import (
	"encoding/json"
	"net/http"
)

type DashboardResponse struct {
	Message string \`json:"message"\`
	Data    string \`json:"data"\`
}

func Dashboard(w http.ResponseWriter, r *http.Request) {
	response := DashboardResponse{
		Message: "Welcome to your dashboard!",
		Data:    "Here is your personalized dashboard data.",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
EOL

cat <<EOL > internal/controllers/user_controller.go
package controllers

import (
	"encoding/json"
	"net/http"
	"$PROJECT_NAME/internal/database"
)

type UserResponse struct {
	ID       int    \`json:"id"\`
	Username string \`json:"username"\`
	Email    string \`json:"email"\`
}

func GetUser(w http.ResponseWriter, r *http.Request) {
	userID := 1

	var user UserResponse
	err := database.DB.QueryRow("SELECT id, username, email FROM users WHERE id = ?", userID).Scan(&user.ID, &user.Username, &user.Email)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}
EOL

# Create routes
cat <<EOL > internal/routes/routes.go
package routes

import (
	"net/http"
	"$PROJECT_NAME/internal/controllers"
	"$PROJECT_NAME/internal/middlewares"
)

func SetupRoutes() *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/login", controllers.Login)
	mux.HandleFunc("/logout", controllers.Logout)
	mux.Handle("/dashboard", middlewares.JWTMiddleware(http.HandlerFunc(controllers.Dashboard)))
	mux.Handle("/user", middlewares.JWTMiddleware(http.HandlerFunc(controllers.GetUser)))

	return mux
}
EOL

# Create middleware for JWT authentication
cat <<EOL > internal/middlewares/jwt_middleware.go
package middlewares

import (
	"context"
	"net/http"
	"strings"
	"github.com/golang-jwt/jwt/v5"
)

var secretKey = []byte("your_secret_key")

func JWTMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return secretKey, nil
		})
		if err != nil || !token.Valid {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		ctx := context.WithValue(r.Context(), "user", token.Claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
EOL

# Create main.go
cat <<EOL > cmd/main.go
package main

import (
	"log"
	"net/http"
	"$PROJECT_NAME/internal/database"
	"$PROJECT_NAME/internal/routes"
)

func main() {
	database.InitDB()
	defer database.DB.Close()

	http.Handle("/", routes.SetupRoutes())
	log.Println("Server running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
EOL

# Initialize the database
echo "Initializing database..."
mysql -u root -pcomplex -e "
CREATE DATABASE IF NOT EXISTS my_api_db;
USE my_api_db;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (username, password, email) 
VALUES ('admin', 'password', 'admin@example.com') ON DUPLICATE KEY UPDATE username=username;
"

echo "Project setup complete!"
