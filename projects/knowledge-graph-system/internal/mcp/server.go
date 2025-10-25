package mcp

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/core"
	"github.com/TheGenXCoder/knowledge-graph/pkg/types"
	"github.com/google/uuid"
)

// Server implements an MCP server for the Knowledge Graph
type Server struct {
	kg     core.KnowledgeGraph
	stdin  io.Reader
	stdout io.Writer
	stderr io.Writer
}

// NewServer creates a new MCP server
func NewServer(kg core.KnowledgeGraph) *Server {
	return &Server{
		kg:     kg,
		stdin:  os.Stdin,
		stdout: os.Stdout,
		stderr: os.Stderr,
	}
}

// Request represents an MCP JSON-RPC 2.0 request
type Request struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      interface{}     `json:"id"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
}

// Response represents an MCP JSON-RPC 2.0 response
type Response struct {
	JSONRPC string      `json:"jsonrpc"`
	ID      interface{} `json:"id"`
	Result  interface{} `json:"result,omitempty"`
	Error   *Error      `json:"error,omitempty"`
}

// Error represents an MCP JSON-RPC 2.0 error
type Error struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Start starts the MCP server
func (s *Server) Start(ctx context.Context) error {
	decoder := json.NewDecoder(s.stdin)
	encoder := json.NewEncoder(s.stdout)

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		var req Request
		if err := decoder.Decode(&req); err != nil {
			if err == io.EOF {
				return nil
			}
			s.logError("Failed to decode request: %v", err)
			continue
		}

		resp := s.handleRequest(ctx, &req)
		if err := encoder.Encode(resp); err != nil {
			s.logError("Failed to encode response: %v", err)
		}
	}
}

func (s *Server) handleRequest(ctx context.Context, req *Request) *Response {
	resp := &Response{
		JSONRPC: "2.0",
		ID:      req.ID,
	}

	switch req.Method {
	case "initialize":
		resp.Result = s.handleInitialize(ctx, req.Params)
	case "tools/list":
		resp.Result = s.handleToolsList(ctx)
	case "tools/call":
		result, err := s.handleToolsCall(ctx, req.Params)
		if err != nil {
			resp.Error = &Error{
				Code:    -32603,
				Message: err.Error(),
			}
		} else {
			resp.Result = result
		}
	default:
		resp.Error = &Error{
			Code:    -32601,
			Message: fmt.Sprintf("Method not found: %s", req.Method),
		}
	}

	return resp
}

func (s *Server) handleInitialize(ctx context.Context, params json.RawMessage) interface{} {
	return map[string]interface{}{
		"protocolVersion": "2024-11-05",
		"capabilities": map[string]interface{}{
			"tools": map[string]bool{},
		},
		"serverInfo": map[string]string{
			"name":    "knowledge-graph",
			"version": "0.1.0",
		},
	}
}

func (s *Server) handleToolsList(ctx context.Context) interface{} {
	return map[string]interface{}{
		"tools": []map[string]interface{}{
			{
				"name":        "kg_save_block",
				"description": "Save a conversation block to the knowledge graph. Auto-detects project from current directory.",
				"inputSchema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"topic": map[string]interface{}{
							"type":        "string",
							"description": "Topic or title of the conversation block",
						},
						"exchanges": map[string]interface{}{
							"type": "array",
							"description": "List of question-answer exchanges",
							"items": map[string]interface{}{
								"type": "object",
								"properties": map[string]interface{}{
									"question": map[string]interface{}{
										"type": "string",
									},
									"answer": map[string]interface{}{
										"type": "string",
									},
									"model": map[string]interface{}{
										"type": "string",
									},
								},
								"required": []string{"question", "answer"},
							},
						},
					},
					"required": []string{"topic", "exchanges"},
				},
			},
			{
				"name":        "kg_search",
				"description": "Search the knowledge graph using semantic + keyword hybrid search. Returns relevant blocks with sub-200ms performance.",
				"inputSchema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"query": map[string]interface{}{
							"type":        "string",
							"description": "Search query (natural language)",
						},
						"limit": map[string]interface{}{
							"type":        "integer",
							"description": "Maximum number of results (default 10)",
							"default":     10,
						},
						"include_n_plus": map[string]interface{}{
							"type":        "boolean",
							"description": "Include N+1 related blocks",
							"default":     false,
						},
					},
					"required": []string{"query"},
				},
			},
			{
				"name":        "kg_get_context",
				"description": "Get a block with N+1 context (one hop of relationships). Returns the block plus all related blocks via tags and relationships.",
				"inputSchema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"block_id": map[string]interface{}{
							"type":        "string",
							"description": "UUID of the block to retrieve",
						},
					},
					"required": []string{"block_id"},
				},
			},
		},
	}
}

func (s *Server) handleToolsCall(ctx context.Context, params json.RawMessage) (interface{}, error) {
	var callParams struct {
		Name      string                 `json:"name"`
		Arguments map[string]interface{} `json:"arguments"`
	}

	if err := json.Unmarshal(params, &callParams); err != nil {
		return nil, fmt.Errorf("failed to parse tool call params: %w", err)
	}

	switch callParams.Name {
	case "kg_save_block":
		return s.toolSaveBlock(ctx, callParams.Arguments)
	case "kg_search":
		return s.toolSearch(ctx, callParams.Arguments)
	case "kg_get_context":
		return s.toolGetContext(ctx, callParams.Arguments)
	default:
		return nil, fmt.Errorf("unknown tool: %s", callParams.Name)
	}
}

func (s *Server) toolSaveBlock(ctx context.Context, args map[string]interface{}) (interface{}, error) {
	topic, ok := args["topic"].(string)
	if !ok {
		return nil, fmt.Errorf("topic is required")
	}

	exchangesRaw, ok := args["exchanges"].([]interface{})
	if !ok {
		return nil, fmt.Errorf("exchanges is required")
	}

	// Auto-detect project from current directory
	cwd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("failed to get current directory: %w", err)
	}

	// Get or create project
	projectName := filepath.Base(cwd)
	project, err := s.kg.GetOrCreateProject(ctx, projectName, cwd)
	if err != nil {
		return nil, fmt.Errorf("failed to get/create project: %w", err)
	}

	// Build block
	block := &types.Block{
		ProjectID:     project.ID,
		Topic:         topic,
		StartedAt:     time.Now(),
		CompletedAt:   timePtr(time.Now()),
		ExchangeCount: len(exchangesRaw),
		Metadata:      make(map[string]interface{}),
	}

	// Parse exchanges
	for i, exRaw := range exchangesRaw {
		exMap, ok := exRaw.(map[string]interface{})
		if !ok {
			return nil, fmt.Errorf("invalid exchange format at index %d", i)
		}

		question, _ := exMap["question"].(string)
		answer, _ := exMap["answer"].(string)
		model, _ := exMap["model"].(string)

		if question == "" || answer == "" {
			return nil, fmt.Errorf("question and answer are required in exchange %d", i)
		}

		block.Exchanges = append(block.Exchanges, types.Exchange{
			Question:  question,
			Answer:    answer,
			Timestamp: time.Now(),
			ModelUsed: model,
		})
	}

	// Save block
	if err := s.kg.SaveBlock(ctx, block); err != nil {
		return nil, fmt.Errorf("failed to save block: %w", err)
	}

	return map[string]interface{}{
		"success":   true,
		"block_id":  block.ID.String(),
		"project":   project.Name,
		"exchanges": len(block.Exchanges),
	}, nil
}

func (s *Server) toolSearch(ctx context.Context, args map[string]interface{}) (interface{}, error) {
	query, ok := args["query"].(string)
	if !ok {
		return nil, fmt.Errorf("query is required")
	}

	opts := types.SearchOptions{
		Limit:        10,
		IncludeNPlus: false,
	}

	if limit, ok := args["limit"].(float64); ok {
		opts.Limit = int(limit)
	}

	if includeNPlus, ok := args["include_n_plus"].(bool); ok {
		opts.IncludeNPlus = includeNPlus
	}

	results, err := s.kg.Search(ctx, query, opts)
	if err != nil {
		return nil, fmt.Errorf("search failed: %w", err)
	}

	// Format results for MCP response
	formattedResults := make([]map[string]interface{}, len(results.Results))
	for i, result := range results.Results {
		exchanges := make([]map[string]interface{}, len(result.Block.Exchanges))
		for j, ex := range result.Block.Exchanges {
			exchanges[j] = map[string]interface{}{
				"question":  ex.Question,
				"answer":    ex.Answer,
				"timestamp": ex.Timestamp.Format(time.RFC3339),
				"model":     ex.ModelUsed,
			}
		}

		formattedResults[i] = map[string]interface{}{
			"block_id":  result.Block.ID.String(),
			"topic":     result.Block.Topic,
			"relevance": result.Relevance,
			"created":   result.Block.CreatedAt.Format(time.RFC3339),
			"exchanges": exchanges,
		}
	}

	return map[string]interface{}{
		"results":     formattedResults,
		"total_found": results.TotalFound,
		"search_time": results.SearchTime.String(),
	}, nil
}

func (s *Server) toolGetContext(ctx context.Context, args map[string]interface{}) (interface{}, error) {
	blockIDStr, ok := args["block_id"].(string)
	if !ok {
		return nil, fmt.Errorf("block_id is required")
	}

	blockID, err := uuid.Parse(blockIDStr)
	if err != nil {
		return nil, fmt.Errorf("invalid block_id: %w", err)
	}

	bundle, err := s.kg.GetContextNPlusOne(ctx, blockID)
	if err != nil {
		return nil, fmt.Errorf("failed to get context: %w", err)
	}

	// Format response
	return map[string]interface{}{
		"primary_block": formatBlock(bundle.PrimaryBlock),
		"related_blocks": formatBlocks(bundle.RelatedBlocks),
		"tags":          formatTags(bundle.Tags),
	}, nil
}

func formatBlock(block *types.Block) map[string]interface{} {
	if block == nil {
		return nil
	}

	exchanges := make([]map[string]interface{}, len(block.Exchanges))
	for i, ex := range block.Exchanges {
		exchanges[i] = map[string]interface{}{
			"question":  ex.Question,
			"answer":    ex.Answer,
			"timestamp": ex.Timestamp.Format(time.RFC3339),
			"model":     ex.ModelUsed,
		}
	}

	return map[string]interface{}{
		"id":       block.ID.String(),
		"topic":    block.Topic,
		"created":  block.CreatedAt.Format(time.RFC3339),
		"exchanges": exchanges,
	}
}

func formatBlocks(blocks []*types.Block) []map[string]interface{} {
	result := make([]map[string]interface{}, len(blocks))
	for i, block := range blocks {
		result[i] = formatBlock(block)
	}
	return result
}

func formatTags(tags []types.Tag) []map[string]interface{} {
	result := make([]map[string]interface{}, len(tags))
	for i, tag := range tags {
		result[i] = map[string]interface{}{
			"id":   tag.ID.String(),
			"name": tag.Name,
		}
	}
	return result
}

func (s *Server) logError(format string, args ...interface{}) {
	fmt.Fprintf(s.stderr, "[ERROR] "+format+"\n", args...)
}

func timePtr(t time.Time) *time.Time {
	return &t
}
