[Audiobookshelf]
title="Audiobookshelf"
desc="Audiobookshelf HTTP and HTTPS"
port_forward="yes"
src.ports="13378,13379,443/tcp"
dst.ports="13378,13379,443/tcp"

# 端口说明：
# 13378 - HTTP 访问
# 13379 - WebSocket
# 443   - HTTPS（如果配置了 SSL/TLS）
