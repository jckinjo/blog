utc_now := $(shell date -u +%Y-%m-%dT%H:%M:%S+00:00)
today := $(shell date -u +%Y%m%d)
filename := content/posts/$(today).md

tech:
	@echo "Creating post: $(filename)"; \
	cp archetypes/tech.md $(filename); \
	sed -i '' "s/^date: .*/date: $(utc_now)/" $(filename)

life:
	@echo "Creating post: $(filename)"; \
	cp archetypes/life.md $(filename); \
	sed -i '' "s/^date: .*/date: $(utc_now)/" $(filename)

note:
	@read -p "Filename (e.g. book_name): " name; \
	echo "Creating note: content/posts/booknotes/$$name.md"; \
	cp archetypes/note.md content/posts/booknotes/$$name.md

serve:
	@hugo server --disableFastRender --ignoreCache
