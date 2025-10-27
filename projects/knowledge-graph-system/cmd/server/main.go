package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/rs/cors"
)

// Config holds the application configuration
type Config struct {
	Port      string
	DBHost    string
	DBName    string
	DBUser    string
	DBPassword string
	RedisHost string
	JWTSecret string
}

// Server represents our API server
type Server struct {
	config   *Config
	router   *mux.Router
	upgrader websocket.Upgrader
}

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
}

// NewServer creates a new server instance
func NewServer(config *Config) *Server {
	return &Server{
		config: config,
		router: mux.NewRouter(),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// Allow connections from any origin in development
				// TODO: Restrict in production
				return true
			},
		},
	}
}

// setupRoutes configures all API routes
func (s *Server) setupRoutes() {
	// Health check
	s.router.HandleFunc("/health", s.handleHealth).Methods("GET")

	// API v1 routes
	api := s.router.PathPrefix("/api/v1").Subrouter()

	// Knowledge graph endpoints
	api.HandleFunc("/search", s.handleSearch).Methods("POST")
	api.HandleFunc("/chat", s.handleChat).Methods("POST")
	api.HandleFunc("/embed", s.handleEmbed).Methods("POST")
	api.HandleFunc("/knowledge/add", s.handleKnowledgeAdd).Methods("POST")
	api.HandleFunc("/knowledge/{id}", s.handleKnowledgeGet).Methods("GET")

	// Neovim plugin specific endpoints
	api.HandleFunc("/nvim/complete", s.handleNvimComplete).Methods("POST")
	api.HandleFunc("/nvim/edit", s.handleNvimEdit).Methods("POST")
	api.HandleFunc("/nvim/git", s.handleNvimGit).Methods("POST")

	// WebSocket endpoint for streaming
	api.HandleFunc("/ws", s.handleWebSocket)

	// Static file serving for web UI (if exists)
	s.router.PathPrefix("/").Handler(http.FileServer(http.Dir("./web/dist/")))
}

// handleHealth handles health check requests
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Version:   "0.9.0",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleSearch handles search requests
func (s *Server) handleSearch(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement search logic with pgvector
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"results": []interface{}{},
		"query":   r.URL.Query().Get("q"),
	})
}

// handleChat handles chat requests
func (s *Server) handleChat(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement chat logic with Ollama
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"response": "Chat endpoint coming soon",
		"model":    "ollama/llama3",
	})
}

// handleEmbed handles embedding requests
func (s *Server) handleEmbed(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement embedding logic with Ollama
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"embeddings": []float64{},
		"model":      "nomic-embed-text",
	})
}

// handleKnowledgeAdd handles adding knowledge to the graph
func (s *Server) handleKnowledgeAdd(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement knowledge addition logic
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"id":     "placeholder-id",
	})
}

// handleKnowledgeGet retrieves knowledge from the graph
func (s *Server) handleKnowledgeGet(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	// TODO: Implement knowledge retrieval logic
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"id":      id,
		"content": "placeholder content",
	})
}

// handleNvimComplete handles Neovim completion requests
func (s *Server) handleNvimComplete(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement Neovim completion logic
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"completions": []string{},
	})
}

// handleNvimEdit handles Neovim edit requests
func (s *Server) handleNvimEdit(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement Neovim edit logic
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"diff": "",
		"status": "success",
	})
}

// handleNvimGit handles Neovim git requests
func (s *Server) handleNvimGit(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement Neovim git logic
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Auto-generated commit message",
		"status":  "success",
	})
}

// handleWebSocket handles WebSocket connections for streaming
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}
	defer conn.Close()

	// TODO: Implement WebSocket streaming logic
	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			log.Printf("WebSocket read error: %v", err)
			return
		}

		// Echo the message back for now
		if err := conn.WriteMessage(messageType, p); err != nil {
			log.Printf("WebSocket write error: %v", err)
			return
		}
	}
}

// Run starts the server
func (s *Server) Run() error {
	s.setupRoutes()

	// Setup CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"https://catalyst9.ai", "http://localhost:*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})

	handler := c.Handler(s.router)

	srv := &http.Server{
		Addr:         ":" + s.config.Port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Catalyst9 API server starting on port %s", s.config.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		return fmt.Errorf("server forced to shutdown: %w", err)
	}

	log.Println("Server gracefully stopped")
	return nil
}

func main() {
	// Load configuration from environment
	config := &Config{
		Port:       getEnv("PORT", "8080"),
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBName:     getEnv("DB_NAME", "catalyst9"),
		DBUser:     getEnv("DB_USER", "catalyst9"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		RedisHost:  getEnv("REDIS_HOST", "localhost:6379"),
		JWTSecret:  getEnv("JWT_SECRET", "development_secret"),
	}

	// Create and run server
	server := NewServer(config)
	if err := server.Run(); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}