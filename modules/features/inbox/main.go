package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

// entry formats a capture as one Markdown list item, indenting continuation lines.
func entry(now time.Time, text string) string {
	lines := strings.Split(strings.ReplaceAll(text, "\r\n", "\n"), "\n")
	return "- " + now.Format("2006-01-02 15:04") + " " + strings.Join(lines, "\n  ") + "\n"
}

func appendTo(path, s string) error {
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	if _, err := f.WriteString(s); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}

func main() {
	addr := flag.String("addr", "", "address to listen on, e.g. 127.0.0.1:8080")
	file := flag.String("file", "", "Markdown file captures are appended to")
	flag.Parse()
	if *addr == "" || *file == "" {
		log.Fatal("-addr and -file are required")
	}

	http.HandleFunc("POST /{$}", func(w http.ResponseWriter, r *http.Request) {
		text := strings.TrimSpace(r.PostFormValue("text"))
		if text == "" {
			http.Error(w, "missing form field: text", http.StatusBadRequest)
			return
		}
		if err := appendTo(*file, entry(time.Now(), text)); err != nil {
			log.Print(err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})

	log.Fatal(http.ListenAndServe(*addr, nil))
}
