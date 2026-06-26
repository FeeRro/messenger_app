package main

import "fmt"

func main() {
	a := []int{1, 2, 3, 4, 5}
	b := []int{4, 5, 6, 7, 8}

	result := setArray(a, b)
	fmt.Println(result)
}

func setArray(a, b []int) []int {
	set := make(map[int]struct{})
	my_set := make([]int, 0, len(a))

	for _, i := range a {
		set[i] = struct{}{}
		for _, j := range b {
			if _, ok := set[j]; ok {
				my_set = append(my_set, j)
				delete(set, j)
			}
		}
	}

	return my_set
}
