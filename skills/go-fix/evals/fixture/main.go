package main

import (
	"fmt"
	"sort"
	"strings"
	"sync"
)

func newCount(x int) *int { return &x }

func clampScore(raw func() int) int {
	s := raw()
	if s < 0 {
		s = 0
	}
	if s > 100 {
		s = 100
	}
	return s
}

func firstField(s string) string {
	i := strings.Index(s, ":")
	if i >= 0 {
		return s[:i]
	}
	return s
}

func printAll(items []interface{}) {
	for i := 0; i < len(items); i++ {
		fmt.Println(items[i])
	}
}

func sortNames(names []string) {
	sort.Slice(names, func(i, j int) bool { return names[i] < names[j] })
}

func runWorkers(jobs []string) {
	var wg sync.WaitGroup
	for _, j := range jobs {
		j := j
		wg.Add(1)
		go func() {
			defer wg.Done()
			fmt.Println(j)
		}()
	}
	wg.Wait()
}

func main() {
	c := newCount(3)
	names := []string{"charlie", "alpha", "bravo"}
	sortNames(names)
	printAll([]interface{}{*c, firstField("key:value"), clampScore(func() int { return 150 })})
	runWorkers(names)
}
