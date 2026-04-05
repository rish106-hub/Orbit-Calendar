.PHONY: macos-run macos-build api-venv api-dev

macos-run:
	swift run --package-path apps/macos OrbitCalendarMac

macos-build:
	swift build --package-path apps/macos

api-venv:
	cd apps/api && python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

api-dev:
	cd apps/api && . .venv/bin/activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
