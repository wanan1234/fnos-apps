#!/bin/bash
set -e

# Scaffold a new fnOS app in the monorepo.
#
# Usage: ./scripts/new-app.sh <appname> <display_name> <port>
#
# Example: ./scripts/new-app.sh jellyfin "Jellyfin Media Server" 8096

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APPNAME="$1"
DISPLAY_NAME="$2"
PORT="$3"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[ -z "$APPNAME" ] && error "Usage: $0 <appname> <display_name> <port>"
[ -z "$DISPLAY_NAME" ] && error "Usage: $0 <appname> <display_name> <port>"
[ -z "$PORT" ] && error "Usage: $0 <appname> <display_name> <port>"

APP_DIR="$REPO_ROOT/apps/$APPNAME"
[ -d "$APP_DIR" ] && error "App directory already exists: $APP_DIR"

info "Creating app: $APPNAME ($DISPLAY_NAME) on port $PORT"

# Create directory structure
mkdir -p "$APP_DIR/fnos/"{bin,cmd,config,ui/images}

# manifest
cat > "$APP_DIR/fnos/manifest" << EOF
appname         = $APPNAME
version         = 0.0.0
display_name    = $DISPLAY_NAME
platform        = x86
maintainer      = TODO
maintainer_url  = TODO
distributor     = conversun
distributor_url = https://github.com/conversun/fnos-apps
desktop_uidir   = ui
desktop_applaunchname = ${APPNAME}.Application
service_port    = $PORT
desc            = TODO: Add description
source          = thirdparty
checksum        = 
EOF

# service-setup
cat > "$APP_DIR/fnos/cmd/service-setup" << 'EOF'
#!/bin/bash

LOG_FILE="${TRIM_PKGVAR}/${TRIM_APPNAME}.log"
PID_FILE="${TRIM_PKGVAR}/${TRIM_APPNAME}.pid"

APP_DIR="${TRIM_APPDEST}"
APP_DATA_DIR="${TRIM_PKGVAR}"

SERVICE_COMMAND="$APP_DIR/bin/TODO-server $APP_DATA_DIR"
SVC_BACKGROUND=y
SVC_WRITE_PID=y
EOF

# bin/server launcher
cat > "$APP_DIR/fnos/bin/${APPNAME}-server" << 'EOF'
#!/bin/sh
APP_DIR="${TRIM_APPDEST}"
APP_DATA_DIR=$1

# TODO: Set environment variables for the app

cd $APP_DIR || exit 1
# TODO: exec ./your-binary
EOF
chmod +x "$APP_DIR/fnos/bin/${APPNAME}-server"

# config/privilege
cat > "$APP_DIR/fnos/config/privilege" << EOF
{
    "defaults": {
        "run-as": "package"
    },
    "username": "$APPNAME",
    "groupname": "$APPNAME"
}
EOF

# config/resource
cat > "$APP_DIR/fnos/config/resource" << EOF
{
    "data-share": {
        "shares": [
            {
                "name": "$DISPLAY_NAME",
                "permission": {
                    "rw": [
                        "$APPNAME"
                    ]
                }
            }
        ]
    },
    "systemd-unit": {
    }
}
EOF

# ui/config
cat > "$APP_DIR/fnos/ui/config" << EOF
{
    ".url": {
        "${APPNAME}.Application":
        {
            "title": "$DISPLAY_NAME",
            "desc": "$DISPLAY_NAME",
            "icon": "images/{0}.png",
            "type": "url",
            "port": "$PORT",
            "protocol": "http",
            "url": "/",
            "allUsers": true
        }
    }
}
EOF

# Placeholder README
cat > "$APP_DIR/README.md" << EOF
# $DISPLAY_NAME for fnOS

TODO: Add description and build instructions.

## Local Build

\`\`\`bash
./update_${APPNAME}.sh
\`\`\`
EOF

info "App scaffolded at: apps/$APPNAME/"
info ""
info "Next steps:"
info "  1. Add app icons to apps/$APPNAME/fnos/ICON.PNG and ICON_256.PNG"
info "  2. Add UI icons to apps/$APPNAME/fnos/ui/images/ (16-256px)"
info "  3. Edit fnos/bin/${APPNAME}-server with correct launch command"
info "  4. Edit fnos/cmd/service-setup with correct SERVICE_COMMAND"
info "  5. Create update_${APPNAME}.sh build script"
info "  6. Create .github/workflows/build-${APPNAME}.yml"
info "  7. Fill in manifest TODO fields"
