function run(argv) {
  const days = Number(argv[0]);
  const app = Application("Notes");
  const folder = app.accounts.byName("iCloud").folders.byName("Notes");
  const cutoff = new Date(Date.now() - days * 864e5);
  const notes = folder.notes.whose({
    modificationDate: { _greaterThan: cutoff },
  })();
  return JSON.stringify(
    notes.map((n) => {
      const links = [];
      const media = [];
      for (const a of n.attachments()) {
        if (a.url()) {
          links.push(a.url());
        } else {
          const file =
            a.id().split("/").pop() +
            "-" +
            (a.name() || "attachment").replace(/[^\w.-]/g, "_");
          try {
            app.save(a, { in: Path("/tmp/notes-media/" + file) });
            media.push(file);
          } catch (e) {
            links.push(
              "(attachment not exportable: " + (a.name() || "unnamed") + ")",
            );
          }
        }
      }
      return {
        id: n.id(),
        name: n.name(),
        modified: n.modificationDate().toISOString(),
        body: n.plaintext().replace(/￼/g, "").trim(),
        links,
        media,
      };
    }),
  );
}
