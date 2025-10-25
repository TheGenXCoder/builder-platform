package embeddings

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// OllamaEmbedder uses Ollama to generate embeddings
type OllamaEmbedder struct {
	baseURL string
	model   string
	client  *http.Client
}

// NewOllamaEmbedder creates a new Ollama embedder
func NewOllamaEmbedder(baseURL, model string) *OllamaEmbedder {
	if baseURL == "" {
		baseURL = "http://localhost:11434"
	}
	if model == "" {
		model = "nomic-embed-text" // 384-dim embeddings
	}

	return &OllamaEmbedder{
		baseURL: baseURL,
		model:   model,
		client:  &http.Client{},
	}
}

type embedRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
}

type embedResponse struct {
	Embedding []float64 `json:"embedding"`
}

// Embed generates an embedding for a single text
func (o *OllamaEmbedder) Embed(ctx context.Context, text string) ([]float64, error) {
	req := embedRequest{
		Model:  o.model,
		Prompt: text,
	}

	reqBody, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", o.baseURL+"/api/embeddings", bytes.NewReader(reqBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := o.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ollama returned status %d: %s", resp.StatusCode, string(body))
	}

	var embedResp embedResponse
	if err := json.NewDecoder(resp.Body).Decode(&embedResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return embedResp.Embedding, nil
}

// EmbedBatch generates embeddings for multiple texts
func (o *OllamaEmbedder) EmbedBatch(ctx context.Context, texts []string) ([][]float64, error) {
	embeddings := make([][]float64, len(texts))

	for i, text := range texts {
		emb, err := o.Embed(ctx, text)
		if err != nil {
			return nil, fmt.Errorf("failed to embed text %d: %w", i, err)
		}
		embeddings[i] = emb
	}

	return embeddings, nil
}
