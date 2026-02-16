package strutil

import (
	"github.com/google/uuid"
	"math/rand"
	"strings"
	"time"
)

func Random(length int) string {
	var result []byte
	bytes := []byte("0123456789abcdefghijklmnopqrstuvwxyz")
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < length; i++ {
		result = append(result, bytes[r.Intn(len(bytes))])
	}

	return string(result)
}

func NewMsgId() string {
	return strings.ReplaceAll(uuid.New().String(), "-", "")
}
