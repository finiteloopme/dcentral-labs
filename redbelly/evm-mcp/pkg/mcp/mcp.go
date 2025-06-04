package mcp

import (
	"context"
	"fmt"

	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

type McpServer struct {
	server *server.MCPServer
}

func NewServer() *McpServer {
	server := server.NewMCPServer(
		"Portfolio Manager | AI Agent", // TODO: Add a user name
		"0.0.1-alpha",
		server.WithToolCapabilities(true),
	)
	return &McpServer{
		server: server,
	}
}

func (s *McpServer) Serve() {
	err := server.ServeStdio(s.server)
	oserr.PanicIfError("error serving server", err)
}

func (s *McpServer) RegisterTool(name string, description string, handlerFunc func() (any, error)) {
	tool := mcp.NewTool(
		name,
		mcp.WithDescription(description),
		mcp.WithString("name",
			mcp.Description("Name of the user"),
		),
	)
	s.server.AddTool(tool,
		func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
			response, err := handlerFunc()
			oserr.PanicIfError("error executing tool", err)
			return mcp.NewToolResultText(fmt.Sprintf("%v", response)), nil
		},
	)
	// err := s.server.RegisterTool(name, description,
	// 	func(signer *evm.SignerAddress) (*mcp.ToolResponse, error) {
	// 		// log.Infof("received tool request for signer: %v", signer.Address)
	// 		response, err := handlerFunc()
	// 		oserr.PanicIfError("error executing tool", err)
	// 		return mcp.NewToolResponse(
	// 			mcp.NewTextContent(fmt.Sprintf("%v", response)),
	// 		), nil
	// 	})
	// oserr.PanicIfError(fmt.Sprintf("error registering tool: %v", name), err)
}

// func (s *McpServer) RegisterPrompt(name string, description string, handlerFunc any) {
// 	err := s.server.RegisterPrompt(name, description, handlerFunc)
// 	oserr.PanicIfError(fmt.Sprintf("error registering prompt: %v", name), err)
// }

// func (s *McpServer) RegisterResource(name string, description string, handlerFunc any) {
// 	err := s.server.RegisterTool(name, description, handlerFunc)
// 	oserr.PanicIfError(fmt.Sprintf("error registering tool: %v", name), err)
// }
