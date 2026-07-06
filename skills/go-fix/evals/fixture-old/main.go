package main

import (
	"fmt"
	"strings"
)

func newLimit(x int) *int { return &x }

func hostOf(addr string) string {
	i := strings.Index(addr, ":")
	if i >= 0 {
		return addr[:i]
	}
	return addr
}

func report(vals []interface{}) {
	for i := 0; i < len(vals); i++ {
		fmt.Println(vals[i])
	}
}

func main() {
	l := newLimit(10)
	report([]interface{}{*l, hostOf("db.internal:5432")})
}
