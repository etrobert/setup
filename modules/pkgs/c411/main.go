// Search c411's Torznab API and hand a release to transmission on charon.
package main

import (
	"encoding/xml"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

type feed struct {
	Items []item `xml:"channel>item"`
}

type item struct {
	Title     string `xml:"title"`
	Size      int64  `xml:"size"`
	Enclosure struct {
		URL string `xml:"url,attr"`
	} `xml:"enclosure"`
	Attrs []struct {
		Name  string `xml:"name,attr"`
		Value string `xml:"value,attr"`
	} `xml:"attr"`
}

func (i item) seeders() string {
	for _, attr := range i.Attrs {
		if attr.Name == "seeders" {
			return attr.Value
		}
	}
	return "?"
}

func main() {
	if len(os.Args) < 2 {
		fail("usage: c411 <search terms>")
	}

	key, err := os.ReadFile("/run/agenix/c411-api-key")
	check(err)

	query := url.Values{
		"apikey": {strings.TrimSpace(string(key))},
		"t":      {"music"},
		"q":      {strings.Join(os.Args[1:], " ")},
	}
	response, err := http.Get("https://c411.org/api/torznab?" + query.Encode())
	check(err)
	defer response.Body.Close()

	var results feed
	check(xml.NewDecoder(response.Body).Decode(&results))
	if len(results.Items) == 0 {
		fail("no results")
	}

	var menu strings.Builder
	for n, it := range results.Items {
		fmt.Fprintf(&menu, "%d\t%4s seeds\t%s\t%s\n", n, it.seeders(), gigabytes(it.Size), it.Title)
	}

	picked := exec.Command("fzf", "--delimiter=\t", "--with-nth=2..", "--height=40%", "--reverse")
	picked.Stdin = strings.NewReader(menu.String())
	picked.Stderr = os.Stderr
	choice, err := picked.Output()
	check(err)

	n, err := strconv.Atoi(strings.SplitN(string(choice), "\t", 2)[0])
	check(err)

	add := exec.Command("transmission-remote", "torrents:80", "--add", results.Items[n].Enclosure.URL)
	add.Stdout, add.Stderr = os.Stdout, os.Stderr
	check(add.Run())
}

func gigabytes(bytes int64) string {
	return fmt.Sprintf("%6.2fG", float64(bytes)/1e9)
}

func check(err error) {
	if err != nil {
		fail(err.Error())
	}
}

func fail(message string) {
	fmt.Fprintln(os.Stderr, message)
	os.Exit(1)
}
