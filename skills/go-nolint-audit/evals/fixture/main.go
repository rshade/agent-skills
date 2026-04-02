package main

import (
	"fmt"
	"os"
)

func main() {
	// Stale: errcheck's default ignore list includes fmt.*; rule never fires here
	fmt.Println("hello") //nolint:errcheck // print errors are ignorable

	// Bare nolint — no specific rule named; over-broad suppression
	x := compute() //nolint // legacy shim, do not remove

	// Active: errcheck fires because the error from os.ReadFile is discarded
	data, _ := os.ReadFile("data.txt") //nolint:errcheck // complexity is inherent

	fmt.Println(string(data), x)
}

// compute returns a static string value.
func compute() string {
	return "result"
}
