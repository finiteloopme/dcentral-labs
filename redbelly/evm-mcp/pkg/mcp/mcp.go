package mcp

import (
	"fmt"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
	mcp "github.com/metoro-io/mcp-golang"
	"github.com/metoro-io/mcp-golang/transport/stdio"
)

type McpServer struct {
	server *mcp.Server
}

func NewServer() *McpServer {
	server := mcp.NewServer(stdio.NewStdioServerTransport())
	return &McpServer{
		server: server,
	}
}

func (s *McpServer) Serve() {
	err := s.server.Serve()
	oserr.PanicIfError("error serving server", err)
}

func (s *McpServer) RegisterTool(name string, description string, handlerFunc func() (any, error)) {
	err := s.server.RegisterTool(name, description,
		func(signer *evm.SignerAddress) (*mcp.ToolResponse, error) {
			// log.Infof("received tool request for signer: %v", signer.Address)
			response, err := handlerFunc()
			oserr.PanicIfError("error executing tool", err)
			return mcp.NewToolResponse(
				mcp.NewTextContent(fmt.Sprintf("%v", response)),
			), nil
		})
	oserr.PanicIfError(fmt.Sprintf("error registering tool: %v", name), err)
}

func (s *McpServer) RegisterPrompt(name string, description string, handlerFunc any) {
	err := s.server.RegisterPrompt(name, description, handlerFunc)
	oserr.PanicIfError(fmt.Sprintf("error registering prompt: %v", name), err)
}

func (s *McpServer) RegisterResource(name string, description string, handlerFunc any) {
	err := s.server.RegisterTool(name, description, handlerFunc)
	oserr.PanicIfError(fmt.Sprintf("error registering tool: %v", name), err)
}
