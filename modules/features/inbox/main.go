package main

import (
	"errors"
	"flag"
	"html/template"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

var page = template.Must(template.New("page").Parse(`<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inbox</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 1.1rem system-ui, sans-serif; max-width: 40rem; margin: 1rem auto; padding: 0 1rem; }
  textarea { width: 100%; box-sizing: border-box; font: inherit; }
  pre { white-space: pre-wrap; }
</style>
<form method="post">
  <textarea name="text" rows="4" required autofocus></textarea>
  <button>Capture</button>
</form>
<pre>{{.}}</pre>
`))

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

func fail(w http.ResponseWriter, err error) {
	log.Print(err)
	http.Error(w, err.Error(), http.StatusInternalServerError)
}

func main() {
	addr := flag.String("addr", "", "address to listen on, e.g. 127.0.0.1:8080")
	file := flag.String("file", "", "Markdown file captures are appended to")
	flag.Parse()
	if *addr == "" || *file == "" {
		log.Fatal("-addr and -file are required")
	}

	http.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		content, err := os.ReadFile(*file)
		if err != nil && !errors.Is(err, fs.ErrNotExist) {
			fail(w, err)
			return
		}
		if err := page.Execute(w, string(content)); err != nil {
			log.Print(err)
		}
	})

	http.HandleFunc("POST /{$}", func(w http.ResponseWriter, r *http.Request) {
		text := strings.TrimSpace(r.PostFormValue("text"))
		if text == "" {
			http.Error(w, "missing form field: text", http.StatusBadRequest)
			return
		}
		if err := appendTo(*file, entry(time.Now(), text)); err != nil {
			fail(w, err)
			return
		}
		http.Redirect(w, r, "/", http.StatusSeeOther)
	})

	log.Fatal(http.ListenAndServe(*addr, nil))
}
