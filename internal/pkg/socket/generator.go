package socket

import "github.com/bwmarrin/snowflake"

type IDGenerator interface {
	ID() int64
}

type SnowflakeGenerator struct {
	Node *snowflake.Node
}

var defaultIDGenerator IDGenerator

func init() {
	node, err := snowflake.NewNode(1)
	if err != nil {
		panic(err)
	}
	defaultIDGenerator = &SnowflakeGenerator{Node: node}
}

func (g *SnowflakeGenerator) ID() int64 {
	return g.Node.Generate().Int64()
}
