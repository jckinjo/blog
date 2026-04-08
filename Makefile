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

img:
	@read -p "Image path: " src; \
	read -p "Post name (e.g. 20231017): " post; \
	if [ -z "$$src" ] || [ -z "$$post" ]; then echo "Error: Image path and Post name are required"; exit 1; fi; \
	if [ ! -f "$$src" ]; then echo "Error: $$src not found"; exit 1; fi; \
	if [ ! -f "content/posts/$${post}.md" ]; then echo "Error: content/posts/$${post}.md not found"; exit 1; fi; \
	ext=$${src##*.}; \
	last=$$(ls static/posts/$${post}-*.$$ext 2>/dev/null | sort -t- -k2 -n | tail -1); \
	if [ -z "$$last" ]; then \
		n=1; \
	else \
		n=$$(echo "$$last" | sed "s|.*$${post}-\([0-9]*\)\..*|\1|"); \
		n=$$((n + 1)); \
	fi; \
	name="$${post}-$${n}.$${ext}"; \
	cp "$$src" "static/posts/$$name"; \
	echo "![](/posts/$$name)" >> "content/posts/$${post}.md"; \
	echo "Added $$name to $${post}.md"

serve:
	@hugo server --disableFastRender --ignoreCache
