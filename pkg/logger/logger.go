package logger

import (
	"fmt"
	"log"
	"os"
	"strings"
	"sync"
)

const (
	LevelDebug = iota
	LevelVerbose
	LevelInfo
	LevelWarning
	LevelError
	LevelOff
)

var levelNames = map[int]string{
	LevelDebug:   "DEBUG",
	LevelVerbose: "VERBOSE",
	LevelInfo:    "INFO",
	LevelWarning: "WARN",
	LevelError:   "ERROR",
}

func ParseLevel(s string) int {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "debug":
		return LevelDebug
	case "verbose", "v":
		return LevelVerbose
	case "info", "i":
		return LevelInfo
	case "warn", "warning", "w":
		return LevelWarning
	case "error", "e":
		return LevelError
	case "off", "none", "disabled", "":
		return LevelOff
	default:
		return LevelInfo
	}
}

const (
	ansiReset  = "\033[0m"
	ansiRed    = "\033[31m"
	ansiGreen  = "\033[32m"
	ansiYellow = "\033[33m"
	ansiBlue   = "\033[34m"
)

var stdLog = log.New(os.Stdout, "", 0)

type Logger struct {
	mu       sync.Mutex
	level    int
	prefix   string
	useColor bool
}

var Default = New(LevelInfo, true)

func New(minLevel int, useColor bool) *Logger {
	return &Logger{
		level:    minLevel,
		prefix:   "[Skeleton] ",
		useColor: useColor,
	}
}

func (l *Logger) SetLevel(level int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.level = level
}

func (l *Logger) output(level int, levelName string, color string, format string, args ...any) {
	if level < l.level {
		return
	}

	l.mu.Lock()
	msg := fmt.Sprintf(format, args...)
	line := l.prefix + levelName + " " + msg
	if l.useColor && color != "" {
		line = color + line + ansiReset
	}
	l.mu.Unlock()

	stdLog.Println(line)
}

func (l *Logger) D(format string, args ...any) {
	l.output(LevelDebug, levelNames[LevelDebug], ansiBlue, format, args...)
}

func (l *Logger) V(format string, args ...any) {
	l.output(LevelVerbose, levelNames[LevelVerbose], "", format, args...)
}

func (l *Logger) I(format string, args ...any) {
	l.output(LevelInfo, levelNames[LevelInfo], ansiGreen, format, args...)
}

func (l *Logger) W(format string, args ...any) {
	l.output(LevelWarning, levelNames[LevelWarning], ansiYellow, format, args...)
}

func (l *Logger) E(format string, args ...any) {
	l.output(LevelError, levelNames[LevelError], ansiRed, format, args...)
}

func D(format string, args ...any) {
	Default.D(format, args...)
}

func V(format string, args ...any) {
	Default.V(format, args...)
}

func I(format string, args ...any) {
	Default.I(format, args...)
}

func W(format string, args ...any) {
	Default.W(format, args...)
}

func E(format string, args ...any) {
	Default.E(format, args...)
}
