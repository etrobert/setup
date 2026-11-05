package main

import (
	"errors"
	"flag"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// create writes a new file and fails if one with that name already exists.
func create(path, content string) error {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	if _, err := f.WriteString(content); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}

func main() {
	addr := flag.String("addr", "", "address to listen on, e.g. 127.0.0.1:8080")
	dir := flag.String("dir", "", "directory each capture is written into as its own Markdown file")
	flag.Parse()
	if *addr == "" || *dir == "" {
		log.Fatal("-addr and -dir are required")
	}

	http.HandleFunc("POST /{$}", func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		text := strings.TrimSpace(string(body))
		if text == "" {
			http.Error(w, "empty body", http.StatusBadRequest)
			return
		}
		name := time.Now().Format("2006-01-02T15-04-05") + ".md"
		err = create(filepath.Join(*dir, name), text+"\n")
		if errors.Is(err, fs.ErrExist) {
			http.Error(w, name+" already exists, try again", http.StatusConflict)
			return
		}
		if err != nil {
			log.Print(err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
	})

	log.Fatal(http.ListenAndServe(*addr, nil))
}
